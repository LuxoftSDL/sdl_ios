//
//  SDLProxyManager.m
//  SmartDeviceLink
//
//  Created by Leonid Lokhmatov on 1/30/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "SDLProxyManager.h"
#import "SDLProxy.h"
#import "SDLSecondaryTransportManager.h"
#import "SDLEncryptionLifecycleManager.h"
#import "SDLProxyListener.h"
#import "SDLTCPTransport.h"
#import "SDLIAPTransport.h"

@interface SDLProxy (internal)
/**
 *  Convenience init.
 *
 *  @param transport                   The type of network connection
 *  @param delegate                    The subscriber
 *  @param secondaryTransportManager   The secondary transport manager
 *  @return                            A SDLProxy object
 */
- (instancetype)initWithTransport:(id<SDLTransportType>)transport delegate:(id<SDLProxyListener>)delegate secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager;

- (instancetype)initWithTransport:(id<SDLTransportType>)transport delegate:(id<SDLProxyListener>)delegate secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager;

@end


@implementation SDLProxyManager

static SDLProxyManager * sharedInstance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (SDLProxy *)tcpProxyWithListener:(id<SDLProxyListener>)listener tcpIPAddress:(NSString *)ipaddress tcpPort:(NSString *)port secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager {
    return [self tcpProxyWithListener:listener tcpIPAddress:ipaddress tcpPort:port secondaryTransportManager:secondaryTransportManager encryptionLifecycleManager:nil];
}

- (SDLProxy *)tcpProxyWithListener:(id<SDLProxyListener>)delegate tcpIPAddress:(NSString *)ipaddress tcpPort:(NSString *)port secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager {
    SDLTCPTransport *transport = [[SDLTCPTransport alloc] initWithHostName:ipaddress portNumber:port];

    assert(nil != transport);

    SDLProxy *proxy = [[SDLProxy alloc] initWithTransport:transport delegate:delegate secondaryTransportManager:secondaryTransportManager encryptionLifecycleManager:encryptionLifecycleManager];

    return proxy;
}

- (SDLProxy *)iapProxyWithListener:(id<SDLProxyListener>)delegate secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager {
    SDLIAPTransport *transport = [[SDLIAPTransport alloc] init];
    SDLProxy *proxy = [[SDLProxy alloc] initWithTransport:transport delegate:delegate secondaryTransportManager:secondaryTransportManager];

    return proxy;
}

- (SDLProxy *)iapProxyWithListener:(id<SDLProxyListener>)delegate secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager {
    SDLIAPTransport *transport = [[SDLIAPTransport alloc] init];
    SDLProxy *proxy = [[SDLProxy alloc] initWithTransport:transport delegate:delegate secondaryTransportManager:secondaryTransportManager encryptionLifecycleManager:encryptionLifecycleManager];

    return proxy;
}

@end
