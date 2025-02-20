//  SDLProtocol.m
//


#import "SDLFunctionID.h"

#import "SDLTransportType.h"
#import "SDLControlFramePayloadConstants.h"
#import "SDLControlFramePayloadEndService.h"
#import "SDLControlFramePayloadNak.h"
#import "SDLControlFramePayloadRegisterSecondaryTransportNak.h"
#import "SDLControlFramePayloadAudioStartServiceAck.h"
#import "SDLControlFramePayloadRPCStartService.h"
#import "SDLControlFramePayloadRPCStartServiceAck.h"
#import "SDLControlFramePayloadVideoStartServiceAck.h"
#import "SDLEncryptionLifecycleManager.h"
#import "SDLError.h"
#import "SDLLogMacros.h"
#import "SDLGlobals.h"
#import "SDLPrioritizedObjectCollection.h"
#import "SDLProtocol.h"
#import "SDLProtocolHeader.h"
#import "SDLProtocolMessage.h"
#import "SDLProtocolMessageDisassembler.h"
#import "SDLProtocolReceivedMessageRouter.h"
#import "SDLRPCNotification.h"
#import "SDLRPCPayload.h"
#import "SDLRPCRequest.h"
#import "SDLRPCResponse.h"
#import "SDLSecurityType.h"
#import "SDLSecurityQueryErrorCode.h"
#import "SDLSecurityQueryPayload.h"
#import "SDLSystemInfo.h"
#import "SDLTimer.h"
#import "SDLVersion.h"
#import "SDLV2ProtocolHeader.h"

NSString *const SDLProtocolSecurityErrorDomain = @"com.sdl.protocol.security";
static const NSUInteger TLSMaxDataSize = 16834;
static const NSUInteger TLSMaxRPCPayloadDataToEncryptSize = 16384 /*TLS Max Record Size*/ - 5 /*TLS Record Header Size*/ - 32 /*TLS MES Auth CDE Size*/ - 256 /*TLS Max Record Padding Size*/;

#pragma mark - SDLProtocol Private Interface

typedef NSNumber SDLServiceTypeBox;

NS_ASSUME_NONNULL_BEGIN

@interface SDLProtocol () {
    UInt32 _messageID;
    SDLPrioritizedObjectCollection *_prioritizedCollection;
}

@property (strong, nonatomic) NSMutableData *receiveBuffer;
@property (nullable, strong, nonatomic) SDLProtocolReceivedMessageRouter *messageRouter;
@property (strong, nonatomic) NSMutableDictionary<SDLServiceTypeBox *, SDLProtocolHeader *> *serviceHeaders;
@property (assign, nonatomic) int32_t hashId;

// Readonly public properties
@property (strong, nonatomic, readwrite, nullable) NSString *authToken;
@property (strong, nonatomic, readwrite, nullable) SDLSystemInfo *systemInfo;

@end


#pragma mark - SDLProtocol Implementation

@implementation SDLProtocol

#pragma mark - Lifecycle

- (instancetype)initWithTransport:(id<SDLTransportType>)transport encryptionManager:(nullable SDLEncryptionLifecycleManager *)encryptionManager {
    self = [super init];
    if (!self) { return nil; }

    SDLLogV(@"Initializing protocol with transport: %@, encryption manager: %@", transport, encryptionManager);
    _messageID = 0;
    _hashId = SDLControlFrameInt32NotFound;
    _prioritizedCollection = [[SDLPrioritizedObjectCollection alloc] init];
    _protocolDelegateTable = [NSHashTable weakObjectsHashTable];
    _serviceHeaders = [[NSMutableDictionary alloc] init];
    _messageRouter = [[SDLProtocolReceivedMessageRouter alloc] init];
    _messageRouter.delegate = self;

    _transport = transport;
    _transport.delegate = self;

    _encryptionLifecycleManager = encryptionManager;

    return self;
}

- (void)start {
    SDLLogD(@"Starting protocol: %@", self);
    [self.transport connect];
}

- (void)stopWithCompletionHandler:(void (^)(void))disconnectCompletionHandler {
    SDLLogD(@"Stopping protocol: %@, disconnecting transport and stopping security manager", self);
    [self.securityManager stop];
    [self.transport disconnectWithCompletionHandler:^{
        disconnectCompletionHandler();
    }];
}

#pragma mark - Service metadata
- (BOOL)storeHeader:(SDLProtocolHeader *)header forServiceType:(SDLServiceType)serviceType {
    if (header == nil) {
        return NO;
    }

    SDLLogD(@"Storing SessionID %i of serviceType %i", header.sessionID, serviceType);
    self.serviceHeaders[@(serviceType)] = [header copy];
    return YES;
}

- (UInt8)sdl_retrieveSessionIDforServiceType:(SDLServiceType)serviceType {
    SDLProtocolHeader *header = self.serviceHeaders[@(serviceType)];
    if (header == nil) {
        // The first time the RPC service type is created, there's no header, so we don't need to warn.
        if (serviceType != SDLServiceTypeRPC) {
            SDLLogW(@"Warning: Tried to retrieve sessionID for serviceType %i, but no header is saved for that service type.", serviceType);
        }

        return 0;
    }

    return header.sessionID;
}

#pragma mark - SDLTransportDelegate

- (void)onTransportConnected {
    SDLLogV(@"Transport connected, opening protocol");
    NSArray<id<SDLProtocolDelegate>> *listeners;
    @synchronized(self.protocolDelegateTable) {
        listeners = self.protocolDelegateTable.allObjects;
    }
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocolDidOpen:)]) {
            [listener protocolDidOpen:self];
        }
    }
}

- (void)onTransportDisconnected {
    SDLLogV(@"Transport disconnected, closing protocol");
    NSArray<id<SDLProtocolDelegate>> *listeners;
    @synchronized(self.protocolDelegateTable) {
        listeners = self.protocolDelegateTable.allObjects;
    }
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocolDidClose:)]) {
            [listener protocolDidClose:self];
        }
    }
}

- (void)onDataReceived:(NSData *)receivedData {
    [self sdl_handleBytesFromTransport:receivedData];
}

- (void)onError:(NSError *)error {
    SDLLogV(@"Transport received an error: %@", error);
    for (id<SDLProtocolDelegate> listener in self.protocolDelegateTable.allObjects) {
        if ([listener respondsToSelector:@selector(protocol:transportDidError:)]) {
            [listener protocol:self transportDidError:error];
        }
    }
}

#pragma mark - Start Service

- (void)startServiceWithType:(SDLServiceType)serviceType payload:(nullable NSData *)payload {
    // No encryption, just build and send the message synchronously
    SDLProtocolMessage *message = [self sdl_createStartServiceMessageWithType:serviceType encrypted:NO payload:payload];
    SDLLogD(@"Sending start service: %@", message);
    [self sdl_sendDataToTransport:message.data onService:serviceType];
}

- (void)startSecureServiceWithType:(SDLServiceType)serviceType payload:(nullable NSData *)payload tlsInitializationHandler:(void (^)(BOOL success, NSError *error))tlsInitializationHandler {
    SDLLogD(@"Attempting to start TLS for service type: %hhu", serviceType);
    [self sdl_initializeTLSEncryptionWithCompletionHandler:^(BOOL success, NSError *error) {
        tlsInitializationHandler(success, error);
        if (!success) {
            // We can't start the service because we don't have encryption, return the error
            BLOCK_RETURN;
        }

        // TLS initialization succeeded. Build and send the message.
        SDLProtocolMessage *message = [self sdl_createStartServiceMessageWithType:serviceType encrypted:YES payload:payload];
        SDLLogD(@"TLS initialized, sending start service with encryption for message: %@", message);
        [self sdl_sendDataToTransport:message.data onService:serviceType];
    }];
}

- (SDLProtocolMessage *)sdl_createStartServiceMessageWithType:(SDLServiceType)serviceType encrypted:(BOOL)encryption payload:(nullable NSData *)payload {
    SDLProtocolHeader *header = [SDLProtocolHeader headerForVersion:(UInt8)[SDLGlobals sharedGlobals].protocolVersion.major];
    NSData *servicePayload = payload;

    header.sessionID = [self sdl_retrieveSessionIDforServiceType:SDLServiceTypeRPC];
    header.frameType = SDLFrameTypeControl;
    header.serviceType = serviceType;
    header.frameData = SDLFrameInfoStartService;

    // Sending a StartSession with the encrypted bit set causes module to initiate SSL Handshake with a ClientHello message, which should be handled by the 'processControlService' method.
    header.encrypted = encryption;

    return [SDLProtocolMessage messageWithHeader:header andPayload:servicePayload];
}

- (void)sdl_initializeTLSEncryptionWithCompletionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler {
    if (self.securityManager == nil) {
        SDLLogE(@"Could not start streaming service, encryption was requested by the remote system but failed because there is no security manager set for this app.");

        if (completionHandler != nil) {
            completionHandler(NO, [NSError errorWithDomain:SDLProtocolSecurityErrorDomain code:SDLProtocolErrorNoSecurityManager userInfo:nil]);
        }

        return;
    }

    SDLLogD(@"Telling security manager to initialize");
    [self.securityManager initializeWithAppId:self.appId completionHandler:^(NSError *_Nullable error) {
        if (error) {
            SDLLogE(@"Security Manager failed to initialize with error: %@", error);

            if (completionHandler != nil) {
                completionHandler(NO, error);
            }
        } else {
            if (completionHandler != nil) {
                completionHandler(YES, nil);
            }
        }
    }];
}


#pragma mark - End Service

- (void)endServiceWithType:(SDLServiceType)serviceType {
    SDLProtocolHeader *header = [SDLProtocolHeader headerForVersion:(UInt8)[SDLGlobals sharedGlobals].protocolVersion.major];
    header.frameType = SDLFrameTypeControl;
    header.serviceType = serviceType;
    header.frameData = SDLFrameInfoEndService;
    header.sessionID = [self sdl_retrieveSessionIDforServiceType:serviceType];

    // Assemble the payload, it's a full control frame if we're on 5.0+, it's just the hash id if we are not
    NSData *payload = nil;
    if (self.hashId != SDLControlFrameInt32NotFound) {
        if([SDLGlobals sharedGlobals].protocolVersion.major > 4) {
            SDLControlFramePayloadEndService *endServicePayload = [[SDLControlFramePayloadEndService alloc] initWithHashId:self.hashId];
            payload = endServicePayload.data;
        } else {
            payload = [NSData dataWithBytes:&_hashId length:sizeof(_hashId)];
        }
    }

    SDLProtocolMessage *message = [SDLProtocolMessage messageWithHeader:header andPayload:payload];
    SDLLogD(@"Sending end service: %@", message);
    [self sdl_sendDataToTransport:message.data onService:serviceType];
}


#pragma mark - Register Secondary Transport

- (void)registerSecondaryTransport {
    SDLLogV(@"Attempting to register the secondary transport");

    SDLProtocolHeader *header = [SDLProtocolHeader headerForVersion:(UInt8)[SDLGlobals sharedGlobals].protocolVersion.major];
    header.frameType = SDLFrameTypeControl;
    header.serviceType = SDLServiceTypeControl;
    header.frameData = SDLFrameInfoRegisterSecondaryTransport;
    header.sessionID = [self sdl_retrieveSessionIDforServiceType:SDLServiceTypeControl];
    if ([SDLGlobals sharedGlobals].protocolVersion.major >= 2) {
        [((SDLV2ProtocolHeader *)header) setMessageID:++_messageID];
    }

    SDLProtocolMessage *message = [SDLProtocolMessage messageWithHeader:header andPayload:nil];
    SDLLogD(@"Sending register secondary transport: %@", message);
    [self sdl_sendDataToTransport:message.data onService:SDLServiceTypeControl];
}


#pragma mark - Send Data

- (BOOL)sendRPC:(SDLRPCMessage *)message error:(NSError *__autoreleasing *)error {
    if (!message.isPayloadProtected && [self.encryptionLifecycleManager rpcRequiresEncryption:message]) {
        message.payloadProtected = YES;
    }

    return [self sendRPC:message encrypted:message.isPayloadProtected error:error];
}

- (BOOL)sendRPC:(SDLRPCMessage *)message encrypted:(BOOL)encryption error:(NSError *__autoreleasing *)error {
    NSParameterAssert(message != nil);

    // Check that we can send the message over encryption and fail early if we cannot
    if (message.isPayloadProtected && !self.encryptionLifecycleManager.isEncryptionReady) {
        SDLLogE(@"Encryption Manager not ready, message not sent (%@)", message);
        if (error != nil) {
            *error = [NSError sdl_encryption_lifecycle_notReadyError];
        }
        return NO;
    }

    // Convert the message dictionary to JSON and return early if it fails
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[message serializeAsDictionary:(Byte)[SDLGlobals sharedGlobals].protocolVersion.major] options:kNilOptions error:&jsonError];
    if (jsonError != nil) {
        if (error != nil) {
            *error = jsonError;
        }
        SDLLogE(@"Error encoding JSON data: %@", jsonError);
        return NO;
    }

    NSData *messagePayload = nil;
    SDLLogV(@"Sending RPC: %@", message);

    // Build the message payload. Include the binary header if necessary
    // VERSION DEPENDENT CODE
    switch ([SDLGlobals sharedGlobals].protocolVersion.major) {
        case 1: {
            // No binary header in version 1
            messagePayload = jsonData;
        } break;
        case 2: // Fallthrough
        case 3: // Fallthrough
        case 4: // Fallthrough
        case 5: {
            // Build a binary header
            // Serialize the RPC data into an NSData
            SDLRPCPayload *rpcPayload = [[SDLRPCPayload alloc] init];
            rpcPayload.functionID = [[[SDLFunctionID sharedInstance] functionIdForName:message.name] unsignedIntValue];
            rpcPayload.jsonData = jsonData;
            rpcPayload.binaryData = message.bulkData;

            // If it's a request or a response, we need to pull out the correlation ID, so we'll downcast
            if ([message isKindOfClass:SDLRPCRequest.class]) {
                rpcPayload.rpcType = SDLRPCMessageTypeRequest;
                rpcPayload.correlationID = [((SDLRPCRequest *)message).correlationID unsignedIntValue];
            } else if ([message isKindOfClass:SDLRPCResponse.class]) {
                rpcPayload.rpcType = SDLRPCMessageTypeResponse;
                rpcPayload.correlationID = [((SDLRPCResponse *)message).correlationID unsignedIntValue];
            } else if ([message isKindOfClass:[SDLRPCNotification class]]) {
                rpcPayload.rpcType = SDLRPCMessageTypeNotification;
            } else {
                NSAssert(NO, @"Unknown message type attempted to send. Type: %@", [message class]);
                *error = [NSError sdl_lifecycle_rpcErrorWithDescription:@"Unknown message type" andReason:@"An unknown RPC message type was attempted."];
                return NO;
            }

            messagePayload = rpcPayload.data;
        } break;
        default: {
            NSAssert(NO, @"Attempting to send an RPC based on an unknown version number: %@, message: %@", @([SDLGlobals sharedGlobals].protocolVersion.major), message);
        } break;
    }

    // Build the protocol level header & message
    SDLProtocolHeader *header = [SDLProtocolHeader headerForVersion:(UInt8)[SDLGlobals sharedGlobals].protocolVersion.major];
    header.encrypted = encryption;
    header.frameType = SDLFrameTypeSingle;
    header.serviceType = (message.bulkData.length <= 0) ? SDLServiceTypeRPC : SDLServiceTypeBulkData;
    header.frameData = SDLFrameInfoSingleFrame;
    header.sessionID = [self sdl_retrieveSessionIDforServiceType:SDLServiceTypeRPC];

    // V2+ messages need to have message ID property set.
    if ([SDLGlobals sharedGlobals].protocolVersion.major >= 2) {
        [((SDLV2ProtocolHeader *)header) setMessageID:++_messageID];
    }

    SDLProtocolMessage *protocolMessage = [SDLProtocolMessage messageWithHeader:header andPayload:messagePayload];

    // See if the message is small enough to send in one transmission. If not, break it up into smaller messages and send.
    NSUInteger rpcMTUSize = [[SDLGlobals sharedGlobals] mtuSizeForServiceType:SDLServiceTypeRPC];
    NSUInteger mtuSize = (encryption ? MIN(TLSMaxRPCPayloadDataToEncryptSize, rpcMTUSize) : rpcMTUSize);
    NSArray<SDLProtocolMessage *> *protocolMessages = nil;
    if (protocolMessage.size < mtuSize) {
        protocolMessages = @[protocolMessage];
    } else {
        protocolMessages = [SDLProtocolMessageDisassembler disassemble:protocolMessage withMTULimit:mtuSize];
    }

    // If the message should be encrypted, encrypt the payloads
    if (encryption) {
        BOOL success = [self sdl_encryptProtocolMessages:protocolMessages error:error];
        if (!success) {
            SDLLogE(@"Error encrypting protocol messages. Messages will not be sent. Error: %@", *error);
            return NO;
        }
    }

    // Send each message
    for (SDLProtocolMessage *message in protocolMessages) {
        SDLLogV(@"Sending protocol message: %@", message);
        [self sdl_sendDataToTransport:message.data onService:SDLServiceTypeRPC];
    }

    return YES;
}

/// Receives an array of `SDLProtocolMessage` and attempts to encrypt their payloads in place through the active security manager. If anything fails, it will return NO and pass back the error.
/// @param protocolMessages The array of protocol messages to encrypt.
/// @param error A passback error object if attempting to encrypt the protocol message payloads fails.
/// @returns YES if the encryption was successful, NO if it was not
- (BOOL)sdl_encryptProtocolMessages:(NSArray<SDLProtocolMessage *> *)protocolMessages error:(NSError *__autoreleasing *)error {
    for (SDLProtocolMessage *message in protocolMessages) {
        if (message.header.frameType == SDLFrameTypeFirst) { continue; }

        // If we're trying to encrypt, try to have the security manager encrypt it. Return if it fails.
        NSError *encryptError = nil;
        NSData *encryptedMessagePayload = [self.securityManager encryptData:message.payload withError:&encryptError];

        // If the encryption failed, pass back the error and return false
        if (encryptedMessagePayload.length == 0 || encryptError != nil) {
            if (error != nil) {
                if (encryptError != nil) {
                    *error = encryptError;
                } else {
                    *error = [NSError sdl_encryption_unknown];
                }
            }

            return NO;
        } else {
            message.payload = encryptedMessagePayload;
            message.header.bytesInPayload = (UInt32)encryptedMessagePayload.length;
        }
    }

    return YES;
}

// Use for normal messages
- (void)sdl_sendDataToTransport:(NSData *)data onService:(NSInteger)priority {
    [_prioritizedCollection addObject:data withPriority:priority];

    NSData *dataToTransmit = nil;
    while (dataToTransmit = (NSData *)[self->_prioritizedCollection nextObject]) {
        [self.transport sendData:dataToTransmit];
    }
}

- (void)sendRawData:(NSData *)data withServiceType:(SDLServiceType)serviceType {
    [self sdl_sendRawData:data onService:serviceType encryption:NO];
}

- (void)sendEncryptedRawData:(NSData *)data onService:(SDLServiceType)serviceType {
    // Break up data larger than the max TLS size so the data can be encrypted by the security manager without failing due to the data size being too big
    NSUInteger offset = 0;
    do {
        NSUInteger remainingDataLength = data.length - offset;
        NSUInteger chunkSize = (remainingDataLength > TLSMaxDataSize) ? TLSMaxDataSize : remainingDataLength;
        NSData *chunk = [NSData dataWithBytesNoCopy:(BytePtr)data.bytes + offset length:chunkSize freeWhenDone:NO];

        [self sdl_sendRawData:chunk onService:serviceType encryption:YES];
        offset += chunkSize;
    } while (offset < data.length);
}

- (void)sdl_sendRawData:(NSData *)data onService:(SDLServiceType)service encryption:(BOOL)encryption {
    SDLV2ProtocolHeader *header = [[SDLV2ProtocolHeader alloc] initWithVersion:(UInt8)[SDLGlobals sharedGlobals].protocolVersion.major];
    header.encrypted = encryption;
    header.frameType = SDLFrameTypeSingle;
    header.serviceType = service;
    header.sessionID = [self sdl_retrieveSessionIDforServiceType:service];
    header.messageID = ++_messageID;

    if (encryption && data.length) {
        NSError *encryptError = nil;
        data = [self.securityManager encryptData:data withError:&encryptError];

        // If the data fails to encrypt, fail out of sending this chunk of data.
        if ((data.length == 0) || (encryptError != nil)) {
            SDLLogE(@"Error attempting to encrypt raw data for service: %@, error: %@", @(service), encryptError);
            return;
        }
    }

    SDLProtocolMessage *message = [SDLProtocolMessage messageWithHeader:header andPayload:data];
    if (message.size < [[SDLGlobals sharedGlobals] mtuSizeForServiceType:service]) {
        SDLLogV(@"Sending protocol message: %@", message);
        [self sdl_sendDataToTransport:message.data onService:header.serviceType];
    } else {
        NSArray<SDLProtocolMessage *> *messages = [SDLProtocolMessageDisassembler disassemble:message withMTULimit:[[SDLGlobals sharedGlobals] mtuSizeForServiceType:service]];
        for (SDLProtocolMessage *smallerMessage in messages) {
            SDLLogV(@"Sending protocol message: %@", smallerMessage);
            [self sdl_sendDataToTransport:smallerMessage.data onService:header.serviceType];
        }
    }
}


#pragma mark - Receive and Process Data

// Turn received bytes into message objects.
- (void)sdl_handleBytesFromTransport:(NSData *)receivedData {
    // Initialize the receive buffer which will contain bytes while messages are constructed.
    if (self.receiveBuffer == nil) {
        self.receiveBuffer = [NSMutableData dataWithCapacity:(4 * [[SDLGlobals sharedGlobals] mtuSizeForServiceType:SDLServiceTypeRPC])];
    }

    // Save the data
    [self.receiveBuffer appendData:receivedData];

    [self sdl_processMessages];
}

- (void)sdl_processMessages {
    UInt8 incomingVersion = [SDLProtocolHeader determineVersion:self.receiveBuffer];

    // If we have enough bytes, create the header.
    SDLProtocolHeader *header = [SDLProtocolHeader headerForVersion:incomingVersion];
    NSUInteger headerSize = header.size;
    if (self.receiveBuffer.length >= headerSize) {
        [header parse:self.receiveBuffer];
    } else {
        return;
    }

    // If we have enough bytes, finish building the message.
    SDLProtocolMessage *message = nil;
    NSUInteger payloadSize = header.bytesInPayload;
    NSUInteger messageSize = headerSize + payloadSize;
    if (self.receiveBuffer.length >= messageSize) {
        NSUInteger payloadOffset = headerSize;
        NSUInteger payloadLength = payloadSize;
        NSData *payload = [self.receiveBuffer subdataWithRange:NSMakeRange(payloadOffset, payloadLength)];

        // If the message in encrypted and there is payload, try to decrypt it
        if (header.encrypted && payload.length) {
            NSError *decryptError = nil;
            payload = [self.securityManager decryptData:payload withError:&decryptError];

            if (decryptError != nil) {
                SDLLogE(@"Error attempting to decrypt a payload with error: %@", decryptError);
                return;
            }
        }

        message = [SDLProtocolMessage messageWithHeader:header andPayload:payload];
    } else {
        // Need to wait for more bytes.
        SDLLogV(@"Protocol header complete, message incomplete, waiting for %ld more bytes. Header: %@", (long)(messageSize - self.receiveBuffer.length), header);
        return;
    }

    // Need to maintain the receiveBuffer, remove the bytes from it which we just processed.
    self.receiveBuffer = [[self.receiveBuffer subdataWithRange:NSMakeRange(messageSize, self.receiveBuffer.length - messageSize)] mutableCopy];

    // Pass on the message to the message router.
    [self.messageRouter handleReceivedMessage:message protocol:self];

    // Call recursively until the buffer is empty or incomplete message is encountered
    if (self.receiveBuffer.length > 0) {
        [self sdl_processMessages];
    }
}


#pragma mark - SDLProtocolDelegate from SDLReceivedProtocolMessageRouter

- (void)protocol:(SDLProtocol *)protocol didReceiveStartServiceACK:(SDLProtocolMessage *)startServiceACK {
    SDLLogD(@"Received start service ACK: %@", startServiceACK);

    // V5+ Packet
    if (startServiceACK.header.version >= 5) {
        switch (startServiceACK.header.serviceType) {
            case SDLServiceTypeRPC: {
                SDLControlFramePayloadRPCStartServiceAck *startServiceACKPayload = [[SDLControlFramePayloadRPCStartServiceAck alloc] initWithData:startServiceACK.payload];
                if (startServiceACKPayload.mtu != SDLControlFrameInt64NotFound) {
                    [[SDLGlobals sharedGlobals] setDynamicMTUSize:(NSUInteger)startServiceACKPayload.mtu forServiceType:startServiceACK.header.serviceType];
                }
                if (startServiceACKPayload.hashId != SDLControlFrameInt32NotFound) {
                    self.hashId = startServiceACKPayload.hashId;
                }

                [SDLGlobals sharedGlobals].maxHeadUnitProtocolVersion = (startServiceACKPayload.protocolVersion != nil) ? [SDLVersion versionWithString:startServiceACKPayload.protocolVersion] : [SDLVersion versionWithMajor:startServiceACK.header.version minor:0 patch:0];

                self.authToken = startServiceACKPayload.authToken;

                if ((startServiceACKPayload.make != nil) || (startServiceACKPayload.systemHardwareVersion != nil) || (startServiceACKPayload.systemSoftwareVersion != nil)) {
                    self.systemInfo = [[SDLSystemInfo alloc] initWithMake:startServiceACKPayload.make model:startServiceACKPayload.model trim:startServiceACKPayload.trim modelYear:startServiceACKPayload.modelYear softwareVersion:startServiceACKPayload.systemSoftwareVersion hardwareVersion:startServiceACKPayload.systemHardwareVersion];
                }
            } break;
            case SDLServiceTypeAudio: {
                SDLControlFramePayloadAudioStartServiceAck *startServiceACKPayload = [[SDLControlFramePayloadAudioStartServiceAck alloc] initWithData:startServiceACK.payload];
                if (startServiceACKPayload.mtu != SDLControlFrameInt64NotFound) {
                    [[SDLGlobals sharedGlobals] setDynamicMTUSize:(NSUInteger)startServiceACKPayload.mtu forServiceType:SDLServiceTypeAudio];
                }
            } break;
            case SDLServiceTypeVideo: {
                SDLControlFramePayloadVideoStartServiceAck *startServiceACKPayload = [[SDLControlFramePayloadVideoStartServiceAck alloc] initWithData:startServiceACK.payload];
                if (startServiceACKPayload.mtu != SDLControlFrameInt64NotFound) {
                    [[SDLGlobals sharedGlobals] setDynamicMTUSize:(NSUInteger)startServiceACKPayload.mtu forServiceType:SDLServiceTypeVideo];
                }
            } break;
            default:
                break;
        }
    } else { // V4 and below packet
        switch (startServiceACK.header.serviceType) {
            case SDLServiceTypeRPC: {
                [SDLGlobals sharedGlobals].maxHeadUnitProtocolVersion = [SDLVersion versionWithMajor:startServiceACK.header.version minor:0 patch:0];
            } break;
            default:
                break;
        }
    }

    // Store the header of this service away for future use
    self.serviceHeaders[@(startServiceACK.header.serviceType)] = [startServiceACK.header copy];

    // Pass along to all the listeners
    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveStartServiceACK:)]) {
            [listener protocol:protocol didReceiveStartServiceACK:startServiceACK];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveStartServiceNAK:(SDLProtocolMessage *)startServiceNAK {
    [self sdl_logControlNAKPayload:startServiceNAK];

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveStartServiceNAK:)]) {
            [listener protocol:protocol didReceiveStartServiceNAK:startServiceNAK];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveEndServiceACK:(SDLProtocolMessage *)endServiceACK {
    SDLLogD(@"End service ACK: %@", endServiceACK);
    // Remove the session id
    [self.serviceHeaders removeObjectForKey:@(endServiceACK.header.serviceType)];

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveEndServiceACK:)]) {
            [listener protocol:protocol didReceiveEndServiceACK:endServiceACK];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveEndServiceNAK:(SDLProtocolMessage *)endServiceNAK {
    [self sdl_logControlNAKPayload:endServiceNAK];

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveEndServiceNAK:)]) {
            [listener protocol:protocol didReceiveEndServiceNAK:endServiceNAK];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveRegisterSecondaryTransportACK:(SDLProtocolMessage *)registerSecondaryTransportACK {
    SDLLogD(@"Register Secondary Transport ACK: %@", registerSecondaryTransportACK);

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveRegisterSecondaryTransportACK:)]) {
            [listener protocol:protocol didReceiveRegisterSecondaryTransportACK:registerSecondaryTransportACK];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveRegisterSecondaryTransportNAK:(SDLProtocolMessage *)registerSecondaryTransportNAK {
    [self sdl_logControlNAKPayload:registerSecondaryTransportNAK];

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveRegisterSecondaryTransportNAK:)]) {
            [listener protocol:protocol didReceiveRegisterSecondaryTransportNAK:registerSecondaryTransportNAK];
        }
    }
}

- (void)handleHeartbeatForSession:(Byte)session {
    SDLLogV(@"Received a heartbeat");

    // Respond with a heartbeat ACK
    SDLProtocolHeader *header = [SDLProtocolHeader headerForVersion:(UInt8)[SDLGlobals sharedGlobals].protocolVersion.major];
    header.frameType = SDLFrameTypeControl;
    header.serviceType = SDLServiceTypeControl;
    header.frameData = SDLFrameInfoHeartbeatACK;
    header.sessionID = session;
    SDLProtocolMessage *message = [SDLProtocolMessage messageWithHeader:header andPayload:nil];
    [self sdl_sendDataToTransport:message.data onService:header.serviceType];

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(handleHeartbeatForSession:)]) {
            [listener handleHeartbeatForSession:session];
        }
    }
}

- (void)handleHeartbeatACK {
    SDLLogV(@"Received a heartbeat ACK");

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(handleHeartbeatACK)]) {
            [listener handleHeartbeatACK];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveTransportEventUpdate:(SDLProtocolMessage *)transportEventUpdate {
    SDLLogD(@"Received a transport event update: %@", transportEventUpdate);

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveTransportEventUpdate:)]) {
            [listener protocol:protocol didReceiveTransportEventUpdate:transportEventUpdate];
        }
    }
}

- (void)protocol:(SDLProtocol *)protocol didReceiveMessage:(SDLProtocolMessage *)msg {
    // Control service (but not control frame type) messages are TLS handshake messages
    if (msg.header.serviceType == SDLServiceTypeControl) {
        [self sdl_processSecurityMessage:msg];
        return;
    }

    SDLLogV(@"Other protocol message received: %@", msg);

    NSArray<id<SDLProtocolDelegate>> *listeners = [self sdl_getProtocolListeners];
    for (id<SDLProtocolDelegate> listener in listeners) {
        if ([listener respondsToSelector:@selector(protocol:didReceiveMessage:)]) {
            [listener protocol:protocol didReceiveMessage:msg];
        }
    }
}

- (void)sdl_logControlNAKPayload:(SDLProtocolMessage *)nakMessage {
    switch (nakMessage.header.frameData) {
        case SDLFrameInfoStartServiceNACK: // fallthrough
        case SDLFrameInfoEndServiceNACK: {
            if (nakMessage.header.version >= 5) {
                SDLControlFramePayloadNak *endServiceNakPayload = [[SDLControlFramePayloadNak alloc] initWithData:nakMessage.payload];
                SDLLogE(@"%@ service NAK'd, service type: %@, payload: %@", (nakMessage.header.frameData == SDLFrameInfoStartServiceNACK) ? @"Start" : @"End", @(nakMessage.header.serviceType), endServiceNakPayload);
            } else {
                SDLLogE(@"NAK received message: %@", nakMessage);
            }
        } break;
        case SDLFrameInfoRegisterSecondaryTransportNACK: {
            SDLControlFramePayloadRegisterSecondaryTransportNak *payload = [[SDLControlFramePayloadRegisterSecondaryTransportNak alloc] initWithData:nakMessage.payload];
            SDLLogE(@"Register Secondary Transport NAK'd, reason: %@", payload.reason);
        } break;
        default: break;
    }
}

- (NSArray<id<SDLProtocolDelegate>> *)sdl_getProtocolListeners {
    @synchronized(self.protocolDelegateTable) {
        return self.protocolDelegateTable.allObjects;
    }
}


#pragma mark - TLS Handshake

// TODO: These should be split out to a separate class to be tested properly
- (void)sdl_processSecurityMessage:(SDLProtocolMessage *)clientHandshakeMessage {
    SDLLogD(@"Received a security message: %@", clientHandshakeMessage);

    if (self.securityManager == nil) {
        SDLLogE(@"Failed to process security message because no security manager is set.");
        return;
    }

    // Misformatted handshake message, something went wrong
    if (clientHandshakeMessage.payload.length <= 12) {
        SDLLogE(@"Security message is malformed, less than 12 bytes. It does not have a security payload header.");
    }

    // Check the client's message header for any internal errors
    // NOTE: Before Core v8.0.0, all these messages will be notifications. In Core v8.0.0 and later, received messages will have the proper query type. Therefore, we cannot do things based only on the query type being request or response.
    SDLSecurityQueryPayload *clientSecurityQueryPayload = [SDLSecurityQueryPayload securityPayloadWithData:clientHandshakeMessage.payload];
    if (clientSecurityQueryPayload == nil) {
        SDLLogE(@"Module Security Query could not convert to object.");
        return;
    }

    // If the query is of type `Notification` and the id represents a client internal error, we abort the response message and the encryptionManager will not be in state ready.
    if (clientSecurityQueryPayload.queryID == SDLSecurityQueryIdSendInternalError && clientSecurityQueryPayload.queryType == SDLSecurityQueryTypeNotification) {
        NSError *jsonDecodeError = nil;
        NSDictionary<NSString *, id> *securityQueryErrorDictionary = [NSJSONSerialization JSONObjectWithData:clientSecurityQueryPayload.jsonData options:kNilOptions error:&jsonDecodeError];
        if (jsonDecodeError != nil) {
            SDLLogE(@"Error decoding module security query response JSON: %@", jsonDecodeError);
        } else {
            if (securityQueryErrorDictionary[@"text"] != nil) {
                SDLSecurityQueryErrorCode errorCodeString = [SDLSecurityQueryError convertErrorIdToStringEnum:securityQueryErrorDictionary[@"id"]];
                SDLLogE(@"Security Query module internal error: %@, code: %@", securityQueryErrorDictionary[@"text"], errorCodeString);
            } else {
                SDLLogE(@"Security Query module error: No information provided");
            }
        }
        return;
    }

    if (clientSecurityQueryPayload.queryID != SDLSecurityQueryIdSendHandshake) {
        SDLLogE(@"Security Query module error: Message is not a SEND_HANDSHAKE_DATA REQUEST");
        return;
    }

    if (clientSecurityQueryPayload.queryType == SDLSecurityQueryTypeResponse) {
        SDLLogE(@"Security Query module error: Message is a response, which is not supported");
        return;
    }

    // Tear off the binary header of the client protocol message to get at the actual TLS handshake
    // TODO: (Joel F.)[2016-02-15] Should check for errors
    NSData *clientHandshakeData = [clientHandshakeMessage.payload subdataWithRange:NSMakeRange(12, (clientHandshakeMessage.payload.length - 12))];

    // Ask the security manager for server data based on the client data sent
    NSError *handshakeError = nil;
    NSData *serverHandshakeData = [self.securityManager runHandshakeWithClientData:clientHandshakeData error:&handshakeError];

    // If the handshake went bad and the security library ain't happy, send over the failure to the module. This should result in an ACK with encryption off.
    SDLProtocolMessage *serverSecurityMessage = nil;
    if (serverHandshakeData.length == 0) {
        SDLLogE(@"Error running TLS handshake procedure. Sending error to module. Error: %@", handshakeError);

        serverSecurityMessage = [self.class sdl_serverSecurityFailedMessageWithClientMessageHeader:clientHandshakeMessage.header messageId:++_messageID];
    } else {
        // The handshake went fine, send the module the remaining handshake data
        serverSecurityMessage = [self.class sdl_serverSecurityHandshakeMessageWithData:serverHandshakeData clientMessageHeader:clientHandshakeMessage.header messageId:++_messageID];
    }

    // Send the response or error message. If it's an error message, the module will ACK the Start Service without encryption. If it's a TLS handshake message, the module will ACK with encryption
    SDLLogD(@"Sending security message: %@", serverSecurityMessage);
    [self sdl_sendDataToTransport:serverSecurityMessage.data onService:SDLServiceTypeControl];
}

+ (SDLProtocolMessage *)sdl_serverSecurityHandshakeMessageWithData:(NSData *)data clientMessageHeader:(SDLProtocolHeader *)clientHeader messageId:(UInt32)messageId {
    // This can't possibly be a v1 header because v1 does not have control protocol messages
    SDLV2ProtocolHeader *serverMessageHeader = [SDLProtocolHeader headerForVersion:clientHeader.version];
    serverMessageHeader.encrypted = NO;
    serverMessageHeader.frameType = SDLFrameTypeSingle;
    serverMessageHeader.serviceType = SDLServiceTypeControl;
    serverMessageHeader.frameData = SDLFrameInfoSingleFrame;
    serverMessageHeader.sessionID = clientHeader.sessionID;
    serverMessageHeader.messageID = messageId;

    // Assemble a security query payload header for our response
    SDLSecurityQueryPayload *serverTLSPayload = [[SDLSecurityQueryPayload alloc] initWithQueryType:SDLSecurityQueryTypeResponse queryID:SDLSecurityQueryIdSendHandshake sequenceNumber:0x00 jsonData:nil binaryData:data];

    NSData *binaryData = [serverTLSPayload convertToData];

    return [SDLProtocolMessage messageWithHeader:serverMessageHeader andPayload:binaryData];
}

+ (SDLProtocolMessage *)sdl_serverSecurityFailedMessageWithClientMessageHeader:(SDLProtocolHeader *)clientHeader messageId:(UInt32)messageId {
    // This can't possibly be a v1 header because v1 does not have control protocol messages
    SDLV2ProtocolHeader *serverMessageHeader = [SDLProtocolHeader headerForVersion:clientHeader.version];
    serverMessageHeader.encrypted = NO;
    serverMessageHeader.frameType = SDLFrameTypeSingle;
    serverMessageHeader.serviceType = SDLServiceTypeControl;
    serverMessageHeader.frameData = SDLFrameInfoSingleFrame;
    serverMessageHeader.sessionID = clientHeader.sessionID;
    serverMessageHeader.messageID = messageId;

    // For a control service packet, we need a binary header with a function ID corresponding to what type of packet we're sending.
    UInt8 errorCode = 0xFF;
    NSDictionary *jsonDictionary = @{@"id" : @(errorCode), @"text" : [SDLSecurityQueryError convertErrorIdToStringEnum:@(errorCode)]};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:kNilOptions error:nil];

    NSData *binaryDataPayload = [NSData dataWithBytes:&errorCode length:sizeof(errorCode)];
    SDLSecurityQueryPayload *serverTLSPayload = [[SDLSecurityQueryPayload alloc] initWithQueryType:SDLSecurityQueryTypeNotification queryID:SDLSecurityQueryIdSendInternalError sequenceNumber:0x00 jsonData:jsonData binaryData:binaryDataPayload];

    NSData *binaryData = [serverTLSPayload convertToData];

    // TODO: (Joel F.)[2016-02-15] This is supposed to have some JSON data and json data size
    return [SDLProtocolMessage messageWithHeader:serverMessageHeader andPayload:binaryData];
}

@end

NS_ASSUME_NONNULL_END
