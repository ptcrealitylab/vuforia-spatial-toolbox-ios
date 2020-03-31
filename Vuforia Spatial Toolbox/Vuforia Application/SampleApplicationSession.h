/*===============================================================================
Copyright (c) 2020 PTC Inc. All Rights Reserved.

 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Vuforia/Matrices.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/Device.h>
#import <Vuforia/State.h>

#define E_INITIALIZING_VUFORIA      100

#define E_INITIALIZING_CAMERA       110
#define E_STARTING_CAMERA           111
#define E_STOPPING_CAMERA           112
#define E_DEINIT_CAMERA             113

#define E_INIT_TRACKERS             120
#define E_LOADING_TRACKERS_DATA     121
#define E_STARTING_TRACKERS         122
#define E_STOPPING_TRACKERS         123
#define E_UNLOADING_TRACKERS_DATA   124
#define E_DEINIT_TRACKERS           125

#define E_CAMERA_NOT_STARTED        150

#define E_INTERNAL_ERROR                -1

// An AR application must implement this protocol in order to be notified of
// the different events during the life cycle of an AR application
@protocol SampleApplicationControl

@required
// this method is called to notify the application that the initialization (initAR) is complete
// usually the application then starts the AR through a call to startAR
- (void)onInitARDone:(NSError *)error;

// the application must initialize its tracker(s)
- (BOOL)doInitTrackers;

// the application must initialize the data associated to its tracker(s)
- (BOOL)doLoadTrackersData;

// the application must starts its tracker(s)
- (BOOL)doStartTrackers;

// the application must stop its tracker(s)
- (BOOL)doStopTrackers;

// the application must unload the data associated its tracker(s)
- (BOOL)doUnloadTrackersData;

// the application must deinititalize its tracker(s)
- (BOOL)doDeinitTrackers;

// the application msut handle the video background configuration
- (void) configureVideoBackgroundWithCameraMode:(Vuforia::CameraDevice::MODE)cameraMode viewWidth:(float)viewWidth andHeight:(float)viewHeight;

@optional
// optional method to handle the Vuforia Engine callback - can be used to swap dataset for instance
- (void) onVuforiaUpdate:(Vuforia::State *)state;

@end

@interface SampleApplicationSession : NSObject

- (id)initWithDelegate:(id<SampleApplicationControl>)delegate;

// initialize the AR library. This is an asynchronous method. When the initialization is complete, the callback method initARDone will be called
- (void) initAR:(int)vuforiaInitFlags orientation:(UIInterfaceOrientation)ARViewOrientation;
- (void) initAR:(int)vuforiaInitFlags orientation:(UIInterfaceOrientation)ARViewOrientation cameraMode:(Vuforia::CameraDevice::MODE)cameraMode;

// start the AR session
- (BOOL)startAR:(NSError **)error;

// pause the AR session
- (BOOL)pauseAR:(NSError **)error;

// resume the AR session
- (BOOL)resumeAR:(NSError **)error;

// stop the AR session
- (BOOL)stopAR:(NSError **)error;

// stop the camera.
// This can be used if you want to switch between the front and the back camera for instance
- (BOOL)stopCamera:(NSError **)error;

// utility methods
- (BOOL)setFusionProviderType:(Vuforia::FUSION_PROVIDER_TYPE) providerType;

- (void)changeOrientation:(UIInterfaceOrientation) ARViewOrientation;

// Get current camera mode
- (Vuforia::CameraDevice::MODE) getCameraMode;

@property (nonatomic, readwrite) BOOL cameraIsStarted;

@end
