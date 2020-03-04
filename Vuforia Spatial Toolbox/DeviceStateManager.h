//
//  DeviceStateManager.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 2/21/20.
//  Copyright © 2020 Reality Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ CompletionHandlerWithString)(NSString *);

@interface DeviceStateManager : NSObject

+ (id)sharedManager;
- (void)enableOrientationChanges:(CompletionHandlerWithString)completionHandler;

@property (nonatomic, strong) UIView* viewToRotate;

@end

NS_ASSUME_NONNULL_END
