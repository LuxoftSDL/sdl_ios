//
//  SDLCacheFileManager.h
//  SmartDeviceLink
//
//  Created by James Lapinski on 3/10/20.
//  Copyright © 2020 smartdevicelink. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SDLOnSystemRequest

NS_ASSUME_NONNULL_BEGIN

typedef void (^ImageRetrievalCompletionHandler)(UIImage * _Nullable image, NSError * _Nullable error);

@interface SDLCacheFileManager : NSObject

/**
 * Handles a system request from the head unit to use a lock screen icon from a URL.
 *
 * @param request The System request used to retrieve the icon
 * @param completion The handler called when the manager retrieves the icon or fails to do so with an error.
*/
- (void)retrieveImageForRequest:(SDLOnSystemRequest *)request withCompletionHandler:(ImageRetrievalCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
