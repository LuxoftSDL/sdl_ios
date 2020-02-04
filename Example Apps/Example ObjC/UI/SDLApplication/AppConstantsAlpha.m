//
//  AppConstantsAlpha.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/4/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "AppConstantsAlpha.h"

@implementation AppConstantsAlpha

- (NSString *)ExampleFullAppId {
    return [@"alpha" stringByAppendingString:[super ExampleFullAppId]];
}

- (NSString *)ExampleAppNameTTS {
    return @"S D L Example App Alpha. Hi.";
}

@end
