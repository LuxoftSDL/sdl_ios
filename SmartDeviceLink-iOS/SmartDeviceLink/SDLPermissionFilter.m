//
//  SDLPermissionFilter.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 11/18/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import "SDLPermissionFilter.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SDLPermissionFilter

#pragma mark - Lifecycle

- (instancetype)init {
    return [self initWithRPCNames:@[] groupType:SDLPermissionGroupTypeAny observer:^(NSDictionary<SDLPermissionRPCName *,NSNumber<SDLBool> *> * _Nonnull changedDict, SDLPermissionStatus status) {}];
}

- (instancetype)initWithRPCNames:(NSArray<SDLPermissionRPCName *> *)rpcNames groupType:(SDLPermissionGroupType)groupType observer:(SDLPermissionObserver)observer {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _identifier = [NSUUID UUID];
    _rpcNames = rpcNames;
    _groupType = groupType;
    _observer = observer;
    
    return self;
}

+ (instancetype)filterWithRPCNames:(NSArray<SDLPermissionRPCName *> *)rpcNames groupType:(SDLPermissionGroupType)groupType observer:(SDLPermissionObserver)observer {
    return [[self alloc] initWithRPCNames:rpcNames groupType:groupType observer:observer];
}


#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    SDLPermissionFilter *newFilter = [[self.class allocWithZone:zone] initWithRPCNames:[_rpcNames copyWithZone:zone] groupType:_groupType observer:[_observer copyWithZone:zone]];
    newFilter->_identifier = _identifier;
    
    return newFilter;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    
    if (![object isMemberOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToFilter:object];
}

- (BOOL)isEqualToFilter:(SDLPermissionFilter *)otherFilter {
    return (self.identifier == otherFilter.identifier);
}

@end

NS_ASSUME_NONNULL_END
