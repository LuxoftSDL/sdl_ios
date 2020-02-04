//
//  PerformInteractionManager.h
//  SmartDeviceLink-Example-ObjC
//
//  Created by Nicole on 5/15/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDLTriggerSource.h"

@class SDLCreateInteractionChoiceSet;
@class SDLManager;
@class AppConstants;

NS_ASSUME_NONNULL_BEGIN

@interface PerformInteractionManager : NSObject

- (instancetype)initWithManager:(SDLManager *)manager appConst:(AppConstants *)appConst;
- (void)showWithTriggerSource:(SDLTriggerSource)source;

@end

NS_ASSUME_NONNULL_END
