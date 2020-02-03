//
//  SDLMultiManager.m
//  SmartDeviceLink
//
//  Created by Leonid Lokhmatov on 2/3/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "SDLMultiManager.h"
#import "SDLManager.h"
#import "SDLConfiguration.h"
#import "SDLLifecycleConfiguration.h"

@interface SDLMultiManager ()
@property (nonatomic, strong) NSMutableDictionary* allManagers;
@end

@implementation SDLMultiManager

- (instancetype)init {
    if ((self = [super init])) {
        _allManagers = [NSMutableDictionary dictionaryWithCapacity:4];
    }
    return self;
}

- (SDLManager*)managerForAppId:(NSString*)appId {
    return nil == appId ? nil : self.allManagers[appId];
}

- (SDLManager*)createManagerWithConfiguration:(SDLConfiguration*)configuration delegate:(nullable id<SDLManagerDelegate>)delegate {
    NSString *appId = configuration.lifecycleConfig.appId;
    assert(nil != appId);
    SDLManager *manager = [self managerForAppId:appId];
    if (nil != manager) {
        return manager;
    }
    manager = [[SDLManager alloc] initWithConfiguration:configuration delegate:delegate];
    self.allManagers[appId] = manager;
    return manager;
}

- (void)stopAppId:(NSString*)appId {
    assert(nil != appId);
    SDLManager *manager = [self managerForAppId:appId];
    if (nil != manager) {
        [manager stop];
        [self.allManagers removeObjectForKey:appId];
    }
}

@end
