//
//  AppConstantsGamma.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/4/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "AppConstantsGamma.h"

@implementation AppConstantsGamma

- (NSString *)ExampleAppName {
    return @"SDL Example Gamma";
}

- (NSString *)ExampleFullAppId {
    return [@"gamma" stringByAppendingString:[super ExampleFullAppId]];
}

- (NSString *)ExampleAppLogoName {
    return @"sdl_logo_red";
}

- (NSString *)ExampleAppNameTTS {
    return @"S D L Example App Gamma. Let's go shopping.";
}

@end
