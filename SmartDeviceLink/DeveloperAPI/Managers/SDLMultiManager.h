//
//  SDLMultiManager.h
//  SmartDeviceLink
//
//  Created by Leonid Lokhmatov on 2/3/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import <Foundation/Foundation.h>

@class SDLManager;
@class SDLConfiguration;
@protocol SDLManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface SDLMultiManager : NSObject

- (SDLManager*)managerForAppId:(NSString*)appId;

- (void)stopAppId:(NSString*)appId;

#pragma mark Lifecycle

/**
 *  Initialize the manager with a configuration. Call `startWithHandler` to begin waiting for a connection.
 *
 *  @param configuration The app unique configuration for setup.
 *  @param delegate An optional delegate to be notified of hmi level changes and startup and shutdown. It is recommended to be implemented.
 *
 *  @return An instance of SDLManager
 */
- (SDLManager*)createManagerWithConfiguration:(SDLConfiguration*)configuration delegate:(nullable id<SDLManagerDelegate>)delegate;



@end

NS_ASSUME_NONNULL_END
