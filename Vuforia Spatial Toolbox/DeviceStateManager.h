//
//  DeviceStateManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 2/21/20.
//  Copyright © 2020 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ CompletionHandlerWithString)(NSString *);

@interface DeviceStateManager : NSObject

+ (id)sharedManager;
- (void)enableOrientationChanges:(CompletionHandlerWithString)completionHandler;
- (void)subscribeToAppLifeCycleEvents:(CompletionHandlerWithString)completionHandler;

@property (nonatomic, strong) UIView* viewToRotate;

@end

NS_ASSUME_NONNULL_END
