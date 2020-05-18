//
//  SDLStreamingProtocolDelegate.h
//  SmartDeviceLink-iOS
//
//  Created by Sho Amano on 2018/03/23.
//  Copyright © 2018 Xevo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SDLProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol SDLStreamingProtocolDelegate <NSObject>

/// Called when protocol instance for audio and/or video service has been updated.
///
/// If `newVideoProtocol` or `newAudioProtocol` is nil it indicates that underlying transport has become unavailable.
///
/// @param oldVideoProtocol protocol instance that was being used for video streaming
/// @param newVideoProtocol protocol instance that will be used for video streaming
/// @param oldAudioProtocol protocol instance that was being used for audio streaming
/// @param newAudioProtocol protocol instance that will be used for audio streaming
- (void)didUpdateFromOldVideoProtocol:(nullable SDLProtocol *)oldVideoProtocol toNewVideoProtocol:(nullable SDLProtocol *)newVideoProtocol fromOldAudioProtocol:(nullable SDLProtocol *)oldAudioProtocol toNewAudioProtocol:(nullable SDLProtocol *)newAudioProtocol;

/// Called when the audio and/or video must be stopped because the transport has been destroyed or errored out.
/// @param videoProtocol protocol instance that was being used for video streaming
/// @param audioProtocol protocol instance that was being used for audio streaming
- (void)destroyVideoProtocol:(nullable SDLProtocol *)videoProtocol audioProtocol:(nullable SDLProtocol *)audioProtocol;

@end

NS_ASSUME_NONNULL_END
