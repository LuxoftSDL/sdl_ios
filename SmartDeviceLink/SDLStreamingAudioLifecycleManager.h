//
//  SDLStreamingAudioLifecycleManager.h
//  SmartDeviceLink
//
//  Created by Joel Fischer on 6/19/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDLHMILevel.h"
#import "SDLProtocolListener.h"
#import "SDLStreamingAudioManagerType.h"
#import "SDLStreamingMediaManagerConstants.h"

@class SDLAudioStreamManager;
@class SDLProtocol;
@class SDLStateMachine;
@class SDLStreamingMediaConfiguration;
@class SDLEncryptionConfiguration;

@protocol SDLConnectionManagerType;


NS_ASSUME_NONNULL_BEGIN

@interface SDLStreamingAudioLifecycleManager : NSObject <SDLProtocolListener, SDLStreamingAudioManagerType>

@property (nonatomic, strong, readonly) SDLAudioStreamManager *audioManager;

@property (strong, nonatomic, readonly) SDLStateMachine *audioStreamStateMachine;
@property (strong, nonatomic, readonly) SDLAudioStreamManagerState *currentAudioStreamState;

@property (strong, nonatomic, readonly) SDLStateMachine *appStateMachine;

@property (copy, nonatomic, nullable) SDLHMILevel hmiLevel;

/**
 *  Whether or not the audio session is connected.
 */
@property (assign, nonatomic, readonly, getter=isAudioConnected) BOOL audioConnected;

/**
 *  Whether or not the audio session is encrypted. This may be different than the requestedEncryptionType.
 */
@property (assign, nonatomic, readonly, getter=isAudioEncrypted) BOOL audioEncrypted;

/**
 *  Whether or not video streaming is supported
 *
 *  @see SDLRegisterAppInterface SDLDisplayCapabilities
 */
@property (assign, nonatomic, readonly, getter=isStreamingSupported) BOOL streamingSupported;

/**
 *  The requested encryption type when a session attempts to connect. This setting applies to both video and audio sessions.
 *
 *  DEFAULT: SDLStreamingEncryptionFlagAuthenticateAndEncrypt
 */
@property (assign, nonatomic) SDLStreamingEncryptionFlag requestedEncryptionType;

- (instancetype)init NS_UNAVAILABLE;

/**
 Create a new streaming media manager for navigation and VPM apps with a specified configuration

 @param connectionManager The pass-through for RPCs
 @param streamingConfiguration The configuration of this streaming media session
 @param encryptionConfiguration The encryption configuration with security managers
 @return A new streaming manager
 */
- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager streamingConfiguration:(SDLStreamingMediaConfiguration *)streamingConfiguration encryptionConfiguration:(SDLEncryptionConfiguration *)encryptionConfiguration NS_DESIGNATED_INITIALIZER;

/**
 *  Start the manager with a completion block that will be called when startup completes. This is used internally. To use an SDLStreamingMediaManager, you should use the manager found on `SDLManager`.
 */
- (void)startWithProtocol:(SDLProtocol *)protocol;

/// This method is used internally to stop the manager when the device disconnects from the module. Since there is no connection between the device and the module there is no point in sending an end audio service control frame as the module will never receive the request.
- (void)stop;

/// This method is used internally to stop the manager when audio needs to be stopped on the secondary transport. The primary transport is still open.
/// 1. Since the primary transport is still open, we will not reset the `hmiLevel` since we can still get notifications from the module with the updated HMI status on the primary transport.
/// 2. We need to send an end audio service control frame to the module to ensure that the audio session is shut down correctly. In order to do this the protocol must be kept open and only destroyed after the module ACKs or NAKs our end audio service request.
/// @param audioEndedCompletionHandler Called when the module ACKs or NAKs to the request to end the audio service.
- (void)endAudioServiceWithCompletionHandler:(void (^)(void))audioEndedCompletionHandler;

/**
 *  This method receives PCM audio data and will attempt to send that data across to the head unit for immediate playback
 *
 *  @param audioData    The data in PCM audio format, to be played
 *
 *  @return Whether or not the data was successfully sent.
 */
- (BOOL)sendAudioData:(NSData *)audioData;

@end

NS_ASSUME_NONNULL_END
