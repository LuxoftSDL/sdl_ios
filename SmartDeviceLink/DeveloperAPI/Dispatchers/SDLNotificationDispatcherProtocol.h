//
//  SDLNotificationDispatcherProtocol.h
//  SmartDeviceLink
//
//  Created by Leonid Lokhmatov on 2/3/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SDLNotificationDispatcherProtocol <NSObject>
- (NSNotificationCenter*)notificationCenter;
@end

NS_ASSUME_NONNULL_END
