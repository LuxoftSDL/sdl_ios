//
//  SDLVersion.h
//  SmartDeviceLink
//
//  Created by Joel Fischer on 2/19/19.
//  Copyright © 2019 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDLVersion.h"

/// Specifies a major / minor / patch version number for semantic versioning purposes and comparisons
@interface SDLVersion (extention)
+ (instancetype)version:(NSUInteger)major :(NSUInteger)minor :(NSUInteger)patch;
@end
