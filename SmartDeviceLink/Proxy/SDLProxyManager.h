//
//  SDLProxyManager.h
//  SmartDeviceLink
//
//  Created by Leonid Lokhmatov on 1/30/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import <Foundation/Foundation.h>

@class SDLProxy;
@class SDLSecondaryTransportManager;
@class SDLEncryptionLifecycleManager;
@protocol SDLProxyListener;

NS_ASSUME_NONNULL_BEGIN

@interface SDLProxyManager : NSObject

+ (instancetype)shared;

/**
 *  Creates a SDLProxy object with a TCP (WiFi) transport network connection.
 *
 *  @param delegate                    The subscriber
 *  @param ipaddress                   The IP address of Core
 *  @param port                        The port address of Core
 *  @param secondaryTransportManager   The secondary transport manager
 *  @param encryptionLifecycleManager  The encryption life cycle manager
 *  @return                            A SDLProxy object
 */
- (SDLProxy *)tcpProxyWithListener:(id<SDLProxyListener>)delegate
                      tcpIPAddress:(NSString *)ipaddress
                           tcpPort:(NSString *)port
         secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager
        encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager
                notificationCenter:(NSNotificationCenter *)notificationCenter;
/**
 *  Creates a SDLProxy object with an iap (USB / Bluetooth) transport network connection.
 *
 *  @param delegate                    The subscriber
 *  @param secondaryTransportManager   The secondary transport manager
 *  @param encryptionLifecycleManager  The encryption life cycle manager
 *  @return                            A SDLProxy object
 */
- (SDLProxy *)iapProxyWithListener:(id<SDLProxyListener>)delegate
         secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager
        encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager
                notificationCenter:(NSNotificationCenter *)notificationCenter;

@end

NS_ASSUME_NONNULL_END
