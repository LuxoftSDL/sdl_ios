//
//  MenuManager.h
//  SmartDeviceLink-Example-ObjC
//
//  Created by Nicole on 5/15/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PerformInteractionManager;
@class SDLManager;
@class SDLMenuCell;
@class SDLVoiceCommand;
@class AppConstants;
@class VehicleDataManager;

NS_ASSUME_NONNULL_BEGIN

@interface MenuManager : NSObject

- (instancetype)initWithAppConst:(AppConstants *)appConst
              vehicleDataManager:(VehicleDataManager *)vehicleDataManager;

- (NSArray<SDLMenuCell *> *)allMenuItemsWithManager:(SDLManager *)manager performManager:(PerformInteractionManager *)performManager;
- (NSArray<SDLVoiceCommand *> *)allVoiceMenuItemsWithManager:(SDLManager *)manager;

@end

NS_ASSUME_NONNULL_END
