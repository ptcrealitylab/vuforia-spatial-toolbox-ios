//
//  DeviceStateManager.m
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 2/21/20.
//  Copyright © 2020 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "DeviceStateManager.h"

@implementation DeviceStateManager
{
    CompletionHandlerWithString orientationCompletionHandler;
    CompletionHandlerWithString lifeCycleCompletionHandler;
}

+ (id)sharedManager
{
    static DeviceStateManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

// begins listening for UIDeviceOrientationDidChangeNotifications, and store the callback handle
- (void)enableOrientationChanges:(CompletionHandlerWithString)completionHandler
{
    orientationCompletionHandler = completionHandler;

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(orientationChanged:)
       name:UIDeviceOrientationDidChangeNotification
       object:[UIDevice currentDevice]];

    __block DeviceStateManager *blocksafeSelf = self;

    // trigger the callback once with the current orientation
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [blocksafeSelf updateOrientation:[UIDevice currentDevice].orientation];
    });
}

// Rotates the provided view when the device orientation changes, and triggers the callback
- (void)orientationChanged:(NSNotification *)note
{
    UIDevice* device = note.object;
    [self updateOrientation:device.orientation];
}

- (void)updateOrientation:(UIDeviceOrientation)orientation
{
    NSString* orientationString = [self deviceOrientationToString:orientation];

    if ([orientationString isEqualToString:@"landscapeLeft"]) {
        [self rotateView:YES]; // landscapeLeft is flipped upside-down
    } else if ([orientationString isEqualToString:@"landscapeRight"]) {
        [self rotateView:NO]; // landscapeRight is the default for this application
    }

    if (orientationCompletionHandler) {
        orientationCompletionHandler(orientationString);
    }
}

- (NSString *)deviceOrientationToString:(UIDeviceOrientation)orientation
{
    NSString* orientationString = @"unknown";

    switch(orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            orientationString = @"landscapeLeft";
            break;
        case UIDeviceOrientationLandscapeRight:
            orientationString = @"landscapeRight";
            break;
        case UIDeviceOrientationPortrait:
            orientationString = @"portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientationString = @"portraitUpsideDown";
            break;
        case UIDeviceOrientationUnknown:
            orientationString = @"unknown";
            break;
        default:
            break;
    };

    return orientationString;
}

// applies a 180 degree rotation to the viewToRotate if the device is upside-down
- (void)rotateView:(BOOL)upsideDown
{
    if (self.viewToRotate == nil) {
        NSLog(@"You should assign this a view (e.g. the WebView) from the MainViewController");
        return;
    }

    if (upsideDown) {
        [self.viewToRotate setTransform:CGAffineTransformMakeRotation(M_PI)];
    } else {
        [self.viewToRotate setTransform:CGAffineTransformMakeRotation(0)];
    }
}

// begins listening for app life-cycle events, and store the callback handle
- (void)subscribeToAppLifeCycleEvents:(CompletionHandlerWithString)completionHandler
{
    lifeCycleCompletionHandler = completionHandler;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)appDidBecomeActive:(NSNotification*)notification
{
    [self sendLifeCycleEvent:@"appDidBecomeActive"];
}

- (void)appWillResignActive:(NSNotification*)notification
{
    [self sendLifeCycleEvent:@"appWillResignActive"];
}

- (void)appDidEnterBackground:(NSNotification *)notification
{
    [self sendLifeCycleEvent:@"appDidEnterBackground"];
}

- (void)appWillEnterForeground:(NSNotification *)notification
{
    [self sendLifeCycleEvent:@"appWillEnterForeground"];
}

- (void)appWillTerminate:(NSNotification*)note
{
    [self sendLifeCycleEvent:@"appWillTerminate"];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void)sendLifeCycleEvent:(NSString *)eventName
{
    if (lifeCycleCompletionHandler == nil) { return; }
    
    lifeCycleCompletionHandler(eventName);
}

@end
