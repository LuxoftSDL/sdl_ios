//
//  SDLVersion.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 2/19/19.
//  Copyright © 2019 smartdevicelink. All rights reserved.
//

#import "SDLVersion_ext.h"

@implementation SDLVersion (extention)

+ (instancetype)version:(NSUInteger)major :(NSUInteger)minor :(NSUInteger)patch {
    return [[self alloc] initWithMajor:major minor:minor patch:patch];
}

@end
