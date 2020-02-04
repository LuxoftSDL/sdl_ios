//
//  AppConstantsBeta.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/4/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "AppConstantsBeta.h"

@implementation AppConstantsBeta

- (NSString *)ExampleAppName {
    return @"SDL Example Beta";
}

- (NSString *)ExampleFullAppId {
    return [@"beta" stringByAppendingString:[super ExampleFullAppId]];
}

- (NSString *)ExampleAppLogoName {
    return @"sdl_logo_purple";
}

- (NSString *)ExampleAppNameTTS {
    return @"S D L Example App Beta. Are you OK?";
}

@end
