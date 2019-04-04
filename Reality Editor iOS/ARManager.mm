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
#import <Vuforia/SmartTerrain.h>
#import <Vuforia/HitTestResult.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/Tool.h>
#import <Vuforia/StateUpdater.h>

#import <Vuforia/ObjectTargetResult.h>
#import <Vuforia/ImageTargetResult.h>
#import <Vuforia/DeviceTrackable.h>
#import <Vuforia/Anchor.h>
#import <Vuforia/ObjectTargetRaw.h>

#import "SampleApplicationUtils.h"

@implementation ARManager {
    bool isCameraPaused;
    const Vuforia::TrackableResult* deviceTrackableResult;
    const Vuforia::TrackableResult* groundPlaneTrackableResult;

    Vuforia::Anchor* mHitTestAnchor;
    Vuforia::Matrix44F mReticlePose;
    const char* HIT_TEST_ANCHOR_NAME;
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
        HIT_TEST_ANCHOR_NAME = "groundPlaneAnchor";
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
    
    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    [self.vapp initAR:Vuforia::GL_20 orientation:[[UIApplication sharedApplication] statusBarOrientation] deviceMode:Vuforia::Device::MODE_AR stereo:false];
    self.didStartAR = true;
}

- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    [eaglView updateRenderingPrimitives];
}

- (BOOL)addNewMarker:(NSString *)markerPath
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

            } else {
                objectTracker->activateDataSet(dataSet);
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet != NULL;
}

- (NSString *)getProjectionMatrixString
{
    Vuforia::Matrix44F projectionMatrix = [self.eaglView getProjectionMatrix];
    return [self stringFromMatrix44F:projectionMatrix];
}

- (void)getProjectionMatrixStringWithCompletionHandler:(MatrixStringCompletionHandler)completionHandler
{
    projectionMatrixCompletionHandler = completionHandler;
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

- (void)setGroundPlaneMatrixCompletionHandler:(MarkerCompletionHandler)completionHandler
{
    groundPlaneMatrixCompletionHandler = completionHandler;
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

- (BOOL)tryPlacingGroundAnchorAtScreenX:(float)normalizedScreenX andScreenY:(float)normalizedScreenY
{
    float hitTestX = normalizedScreenX; //0.5f;
    float hitTestY = normalizedScreenY; //0.5f;

    // Define a default, assumed device height above the plane where you'd like to place content.
    // The world coordinate system will be scaled accordingly to meet this device height value
    // once you create the first successful anchor from a HitTestResult. If your users are adults
    // to place something on the floor use appx. 1.4m. For a tabletop experience use appx. 0.5m.
    // In apps targeted for kids reduce the assumptions to ~80% of these values.
    const float DEFAULT_HEIGHT_ABOVE_GROUND = 1.4f;
    BOOL shouldCreateAnchor = YES;

//    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().updateState();
//    Vuforia::StateUpdater &stateUpdater = Vuforia::TrackerManager::getStateUpdater();

    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().getLatestState();

//    const Vuforia::State state = Vuforia::TrackerManager::getStateUpdater();

    BOOL isAnchorResultAvailable = [self performHitTestWithNormalizedTouchPointX:hitTestX andNormalizedTouchPointY:hitTestY withDeviceHeightInMeters:DEFAULT_HEIGHT_ABOVE_GROUND toCreateAnchor:shouldCreateAnchor andStateToUse:state];

    return isAnchorResultAvailable;
}

- (BOOL) performHitTestWithNormalizedTouchPointX:(float)normalizedTouchPointX
                        andNormalizedTouchPointY:(float)normalizedTouchPointY
                        withDeviceHeightInMeters:(float) deviceHeightInMeters
                                  toCreateAnchor:(BOOL)createAnchor
                                   andStateToUse:(const Vuforia::State&) state
{
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::PositionalDeviceTracker* deviceTracker = static_cast<Vuforia::PositionalDeviceTracker*> (trackerManager.getTracker(Vuforia::PositionalDeviceTracker::getClassType()));
    Vuforia::SmartTerrain* smartTerrain = static_cast<Vuforia::SmartTerrain*>(trackerManager.getTracker(Vuforia::SmartTerrain::getClassType()));

    if (deviceTracker == nullptr || smartTerrain == nullptr)
    {
        NSLog(@"Failed to perform hit test, trackers not initialized");
        return NO;
    }

    Vuforia::Vec2F hitTestPoint(normalizedTouchPointX, normalizedTouchPointY);
    Vuforia::SmartTerrain::HITTEST_HINT hitTestHint = Vuforia::SmartTerrain::HITTEST_HINT_NONE; // hit test hint is currently unused

    // A hit test is performed for a given State at normalized screen coordinates.
    // The deviceHeight is an developer provided assumption as explained on
    // definition of DEFAULT_HEIGHT_ABOVE_GROUND.
    const auto& hitTestResults = smartTerrain->hitTest(hitTestPoint, hitTestHint, state, deviceHeightInMeters);
    if (!hitTestResults.empty())
    {
        // Use first HitTestResult
        const Vuforia::HitTestResult* hitTestResult = hitTestResults.at(0);

        if (createAnchor)
        {
//            if(mCurrentMode == SAMPLE_APP_INTERACTIVE_MODE)
//            {
                // Destroy previous hit test anchor if needed
                if (mHitTestAnchor != nullptr)
                {
                    NSLog(@"Destroying hit test anchor with name '%s'", HIT_TEST_ANCHOR_NAME);
                    bool result = deviceTracker->destroyAnchor(mHitTestAnchor);
                    NSLog(@"%s hit test anchor", (result ? "Successfully destroyed" : "Failed to destroy"));
                }

                mHitTestAnchor = deviceTracker->createAnchor(HIT_TEST_ANCHOR_NAME, *hitTestResult);
                if (mHitTestAnchor != nullptr)
                {
                    NSLog(@"Successfully created hit test anchor with name '%s'", mHitTestAnchor->getName());
                }
                else
                {
                    NSLog(@"Failed to create hit test anchor");
                }
//            }
//            else if(mCurrentMode == SAMPLE_APP_FURNITURE_MODE)
//            {
//                // Destroy previous hit test anchor if needed
//                if (mFurnitureAnchor != nullptr)
//                {
//                    NSLog(@"Destroying hit test anchor with name '%s'", FURNITURE_ANCHOR_NAME);
//                    bool result = deviceTracker->destroyAnchor(mFurnitureAnchor);
//                    NSLog(@"%s hit test anchor", (result ? "Successfully destroyed" : "Failed to destroy"));
//                }
//
//                mFurnitureAnchor = deviceTracker->createAnchor(FURNITURE_ANCHOR_NAME, *hitTestResult);
//                if (mFurnitureAnchor != nullptr)
//                {
//                    NSLog(@"Successfully created hit test anchor with name '%s'", mFurnitureAnchor->getName());
//
//                    [mFurniture setTransparency:1.0f];
//                }
//                else
//                {
//                    NSLog(@"Failed to create hit test anchor");
//                }
//
//                mIsFurnitureBeingDragged = NO;
//            }
        }

//        if(mCurrentMode == SAMPLE_APP_FURNITURE_MODE)
//            mFurnitureTranslationPoseMatrix = Vuforia::Tool::convertPose2GLMatrix(hitTestResult->getPose());

        NSLog(@"Successfully placed anchor on ground plane");

        mReticlePose = Vuforia::Tool::convertPose2GLMatrix(hitTestResult->getPose());
        return YES;
    }
    else
    {
       // NSLog(@"Hit test returned no results");
        return NO;
    }
}

// adds any targets to Vuforia that should always be present, e.g. the World Reference marker
- (void)addDefaultMarkers
{
    NSString* markerPath = [[NSBundle mainBundle] pathForResource:@"liveworx" ofType:@"xml" inDirectory:@"worldReferenceMarker"];
    [self addNewMarker:markerPath];
}

#pragma mark - SampleApplicationControl Protocol Implementation

- (void) onInitARDone:(NSError *)initError
{
    NSLog(@"onInitARDone");
    
    if (initError == nil) {
        NSError * error = nil;
        
        bool didSimultaneousImagesSucceed = Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 5);
        bool didSimultaneousObjectsSucceed = Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_OBJECT_TARGETS, 2);
        NSLog(@"Set simultaneouse image targets to 5 (%d), simultaneous object targets to 2 (%d)", didSimultaneousImagesSucceed, didSimultaneousObjectsSucceed);

        [self.vapp startAR:&error];
        
        [self.eaglView updateRenderingPrimitives];
        
        Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_NORMAL);
        
        if (arDoneCompletionHandler) {
            arDoneCompletionHandler();
        }
        
        [self addDefaultMarkers];
        
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
    
    // Initialize the object tracker
    Vuforia::Tracker* objectTracker = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (objectTracker == nullptr)
    {
        NSLog(@"Failed to initialize ObjectTracker.");
        return NO;
    }

    // Initialize the device tracker
    Vuforia::Tracker* deviceTracker = trackerManager.initTracker(Vuforia::PositionalDeviceTracker::getClassType());
    if (deviceTracker == nullptr)
    {
        NSLog(@"Failed to initialize DeviceTracker.");
        return NO;
    }

    // todo is this tracker needed?
    Vuforia::Tracker* smartTerrain = trackerManager.initTracker(Vuforia::SmartTerrain::getClassType());
    if (smartTerrain == nullptr)
    {
        NSLog(@"Failed to start SmartTerrain.");
        return NO;
    }
    
    NSLog(@"Initialized trackers");
    return YES;
}

- (bool) doLoadTrackersData // TODO: add via api?
{
    // we don't need to load these here... we can do it one by one using javascript API
    NSLog(@"doLoadTrackersData");
    return true;
}

- (bool) doStartTrackers
{
    NSLog(@"doStartTrackers");

    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    
    // Start object tracker
    Vuforia::Tracker* objectTracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if(objectTracker == nullptr || !objectTracker->start())
    {
        NSLog(@"ERROR: Failed to start object tracker");
        return NO;
    }
    NSLog(@"Successfully started object tracker");
    
    // Start device tracker
    Vuforia::Tracker* deviceTracker = trackerManager.getTracker(Vuforia::PositionalDeviceTracker::getClassType());
    if (deviceTracker == nullptr || !deviceTracker->start())
    {
        NSLog(@"Failed to start DeviceTracker");
        return NO;
    }
    NSLog(@"Successfully started DeviceTracker");
    
    // Start ground plane tracker
    Vuforia::Tracker* smartTerrain = trackerManager.getTracker(Vuforia::SmartTerrain::getClassType());
    if (smartTerrain == nullptr || !smartTerrain->start())
    {
        NSLog(@"Failed to start SmartTerrain");

        // We stop the device tracker since there was an error starting Smart Terrain one
//        deviceTracker->stop();
//        NSLog(@"Stopped DeviceTracker tracker due to failure to start SmartTerrain");

        return NO;
    }
    NSLog(@"Successfully started SmartTerrain");

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

- (BOOL) doUnloadTrackersData
{
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    
    // deactivate and destroy all the datasets for the object tracker
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    if (objectTracker == 0) {
        NSLog(@"Error finding object tracker to unload data");
        return NO;
    }
    
    int numObjectTargets = objectTracker->getActiveDataSets().size();
    for (int i = 0; i < numObjectTargets; i++) {
        Vuforia::DataSet* thisDataSet = objectTracker->getActiveDataSets().at(i);
        
        if (!objectTracker->deactivateDataSet(thisDataSet)) {
            NSLog(@"Failed to deactivate data set");
        }
        
        if (!objectTracker->destroyDataSet(thisDataSet)) {
            NSLog(@"Failed to destroy data set");
        }
    }
    
    // Note: don't need to unload device tracker anchors.
    // On tracker stop, the anchors will be destroyed.
    
    NSLog(@"doUnloadTrackersData");
    return YES;
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
    [self.eaglView configureVideoBackgroundWithCameraMode:[self.vapp getCameraMode] viewWidth:viewWidth viewHeight:viewHeight];
    NSLog(@"configureVideoBackgroundWithViewWidth:andHeight");
}

- (void)configureVideoBackgroundWithCameraMode:(Vuforia::CameraDevice::MODE)cameraMode viewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    [self.eaglView configureVideoBackgroundWithCameraMode:cameraMode viewWidth:viewWidth viewHeight:viewHeight];
    NSLog(@"configureVideoBackgroundWithCameraMode:viewWidth:andHeight");
}

// optional protocol implementation
- (void) onVuforiaUpdate:(Vuforia::State *)state
{
    if (projectionMatrixCompletionHandler) {
        // try getting the projection matrix this frame...
        
        if ([self.eaglView isProjectionMatrixReady]) {
            Vuforia::Matrix44F projectionMatrix = [self.eaglView getProjectionMatrix];
            NSString* projectionMatrixString = [self stringFromMatrix44F:projectionMatrix];
            projectionMatrixCompletionHandler(projectionMatrixString);
            projectionMatrixCompletionHandler = nil;
        } else {
            NSLog(@"projection matrix is not ready at this state");
        }
    }
    
    if (!isCameraPaused) { // if frozen, keep sending old markers into javascript app
        
        // continuously try to find the ground plane until an anchor is successfully placed
        if (mHitTestAnchor == nullptr) {
            [self tryPlacingGroundAnchorAtScreenX:0.5 andScreenY:0.5];
        }

        [self.markersFound removeAllObjects];
        
        int numOfTrackables = state->getTrackableResults().size();;
        for (int i = 0; i < numOfTrackables; i++) {
            
            const Vuforia::TrackableResult* result = state->getTrackableResults().at(i);

            if(result->getStatus() != Vuforia::TrackableResult::DETECTED &&
               result->getStatus() != Vuforia::TrackableResult::TRACKED &&
               result->getStatus() != Vuforia::TrackableResult::EXTENDED_TRACKED) {
                continue;
            }
            
            const Vuforia::Trackable & trackable = result->getTrackable();

            NSString* trackingStatus;

            if (result->getStatus() == Vuforia::TrackableResult::EXTENDED_TRACKED) {
                trackingStatus = @"EXTENDED_TRACKED";
            } else {
                trackingStatus = @"TRACKED";
            };

            /*
            if (result->getStatus() == Vuforia::TrackableResult::DETECTED) {
                trackingStatus = @"DETECTED";
            } else if (result->getStatus() == Vuforia::TrackableResult::TRACKED) {
                trackingStatus = @"TRACKED";
            } else if (result->getStatus() == Vuforia::TrackableResult::EXTENDED_TRACKED) {
                trackingStatus = @"EXTENDED_TRACKED";
            } else
            // removing extended tracking will eliminate the device tracker.
                // is it possible that these two other cases help with object tracking?
            if (result->getStatus() == Vuforia::TrackableResult::NO_POSE) {
                trackingStatus = @"TRACKED";
            }else if (result->getStatus() == Vuforia::TrackableResult::LIMITED) {
                trackingStatus = @"TRACKED";
            }
             */

            Vuforia::Matrix44F modelViewMatrixCorrected = Vuforia::Tool::convert2GLMatrix(result->getPose());
     //       NSLog(@"%f",modelViewMatrixCorrected.data[12]*1000 );
           modelViewMatrixCorrected.data[12] *=  1000;
            modelViewMatrixCorrected.data[13] *=  1000;
            modelViewMatrixCorrected.data[14] *=  1000;

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
                    // what is poseMatrixData?
                                     @"poseMatrixData": [self stringFromMatrix34F:result->getPose()],
                                     @"trackingStatus": trackingStatus,
                    // todo I don't know with width and height actually work with object marker?
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
            
//            if(result->isOfType(Vuforia::DeviceTrackableResult::getClassType())) {
//                devicePoseTemp = result->getPose();
//                mDevicePoseMatrix = SampleApplicationUtils::Matrix44FTranspose(SampleApplicationUtils::Matrix44FInverse(modelViewMatrix));
//                mIsDeviceResultAvailable = YES;
//            } else if(result->isOfType(Vuforia::AnchorResult::getClassType())) {
//                mIsAnchorResultAvailable = YES;
//                mAnchorResultsCount ++;
//
//                if(!strcmp(result->getTrackable().getName(), HIT_TEST_ANCHOR_NAME))
//                {
//                    renderAstronaut = YES;
//                    mHitTestPoseMatrix = modelViewMatrix;
//                }
//
//                if(!strcmp(result->getTrackable().getName(), MID_AIR_ANCHOR_NAME))
//                {
//                    renderDrone = YES;
//                    mMidAirPoseMatrix = modelViewMatrix;
//                }
//            }

            // send in Positional Device Trackers' information in a different way, via the camera matrix
            if (trackable.isOfType(Vuforia::DeviceTrackable::getClassType())) {
                deviceTrackableResult = result;
                if (cameraMatrixCompletionHandler) {
                    cameraMatrixCompletionHandler(marker);
                }
                continue;
            }

            // send in Ground Plane Anchor information in a different way, via the groundPlane matrix
            if (trackable.isOfType(Vuforia::Anchor::getClassType())) {
                groundPlaneTrackableResult = result;
                if (groundPlaneMatrixCompletionHandler) {
                    groundPlaneMatrixCompletionHandler(marker);
                }
                continue;
            }

            if(![trackingStatus isEqualToString:@"EXTENDED_TRACKED"]) {
                [self.markersFound addObject:marker];
            }
            
        }
        
    }
    
    if (visibleMarkersCompletionHandler) {
        visibleMarkersCompletionHandler(self.markersFound);
    }
}

@end
