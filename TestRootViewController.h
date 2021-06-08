//
//  TestRootViewController.h
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 08.06.2021.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import <UIKit/UIKit.h>

@class ProxyManager;

NS_ASSUME_NONNULL_BEGIN

@interface TestRootViewController : UIViewController
@property (nullable, nonatomic, weak) ProxyManager *proxyManager;
@end

NS_ASSUME_NONNULL_END
