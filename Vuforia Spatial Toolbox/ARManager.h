//
//  ARManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import "ImageTargetsEAGLView.h"
#import "SampleApplicationSession.h"
#import <Vuforia/CameraDevice.h>
#import "VideoRecordingDelegate.h"

typedef void (^ CompletionHandler)(void);
typedef void (^ MarkerCompletionHandler)(NSDictionary *);
typedef void (^ MarkerListCompletionHandler)(NSArray *);
typedef void (^ MatrixStringCompletionHandler)(NSString *);

@interface ARManager : NSObject <SampleApplicationControl, VideoRecordingDelegate> {
    UIViewController* containingViewController;
//    SEL startedARSelector;
    CompletionHandler arDoneCompletionHandler;
    MarkerListCompletionHandler visibleMarkersCompletionHandler;
    MarkerCompletionHandler cameraMatrixCompletionHandler;
    MarkerCompletionHandler groundPlaneMatrixCompletionHandler;
    MatrixStringCompletionHandler projectionMatrixCompletionHandler;
}

+ (id)sharedManager;

@property (nonatomic) BOOL didStartAR;
@property (nonatomic, strong) ImageTargetsEAGLView* eaglView;
@property (nonatomic, strong) SampleApplicationSession * vapp;
@property (nonatomic, strong) NSMutableArray* markersFound;
@property (nonatomic) BOOL extendedTrackingEnabled;

- (void)setContainingViewController:(UIViewController *)newContainingViewController;
- (void)startARWithCompletionHandler:(CompletionHandler)completionHandler;
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight;
- (void)configureVideoBackgroundWithCameraMode:(Vuforia::CameraDevice::MODE)cameraMode viewWidth:(float)viewWidth andHeight:(float)viewHeight;
- (bool)addNewMarker:(NSString *)markerPath;
- (bool)addNewMarkerFromImage:(NSString *)imagePath forObject:(NSString *)objectID targetWidthMeters:(float)targetWidthMeters;
- (void)getProjectionMatrixStringWithCompletionHandler:(MatrixStringCompletionHandler)completionHandler;
- (void)setMatrixCompletionHandler:(MarkerListCompletionHandler)completionHandler;
- (void)setCameraMatrixCompletionHandler:(MarkerCompletionHandler)completionHandler;
- (void)setGroundPlaneMatrixCompletionHandler:(MarkerCompletionHandler)completionHandler;
- (void)enableExtendedTracking:(BOOL)newState;

- (UIImage *)getCameraScreenshot; // for old screenshot method (todo: replace with new method of glReadPixels)

- (GLchar *)getVideoBackgroundPixels;
- (CGSize)getCurrentARViewBoundsSize;
- (void)recordingStarted;
- (void)recordingStopped;

- (void)pauseCamera;
- (void)resumeCamera;
- (void)focusCamera;
- (bool)tryPlacingGroundAnchorAtScreenX:(float)normalizedScreenX andScreenY:(float)normalizedScreenY;

- (bool)startGroundPlaneTracker;
- (bool)stopGroundPlaneTracker;

@end
