//
//  SDLMenuReplaceOperation.h
//  SmartDeviceLink
//
//  Created by Joel Fischer on 1/20/21.
//  Copyright © 2021 smartdevicelink. All rights reserved.
//

#import "SDLAsynchronousOperation.h"

#import "SDLAsynchronousOperation.h"

#import "SDLMenuReplaceUtilities.h"

@protocol SDLConnectionManagerType;

@class SDLFileManager;
@class SDLMenuCell;
@class SDLMenuConfiguration;
@class SDLWindowCapability;

NS_ASSUME_NONNULL_BEGIN

@interface SDLMenuReplaceOperation : SDLAsynchronousOperation

@property (strong, nonatomic) SDLWindowCapability *windowCapability;
@property (strong, nonatomic) SDLMenuConfiguration *menuConfiguration;
@property (strong, nonatomic) NSArray<SDLMenuCell *> *currentMenu;

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager fileManager:(SDLFileManager *)fileManager windowCapability:(SDLWindowCapability *)windowCapability menuConfiguration:(SDLMenuConfiguration *)menuConfiguration currentMenu:(NSArray<SDLMenuCell *> *)currentMenu updatedMenu:(NSArray<SDLMenuCell *> *)updatedMenu compatibilityModeEnabled:(BOOL)compatbilityModeEnabled currentMenuUpdatedBlock:(SDLCurrentMenuUpdatedBlock)currentMenuUpdatedBlock;

@end

NS_ASSUME_NONNULL_END
