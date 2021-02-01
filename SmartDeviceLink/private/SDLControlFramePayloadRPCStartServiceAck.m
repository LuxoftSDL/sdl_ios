//
//  SDLControlFramePayloadStartServiceAck.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/20/17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import "SDLControlFramePayloadRPCStartServiceAck.h"

#import "bson_object.h"
#import "SDLControlFramePayloadConstants.h"
#import "SDLVehicleType.h"
#import "SDLSystemInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLControlFramePayloadRPCStartServiceAck ()

@property (assign, nonatomic, readwrite) int32_t hashId;
@property (assign, nonatomic, readwrite) int64_t mtu;
@property (copy, nonatomic, readwrite, nullable) NSString *authToken;
@property (copy, nonatomic, readwrite, nullable) NSString *protocolVersion;
@property (copy, nonatomic, readwrite, nullable) NSArray<NSString *> *secondaryTransports;
@property (copy, nonatomic, readwrite, nullable) NSArray<NSNumber *> *audioServiceTransports;
@property (copy, nonatomic, readwrite, nullable) NSArray<NSNumber *> *videoServiceTransports;
@property (strong, nonatomic, readwrite, nullable) SDLSystemInfo *systemInfo;

SDLSystemInfo *__nullable sdl_parseSystemInfo(BsonObject *const payloadObject);
BOOL sdl_putStringValue(BsonObject *const payloadObject, const char *key, NSString *value);

@end

@implementation SDLControlFramePayloadRPCStartServiceAck

- (instancetype)initWithHashId:(int32_t)hashId
                           mtu:(int64_t)mtu
                     authToken:(nullable NSString *)authToken
               protocolVersion:(nullable NSString *)protocolVersion
           secondaryTransports:(nullable NSArray<NSString *> *)secondaryTransports
        audioServiceTransports:(nullable NSArray<NSNumber *> *)audioServiceTransports
        videoServiceTransports:(nullable NSArray<NSNumber *> *)videoServiceTransports {
    self = [super init];
    if (!self) return nil;

    _hashId = hashId;
    _mtu = mtu;
    _authToken = authToken;
    _protocolVersion = protocolVersion;
    _secondaryTransports = secondaryTransports;
    _audioServiceTransports = audioServiceTransports;
    _videoServiceTransports = videoServiceTransports;

    return self;
}

- (instancetype)initWithData:(nullable NSData *)data {
    self = [super init];
    if (!self) return nil;

    _hashId = SDLControlFrameInt32NotFound;
    _mtu = SDLControlFrameInt64NotFound;

    if (data.length > 0) {
        [self sdl_parse:data];
    }

    return self;
}

- (nullable NSData *)data {
    if (self.hashId == SDLControlFrameInt32NotFound
        && self.mtu == SDLControlFrameInt64NotFound
        && self.protocolVersion == nil) {
        return nil;
    }

    BsonObject payloadObject;
    bson_object_initialize_default(&payloadObject);

    if (self.hashId != SDLControlFrameInt32NotFound) {
        bson_object_put_int32(&payloadObject, SDLControlFrameHashIdKey, self.hashId);
    }

    if (self.mtu != SDLControlFrameInt64NotFound) {
        bson_object_put_int64(&payloadObject, SDLControlFrameMTUKey, self.mtu);
    }

    if (self.authToken != nil) {
        bson_object_put_string(&payloadObject, SDLControlFrameAuthTokenKey, (char *)self.authToken.UTF8String);
    }

    if (self.protocolVersion != nil) {
        bson_object_put_string(&payloadObject, SDLControlFrameProtocolVersionKey, (char *)self.protocolVersion.UTF8String);
    }

    if (self.secondaryTransports != nil) {
        BsonArray arrayObject;
        // Currently there are 8 transport types defined. So initial value of 8 should be sufficient.
        bson_array_initialize(&arrayObject, 8);

        for (NSString *transport in self.secondaryTransports) {
            bson_array_add_string(&arrayObject, (char *)transport.UTF8String);
        }

        bson_object_put_array(&payloadObject, SDLControlFrameSecondaryTransportsKey, &arrayObject);
    }

    [self sdl_addServiceTransports:&payloadObject fromArray:self.audioServiceTransports forKey:SDLControlFrameAudioServiceTransportsKey];
    [self sdl_addServiceTransports:&payloadObject fromArray:self.videoServiceTransports forKey:SDLControlFrameVideoServiceTransportsKey];

    if (self.systemInfo) {
        sdl_putStringValue(&payloadObject, SDLControlFrameVehicleMake, self.systemInfo.vehicleType.make);
        sdl_putStringValue(&payloadObject, SDLControlFrameVehicleModel, self.systemInfo.vehicleType.model);
        sdl_putStringValue(&payloadObject, SDLControlFrameVehicleModelYear, self.systemInfo.vehicleType.modelYear);
        sdl_putStringValue(&payloadObject, SDLControlFrameVehicleTrim, self.systemInfo.vehicleType.trim);
        sdl_putStringValue(&payloadObject, SDLControlFrameVehicleHardVersion, self.systemInfo.systemHardwareVersion);
        sdl_putStringValue(&payloadObject, SDLControlFrameVehicleSoftVersion, self.systemInfo.systemSoftwareVersion);
    }

    const BytePtr bsonData = bson_object_to_bytes(&payloadObject);
    const NSUInteger length = bson_object_size(&payloadObject);

    bson_object_deinitialize(&payloadObject);

    NSData *data = (bsonData && length) ? [[NSData alloc] initWithBytes:bsonData length:length] : nil;
    if (bsonData) {
        free(bsonData);
    }
    return data;
}

- (void)sdl_parse:(NSData *)data {
    BsonObject payloadObject;
    size_t retval = bson_object_from_bytes_len(&payloadObject, (BytePtr)data.bytes, data.length);
    if (retval <= 0) {
        return;
    }

    self.hashId = bson_object_get_int32(&payloadObject, SDLControlFrameHashIdKey);
    self.mtu = bson_object_get_int64(&payloadObject, SDLControlFrameMTUKey);

    char *protocolVersionUTF8String = bson_object_get_string(&payloadObject, SDLControlFrameProtocolVersionKey);
    if (protocolVersionUTF8String != NULL) {
        self.protocolVersion = [NSString stringWithUTF8String:protocolVersionUTF8String];
    }

    char *authTokenUTF8String = bson_object_get_string(&payloadObject, SDLControlFrameAuthTokenKey);
    if (authTokenUTF8String != NULL) {
        self.authToken = [NSString stringWithUTF8String:authTokenUTF8String];
    }

    BsonArray *arrayObject = bson_object_get_array(&payloadObject, SDLControlFrameSecondaryTransportsKey);
    if (arrayObject != NULL) {
        NSMutableArray<NSString *> *secondaryTransports = [NSMutableArray array];
        size_t index = 0;

        while ((protocolVersionUTF8String = bson_array_get_string(arrayObject, index)) != NULL) {
            [secondaryTransports addObject:[NSString stringWithUTF8String:protocolVersionUTF8String]];
            index++;
        }
        self.secondaryTransports = [secondaryTransports copy];
    }

    self.systemInfo = sdl_parseSystemInfo(&payloadObject);

    self.audioServiceTransports = [self sdl_getServiceTransports:&payloadObject forKey:SDLControlFrameAudioServiceTransportsKey];
    self.videoServiceTransports = [self sdl_getServiceTransports:&payloadObject forKey:SDLControlFrameVideoServiceTransportsKey];

    bson_object_deinitialize(&payloadObject);
}

NSString *sdl_getStringValue(BsonObject *const payloadObject, const char *key) {
    const char *cValue = key && payloadObject ? bson_object_get_string(payloadObject, key) : NULL;
    return cValue ? [NSString stringWithUTF8String:cValue] : nil;
}

BOOL sdl_putStringValue(BsonObject *const payloadObject, const char *key, NSString *value) {
    BOOL success = NO;
    if (payloadObject && key && value) {
        // rationale: bson_object_put_string does not respect const so we have to make a tmp copy
        const NSUInteger leng = [value lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
        char *buf = malloc(leng);
        if (buf) {
            strncpy(buf, value.UTF8String, leng);
            success = bson_object_put_string(payloadObject, key, buf);
            free(buf);
        }
    }
    return success;
}

SDLSystemInfo *sdl_parseSystemInfo(BsonObject *const payloadObject) {
    SDLSystemInfo *systemInfo = nil;
    NSString *make = payloadObject ? sdl_getStringValue(payloadObject, SDLControlFrameVehicleMake) : nil;
    if (make.length > 0) {
        SDLVehicleType *vehicleType = [[SDLVehicleType alloc] init];
        vehicleType.make = make;
        vehicleType.model = sdl_getStringValue(payloadObject, SDLControlFrameVehicleModel);
        vehicleType.modelYear = sdl_getStringValue(payloadObject, SDLControlFrameVehicleModelYear);
        vehicleType.trim = sdl_getStringValue(payloadObject, SDLControlFrameVehicleTrim);
        NSString *hardVersion = sdl_getStringValue(payloadObject, SDLControlFrameVehicleHardVersion);
        NSString *softVersion = sdl_getStringValue(payloadObject, SDLControlFrameVehicleSoftVersion);
        systemInfo = [[SDLSystemInfo alloc] initWithVehicleType:vehicleType systemSoftwareVersion:softVersion systemHardwareVersion:hardVersion];
    }

    return systemInfo;
}

- (nullable NSArray<NSNumber *> *)sdl_getServiceTransports:(BsonObject *)payloadObject forKey:(const char * const)key {
    if (payloadObject == NULL || key == NULL) {
        return nil;
    }

    BsonArray *arrayObject = bson_object_get_array(payloadObject, key);
    if (arrayObject == NULL) {
        return nil;
    }

    NSMutableArray<NSNumber *> *transports = [NSMutableArray array];
    int32_t num;
    size_t index = 0;

    while ((num = bson_array_get_int32(arrayObject, index)) != -1) {
        [transports addObject:@(num)];
        index++;
    }

    return [transports copy];
}

- (void)sdl_addServiceTransports:(BsonObject *)payloadObject fromArray:(NSArray<NSNumber *> *)array forKey:(const char * const)key {
    if (payloadObject == NULL || array == nil || key == NULL) {
        return;
    }

    BsonArray arrayObject;
    // currently there are 2 transports defined (primary and secondary)
    bson_array_initialize(&arrayObject, 2);

    for (NSNumber *num in array) {
        int32_t transport = [num intValue];
        if (transport != -1) {
            bson_array_add_int32(&arrayObject, transport);
        }
    }

    bson_object_put_array(payloadObject, key, &arrayObject);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@>: Protocol Version: %@, hash id: %d, MTU: %lld, auth token: %@, secondary transports: %@, transports for audio service: %@, transports for video service: %@", NSStringFromClass(self.class), self.protocolVersion, self.hashId, self.mtu, self.authToken, self.secondaryTransports, self.audioServiceTransports, self.videoServiceTransports];
}

@end

NS_ASSUME_NONNULL_END
