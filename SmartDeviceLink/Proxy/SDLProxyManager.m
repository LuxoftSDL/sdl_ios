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

@implementation SDLProxyManager

static SDLProxyManager * sharedInstance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (SDLProxy *)tcpProxyWithListener:(id<SDLProxyListener>)delegate
                      tcpIPAddress:(NSString *)ipaddress
                           tcpPort:(NSString *)port
         secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager
        encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager
                notificationCenter:(NSNotificationCenter *)notificationCenter {
    SDLTCPTransport *transport = [[SDLTCPTransport alloc] initWithHostName:ipaddress portNumber:port];

    assert(nil != transport);

    SDLProxy *proxy = [[SDLProxy alloc] initWithTransport:transport
                                                 delegate:delegate
                                secondaryTransportManager:secondaryTransportManager
                               encryptionLifecycleManager:encryptionLifecycleManager];
    return proxy;
}

- (SDLProxy *)iapProxyWithListener:(id<SDLProxyListener>)delegate
         secondaryTransportManager:(nullable SDLSecondaryTransportManager *)secondaryTransportManager
        encryptionLifecycleManager:(nullable SDLEncryptionLifecycleManager *)encryptionLifecycleManager
                notificationCenter:(NSNotificationCenter *)notificationCenter {
    SDLIAPTransport *transport = [SDLIAPTransport new];

    assert(nil != transport);

    SDLProxy *proxy = [[SDLProxy alloc] initWithTransport:transport
                                                 delegate:delegate
                                secondaryTransportManager:secondaryTransportManager
                               encryptionLifecycleManager:encryptionLifecycleManager];
    return proxy;
}

@end
