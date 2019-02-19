//
//  ARManager.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//
//  Currently using Vuforia as the AR framework

#import "ARManager.h"

// import Vuforia
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/PositionalDeviceTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/Tool.h>

#import <Vuforia/ObjectTargetResult.h>
#import <Vuforia/ImageTargetResult.h>
#import <Vuforia/DeviceTrackable.h>
#import <Vuforia/Anchor.h>
#import <Vuforia/ObjectTargetRaw.h>

#import "SampleApplicationUtils.h"

@implementation ARManager {
    bool isCameraPaused;
    const Vuforia::TrackableResult* deviceTrackableResult;
}

@synthesize didStartAR;
@synthesize eaglView;
@synthesize vapp;

+ (id)sharedManager
{
    static ARManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        self.markersFound = [NSMutableArray array];
    }
    return self;
}

- (void)setContainingViewController:(UIViewController *)newContainingViewController
{
    if (!containingViewController) {
        containingViewController = newContainingViewController;
        self.vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
        self.eaglView = [[ImageTargetsEAGLView alloc] initWithFrame:[[UIScreen mainScreen] bounds] appSession:self.vapp];
        [self.eaglView setBackgroundColor:UIColor.clearColor];
    } else {
        NSLog(@"You already set the containing view controller, it cannot be changed anymore");
    }
}

- (void)startARWithCompletionHandler:(CompletionHandler)completionHandler
{
    if (!self.vapp) {
        NSLog(@"You must setContainingViewController in order to start AR");
    }
    
    if (self.didStartAR) {
        NSLog(@"AR is already running... don't initialize it again...");
        
        if (arDoneCompletionHandler) {
            arDoneCompletionHandler();
        }
        return;
    }
    
    [containingViewController.view addSubview:self.eaglView];
    [containingViewController.view sendSubviewToBack:self.eaglView];
    
    arDoneCompletionHandler = completionHandler;
    
    [self.vapp initAR:Vuforia::GL_20 orientation:[[UIApplication sharedApplication] statusBarOrientation] deviceMode:Vuforia::Device::MODE_AR stereo:false];
    self.didStartAR = true;
}

- (bool)addNewMarker:(NSString *)markerPath
{
    NSLog(@"loadObjectTrackerDataSet (%@)", markerPath);

    Vuforia::DataSet * dataSet = NULL;
    
    // Get the Vuforia tracker manager image tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (NULL == objectTracker) {
        NSLog(@"ERROR: failed to get the ObjectTracker from the tracker manager");
    } else {
        dataSet = objectTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([markerPath cStringUsingEncoding:NSASCIIStringEncoding], Vuforia::STORAGE_ABSOLUTE)) {
                NSLog(@"ERROR: failed to load data set");
                objectTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    objectTracker->activateDataSet(dataSet);
    
    return dataSet != NULL;
}

- (NSString *)getProjectionMatrixString
{
    float nearPlane = 2;
    float farPlane = 2000;
    const Vuforia::CameraCalibration& cameraCalibration = Vuforia::CameraDevice::getInstance().getCameraCalibration();
    Vuforia::Matrix44F projectionMatrix = Vuforia::Tool::getProjectionGL(cameraCalibration, nearPlane, farPlane);
    return [self stringFromMatrix44F:projectionMatrix];
}

- (NSString *)stringFromMatrix34F:(Vuforia::Matrix34F)vuforiaMatrix
{
    return [NSString stringWithFormat:@"[%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf]",
            vuforiaMatrix.data[0],
            vuforiaMatrix.data[1],
            vuforiaMatrix.data[2],
            vuforiaMatrix.data[3],
            vuforiaMatrix.data[4],
            vuforiaMatrix.data[5],
            vuforiaMatrix.data[6],
            vuforiaMatrix.data[7],
            vuforiaMatrix.data[8],
            vuforiaMatrix.data[9],
            vuforiaMatrix.data[10],
            vuforiaMatrix.data[11]
            ];
}

- (NSString *)stringFromMatrix44F:(Vuforia::Matrix44F)vuforiaMatrix
{
    return [NSString stringWithFormat:@"[%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf]",
            vuforiaMatrix.data[0],
            vuforiaMatrix.data[1],
            vuforiaMatrix.data[2],
            vuforiaMatrix.data[3],
            vuforiaMatrix.data[4],
            vuforiaMatrix.data[5],
            vuforiaMatrix.data[6],
            vuforiaMatrix.data[7],
            vuforiaMatrix.data[8],
            vuforiaMatrix.data[9],
            vuforiaMatrix.data[10],
            vuforiaMatrix.data[11],
            vuforiaMatrix.data[12],
            vuforiaMatrix.data[13],
            vuforiaMatrix.data[14],
            vuforiaMatrix.data[15]
            ];
}

- (void)setMatrixCompletionHandler:(MarkerListCompletionHandler)completionHandler
{
    visibleMarkersCompletionHandler = completionHandler;
}

- (void)setCameraMatrixCompletionHandler:(MarkerCompletionHandler)completionHandler
{
    cameraMatrixCompletionHandler = completionHandler;
}

- (UIImage *)getCameraPixelBuffer
{
    return [self screenshotOfView:self.eaglView excludingViews:@[]];
}

// Source: https://gist.github.com/brennanMKE/10010625
- (UIImage *)screenshotOfView:(UIView *)view excludingViews:(NSArray *)excludedViews {
    //    if (!floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
    //        NSCAssert(FALSE, @"iOS 7 or later is required.");
    //    }
    
    // hide all excluded views before capturing screen and keep initial value
    NSMutableArray *hiddenValues = [@[] mutableCopy];
    for (NSUInteger index=0;index<excludedViews.count;index++) {
        [hiddenValues addObject:[NSNumber numberWithBool:((UIView *)excludedViews[index]).hidden]];
        ((UIView *)excludedViews[index]).hidden = TRUE;
    }
    
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // reset hidden values
    for (NSUInteger index=0;index<excludedViews.count;index++) {
        ((UIView *)excludedViews[index]).hidden = [[hiddenValues objectAtIndex:index] boolValue];
    }
    
    // clean up
    hiddenValues = nil;
    
    return image;
}

- (void)pauseCamera
{
    Vuforia::CameraDevice::getInstance().stop();
    isCameraPaused = true;
}

- (void)resumeCamera
{
    Vuforia::CameraDevice::getInstance().start();
    isCameraPaused = false;
}

- (void)focusCamera
{
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

#pragma mark - SampleApplicationControl Protocol Implementation

- (void) onInitARDone:(NSError *)initError
{
    NSLog(@"onInitARDone");
    
    if (initError == nil) {
        NSError * error = nil;
        
        Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 5);
        Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_OBJECT_TARGETS, 3);
        
        [self.vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        
        [self.eaglView updateRenderingPrimitives];
        
        Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_INFINITY);
        
        if (arDoneCompletionHandler) {
            arDoneCompletionHandler();
        }
        
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertController *uiAlertController =
            [UIAlertController alertControllerWithTitle:@"Error"
                                                message:[initError localizedDescription]
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction =
            [UIAlertAction actionWithTitle:@"OK"
                                     style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"kDismissARViewController" object:nil];
                                   }];
            
            [uiAlertController addAction:defaultAction];
            [containingViewController presentViewController:uiAlertController animated:YES completion:nil];
        });
        self.didStartAR = false;
    }
}

- (bool) doInitTrackers
{
    NSLog(@"doInitTrackers");
    
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    
    // To get the best performance for extended tracking in this application
    // we ensure that the most optimal fusion provider is being used.
    Vuforia::FUSION_PROVIDER_TYPE provider =  Vuforia::getActiveFusionProvider();
    
    // For ImageTargets, the recommended fusion provider mode is
    // the one recommended by the FUSION_OPTIMIZE_IMAGE_TARGETS_AND_VUMARKS enum
    if ((provider& ~Vuforia::FUSION_PROVIDER_TYPE::FUSION_OPTIMIZE_IMAGE_TARGETS_AND_VUMARKS) != 0)
    {
        if (Vuforia::setAllowedFusionProviders(Vuforia::FUSION_PROVIDER_TYPE::FUSION_OPTIMIZE_IMAGE_TARGETS_AND_VUMARKS) == Vuforia::FUSION_PROVIDER_TYPE::FUSION_PROVIDER_INVALID_OPERATION)
        {
            NSLog(@"Failed to select the recommended fusion provider mode (FUSION_OPTIMIZE_IMAGE_TARGETS_AND_VUMARKS).");
            return false;
        }
    }
    
    // Initialize the object tracker
    Vuforia::Tracker* objectTracker = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (objectTracker == nullptr)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    
    Vuforia::setAllowedFusionProviders(Vuforia::FUSION_PROVIDER_TYPE::FUSION_PROVIDER_ALL);
    
    // Initialize the device tracker
    Vuforia::Tracker* deviceTracker = trackerManager.initTracker(Vuforia::PositionalDeviceTracker::getClassType());
    if (deviceTracker == nullptr)
    {
        NSLog(@"Failed to initialize DeviceTracker.");
    }
    
    NSLog(@"Initialized trackers");
    return true;
}

- (bool) doLoadTrackersData // TODO: add via api?
{
    // we don't need to load these here... we can do it one by one using javascript API
    NSLog(@"doLoadTrackersData");
    return true;
}

- (bool) doStartTrackers
{
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    
    Vuforia::Tracker* objectTracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if (objectTracker == 0) {
        NSLog(@"Error starting object tracker");
        return false;
    }
    objectTracker->start();
    
    Vuforia::Tracker* deviceTracker = trackerManager.getTracker(Vuforia::PositionalDeviceTracker::getClassType());
    if (deviceTracker == 0) {
        NSLog(@"Error starting device tracker");
        return false;
    }
    deviceTracker->start();
    
    NSLog(@"doStartTrackers");
    return true;
}

- (bool) doStopTrackers
{
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    
    Vuforia::Tracker* objectTracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if (objectTracker == 0) {
        NSLog(@"Error stopping object tracker");
        return false;
    }
    objectTracker->stop();
    
    Vuforia::Tracker* deviceTracker = trackerManager.getTracker(Vuforia::PositionalDeviceTracker::getClassType());
    if (deviceTracker == 0) {
        NSLog(@"Error stopping device tracker");
        return false;
    }
    deviceTracker->stop();
    
    NSLog(@"doStopTrackers");
    return true;
}

- (bool) doUnloadTrackersData
{
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    
    // deactivate and destroy all the datasets for the object tracker
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    if (objectTracker == 0) {
        NSLog(@"Error finding object tracker to unload data");
        return false;
    }
    int numObjectTargets = objectTracker->getActiveDataSetCount();
    for (int i = 0; i < numObjectTargets; i++) {
        Vuforia::DataSet* thisDataSet = objectTracker->getActiveDataSet(i);
        
        if (!objectTracker->deactivateDataSet(thisDataSet)) {
            NSLog(@"Failed to deactivate data set");
        }
        
        if (!objectTracker->destroyDataSet(thisDataSet)) {
            NSLog(@"Failed to destroy data set");
        }
    }
    
    // destroy all anchors for the device tracker
    Vuforia::PositionalDeviceTracker* deviceTracker = static_cast<Vuforia::PositionalDeviceTracker*>(trackerManager.getTracker(Vuforia::PositionalDeviceTracker::getClassType()));
    if (deviceTracker == 0) {
        NSLog(@"Error finding object tracker to unload data");
        return false;
    }
    int numPositionAnchors = deviceTracker->getNumAnchors();
    for (int i = 0; i < numPositionAnchors; i++) {
        Vuforia::Anchor* thisAnchor = deviceTracker->getAnchor(i);
        
        if (!deviceTracker->destroyAnchor(thisAnchor)) {
            NSLog(@"Failed to destroy anchor");
        }
    }
    
    NSLog(@"doUnloadTrackersData");
    return true;
}

- (bool) doDeinitTrackers
{
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    trackerManager.deinitTracker(Vuforia::PositionalDeviceTracker::getClassType());
    
    NSLog(@"doDeinitTrackers");
    return true;
}

- (void) configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    [self.eaglView configureVideoBackgroundWithViewWidth:viewWidth andHeight:viewHeight];
    NSLog(@"configureVideoBackgroundWithViewWidth:andHeight");
}

// optional protocol implementation
- (void) onVuforiaUpdate:(Vuforia::State *)state
{
    if (!isCameraPaused) { // if frozen, keep sending old markers into javascript app
        
        [self.markersFound removeAllObjects];
        
        int numOfTrackables = state->getNumTrackableResults();
        for (int i=0; i<numOfTrackables; i++) {
            
            const Vuforia::TrackableResult* result = state->getTrackableResult(i);
            
            if(result->getStatus() != Vuforia::TrackableResult::DETECTED &&
               result->getStatus() != Vuforia::TrackableResult::TRACKED &&
               result->getStatus() != Vuforia::TrackableResult::EXTENDED_TRACKED) {
                continue;
            }
            
            const Vuforia::Trackable & trackable = result->getTrackable();

            NSString* trackingStatus;
            if (result->getStatus() == Vuforia::TrackableResult::DETECTED) {
                trackingStatus = @"DETECTED";
            } else if (result->getStatus() == Vuforia::TrackableResult::TRACKED) {
                trackingStatus = @"TRACKED";
            } else if (result->getStatus() == Vuforia::TrackableResult::EXTENDED_TRACKED) {
                trackingStatus = @"EXTENDED_TRACKED";
                continue; // TODO: for now, don't send extended tracking targets to the visibleObjects in javascript
            }
            
            Vuforia::Matrix44F modelViewMatrixCorrected = Vuforia::Tool::convertPose2GLMatrix(result->getPose());
            
            // used for debugging
//            Vuforia::Type trackableType = trackable.getType();
//            NSLog(@"trackable type: %u, status: %@", trackableType.getData(), trackingStatus);
            
            Vuforia::Vec3F markerSize;
            if(trackable.isOfType(Vuforia::ImageTarget::getClassType())){
                Vuforia::ImageTarget* imageTarget = (Vuforia::ImageTarget *)(&trackable);
                markerSize = imageTarget->getSize();
            }

            NSDictionary* marker = @{
                                     @"name": [NSString stringWithUTF8String:trackable.getName()],
                                     @"modelViewMatrix": [self stringFromMatrix44F:modelViewMatrixCorrected],
                                     @"projectionMatrix": [self getProjectionMatrixString],
                                     @"poseMatrixData": [self stringFromMatrix34F:result->getPose()],
                                     @"trackingStatus": trackingStatus,
                                     @"width": [NSNumber numberWithFloat:markerSize.data[0]],
                                     @"height": [NSNumber numberWithFloat:markerSize.data[1]]
                                     };

            // DEBUG statements
//            if (trackable.isOfType(Vuforia::ObjectTarget::getClassType())) {
//                NSLog(@"Object Type");
//            }
//            if (trackable.isOfType(Vuforia::Anchor::getClassType())) {
//                NSLog(@"Anchor Type");
//            }
//            if (trackable.isOfType(Vuforia::ObjectTargetRaw::getClassType())) {
//                NSLog(@"Object Raw Type");
//            }
            
            // send in Positional Device Trackers' information in a different way, via the camera matrix
            if (trackable.isOfType(Vuforia::DeviceTrackable::getClassType())) {
                deviceTrackableResult = result;
                if (cameraMatrixCompletionHandler) {
                    cameraMatrixCompletionHandler(marker);
                }
                continue;
            }

            [self.markersFound addObject:marker];
            
        }
        
    }
    
    if (visibleMarkersCompletionHandler) {
        visibleMarkersCompletionHandler(self.markersFound);
    }
}

@end
