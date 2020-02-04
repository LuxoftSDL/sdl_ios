//
//  ApplicationBeta.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/4/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "ApplicationBeta.h"
#import "AppConstants.h"
#import "AppConstantsBeta.h"

@implementation ApplicationBeta

- (instancetype)init {
    self = [super initWithConstants:[AppConstantsBeta new]];
    return self;
}

@end
