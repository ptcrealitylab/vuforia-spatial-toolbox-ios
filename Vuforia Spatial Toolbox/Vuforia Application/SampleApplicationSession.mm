/*===============================================================================
Copyright (c) 2020 PTC Inc. All Rights Reserved.

 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "SampleApplicationSession.h"
#import "SampleApplicationUtils.h"
#import <Vuforia/Vuforia.h>
#import <Vuforia/iOS/Vuforia_iOS.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/PositionalDeviceTracker.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/Tool.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/UpdateCallback.h>
#import <Vuforia/VideoBackgroundConfig.h>
#pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application (import license key)
#import "vuforiaKey.h"
#pragma mark -

#import <UIKit/UIKit.h>

#define DEBUG_SAMPLE_APP 1

namespace {
    // --- Data private to this unit ---
    
    // Instance of the session
    // used to support the Vuforia Engine callback
    // there should be only one instance of a session
    // at any given point of time
    SampleApplicationSession* mInstance = nil;
    
    // class used to support the Vuforia callback mechanism
    class VuforiaApplication_UpdateCallback : public Vuforia::UpdateCallback {
        virtual void Vuforia_onUpdate(Vuforia::State& state);
    } vuforiaUpdate;

    // NSerror domain for errors coming from the Sample application template classes
    static NSString* const SAMPLE_APPLICATION_ERROR_DOMAIN = @"vuforia_sample_application";
}

@interface SampleApplicationSession ()

@property (nonatomic, readwrite) UIInterfaceOrientation ARViewOrientation;
@property (nonatomic, readwrite) BOOL cameraIsActive;

@property (nonatomic, readwrite) Vuforia::CameraDevice::MODE cameraMode;

// Vuforia Engine initialization flags (passed to Vuforia Engine before initializing)
@property (nonatomic, readwrite) int vuforiaInitFlags;

// SampleApplicationControl delegate (receives callbacks in response to particular
// events, such as completion of Vuforia initialization)
@property (nonatomic, assign) id delegate;

@end


@implementation SampleApplicationSession

- (id) initWithDelegate:(id<SampleApplicationControl>)delegate
{
    self = [super init];
    if (self)
    {
        self.delegate = delegate;
        
        // we keep a reference of the instance in order to implement the Vuforia callback
        mInstance = self;
    }
    return self;
}

// build a NSError
- (NSError *)NSErrorWithCode:(int)code
{
    return [NSError errorWithDomain:SAMPLE_APPLICATION_ERROR_DOMAIN code:code userInfo:nil];
}

- (NSError *) NSErrorWithCode:(NSString *) description code:(NSInteger)code
{
    NSDictionary *userInfo = @{
                           NSLocalizedDescriptionKey: description
                           };
    return [NSError errorWithDomain:SAMPLE_APPLICATION_ERROR_DOMAIN
                               code:code
                           userInfo:userInfo];
}

- (NSError *)NSErrorWithCode:(int)code error:(NSError **)error
{
    if (error != nil)
    {
        *error = [self NSErrorWithCode:code];
        return *error;
    }
    return nil;
}

// Initialize the Vuforia Engine
- (void) initAR:(int)vuforiaInitFlags
    orientation:(UIInterfaceOrientation)ARViewOrientation
{
    [self initAR:vuforiaInitFlags
     orientation:ARViewOrientation
      cameraMode:Vuforia::CameraDevice::MODE_DEFAULT];
}

- (void) initAR:(int)vuforiaInitFlags
    orientation:(UIInterfaceOrientation)ARViewOrientation
     cameraMode:(Vuforia::CameraDevice::MODE)cameraMode
{
    self.cameraIsActive = NO;
    self.cameraIsStarted = NO;
    self.vuforiaInitFlags = vuforiaInitFlags;
    self.ARViewOrientation = ARViewOrientation;
    self.cameraMode = cameraMode;
    
    // Initialising Vuforia is a potentially lengthy operation, so perform it on a
    // background thread
    [self performSelectorInBackground:@selector(initVuforiaInBackground) withObject:nil];
}

- (Vuforia::CameraDevice::MODE) getCameraMode
{
    return self.cameraMode;
}

// Initialise Vuforia
// (Performed on a background thread)
- (void) initVuforiaInBackground
{
    // Background thread must have its own autorelease pool
    @autoreleasepool {
#pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application (Add Vuforia License Key Here)
        Vuforia::setInitParameters(self.vuforiaInitFlags,vuforiaKey);
#pragma mark -
        // Vuforia::init() will return positive numbers up to 100 as it progresses
        // towards success.  Negative numbers indicate error conditions
        NSInteger initSuccess = 0;
        do {
            initSuccess = Vuforia::init();
        } while (initSuccess >= 0 && initSuccess < 100);
        
        if (initSuccess == 100)
        {
            // We can now continue the initialization of Vuforia Engine
            // (on the main thread)
            [self performSelectorOnMainThread:@selector(prepareAR) withObject:nil waitUntilDone:NO];
        }
        else
        {
            NSError * error;
            NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
            NSString *cameraAccessErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"INIT_CAMERA_ACCESS_DENIED", nil), appName, appName];

            switch(initSuccess)
            {
                case Vuforia::INIT_NO_CAMERA_ACCESS:
                    // On devices running iOS 8+, the user is required to explicitly grant
                    // camera access to an App.
                    // If camera access is denied, Vuforia::init will return
                    // Vuforia::INIT_NO_CAMERA_ACCESS.
                    // This case should be handled gracefully, e.g.
                    // by warning and instructing the user on how
                    // to restore the camera access for this app
                    // via Device Settings > Privacy > Camera
                    error = [self NSErrorWithCode:cameraAccessErrorMessage code:initSuccess];
                    break;

                case Vuforia::INIT_LICENSE_ERROR_NO_NETWORK_TRANSIENT:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_LICENSE_ERROR_NO_NETWORK_TRANSIENT", nil) code:initSuccess];
                    break;
                        
                case Vuforia::INIT_LICENSE_ERROR_NO_NETWORK_PERMANENT:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_LICENSE_ERROR_NO_NETWORK_PERMANENT", nil) code:initSuccess];
                    break;
                        
                case Vuforia::INIT_LICENSE_ERROR_INVALID_KEY:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_LICENSE_ERROR_INVALID_KEY", nil) code:initSuccess];
                    break;
                        
                case Vuforia::INIT_LICENSE_ERROR_CANCELED_KEY:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_LICENSE_ERROR_CANCELED_KEY", nil) code:initSuccess];
                    break;
                        
                case Vuforia::INIT_LICENSE_ERROR_MISSING_KEY:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_LICENSE_ERROR_MISSING_KEY", nil) code:initSuccess];
                    break;
                        
                case Vuforia::INIT_LICENSE_ERROR_PRODUCT_TYPE_MISMATCH:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_LICENSE_ERROR_PRODUCT_TYPE_MISMATCH", nil) code:initSuccess];
                    break;
                        
                default:
                    error = [self NSErrorWithCode:NSLocalizedString(@"INIT_default", nil) code:initSuccess];
                    break;
            }
                    
            // Vuforia Engine initialization error
            [self.delegate onInitARDone:error];
        }
    }
}


// Resume Vuforia Engine
- (BOOL) resumeAR:(NSError **)error
{
    Vuforia::onResume();
    
    // if the camera was previously started, but not currently active, then
    // we restart it
    if ((self.cameraIsStarted) && (!self.cameraIsActive))
    {
        // initialize the camera
        if (!Vuforia::CameraDevice::getInstance().init())
        {
            [self NSErrorWithCode:E_INITIALIZING_CAMERA error:error];
            return NO;
        }
        
        // select the video mode
        if(!Vuforia::CameraDevice::getInstance().selectVideoMode(self.cameraMode))
        {
            [self NSErrorWithCode:-1 error:error];
            return NO;
        }
        
        // configure video background
        CGSize ARViewBoundsSize = [self getCurrentARViewBoundsSize];
        [self.delegate configureVideoBackgroundWithCameraMode:self.cameraMode
                                                    viewWidth:ARViewBoundsSize.width
                                                    andHeight:ARViewBoundsSize.height];
        
        // set the FPS to its recommended value
        int recommendedFps = Vuforia::Renderer::getInstance().getRecommendedFps();
        Vuforia::Renderer::getInstance().setTargetFps(recommendedFps);
        
        // start the camera
        if (!Vuforia::CameraDevice::getInstance().start())
        {
            [self NSErrorWithCode:E_STARTING_CAMERA error:error];
            return NO;
        }
        
        self.cameraIsActive = YES;
    }
    
    if (self.cameraIsActive)
    {
        [self.delegate doStartTrackers];
    }
    
    return YES;
}


// Pause Vuforia
- (BOOL) pauseAR:(NSError **)error
{
    BOOL successfullyPaused = YES;
    [self.delegate doStopTrackers];
    
    if (self.cameraIsActive)
    {
        // Stop and deinit the camera
        if(! Vuforia::CameraDevice::getInstance().stop())
        {
            [self NSErrorWithCode:E_STOPPING_CAMERA error:error];
            successfullyPaused = NO;
        }
        
        if(! Vuforia::CameraDevice::getInstance().deinit())
        {
            [self NSErrorWithCode:E_DEINIT_CAMERA error:error];
            successfullyPaused = NO;
        }
        self.cameraIsActive = NO;
    }
    
    Vuforia::onPause();
    return successfullyPaused;
}

- (void)vuforia_onUpdate:(Vuforia::State *)state
{
    if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(onVuforiaUpdate:)])
    {
        [self.delegate onVuforiaUpdate:state];
    }
}

- (CGSize) getCurrentARViewBoundsSize
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize viewSize = screenBounds.size;
    
    viewSize.width *= [UIScreen mainScreen].nativeScale;
    viewSize.height *= [UIScreen mainScreen].nativeScale;
    return viewSize;
}

- (void) prepareAR
{
    // we register for the Vuforia Engine callback
    Vuforia::registerCallback(&vuforiaUpdate);
    
    // Tell Vuforia Engine we've created a drawing surface
    Vuforia::onSurfaceCreated();
    
    CGSize viewBoundsSize = [self getCurrentARViewBoundsSize];
    int smallerSize = MIN(viewBoundsSize.width, viewBoundsSize.height);
    int largerSize = MAX(viewBoundsSize.width, viewBoundsSize.height);
    
    // Frames from the camera are always landscape, no matter what the
    // orientation of the device. Tell Vuforia Engine to rotate the video background (and
    // the projection matrix it provides to us for rendering our augmentation)
    // by the proper angle in order to match the EAGLView orientation
    if (self.ARViewOrientation == UIInterfaceOrientationPortrait)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_90);
    }
    else if (self.ARViewOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_270);
    }
    else if (self.ARViewOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_180);
    }
    else if (self.ARViewOrientation == UIInterfaceOrientationLandscapeRight)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_0);
    }
    
    [self initTracker];
}

- (void) initTracker
{
    // ask the application to initialize its trackers
    if (![self.delegate doInitTrackers])
    {
        [self.delegate onInitARDone:[self NSErrorWithCode:E_INIT_TRACKERS]];
        return;
    }
    [self loadTrackerData];
}


- (void) loadTrackerData
{
    // Loading tracker data is a potentially lengthy operation, so perform it on
    // a background thread
    [self performSelectorInBackground:@selector(loadTrackerDataInBackground) withObject:nil];
}

// *** Performed on a background thread ***
- (void) loadTrackerDataInBackground
{
    // Background thread must have its own autorelease pool
    @autoreleasepool {
        // the application can now prepare the loading of the data
        if(! [self.delegate doLoadTrackersData]) {
            [self.delegate onInitARDone:[self NSErrorWithCode:E_LOADING_TRACKERS_DATA]];
            return;
        }
    }
    
    [self.delegate onInitARDone:nil];
}


// Start Vuforia camera with the specified view size
- (BOOL) startCameraWithViewWidth:(float)viewWidth andHeight:(float)viewHeight error:(NSError **)error
{
    // initialize the camera
    if (!Vuforia::CameraDevice::getInstance().init())
    {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    // select the default video mode
    if(! Vuforia::CameraDevice::getInstance().selectVideoMode(self.cameraMode))
    {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    // configure Vuforia video background
    [self.delegate configureVideoBackgroundWithCameraMode:self.cameraMode
                                                viewWidth:viewWidth
                                                andHeight:viewHeight];
    
    // set the FPS to its recommended value
    int recommendedFps = Vuforia::Renderer::getInstance().getRecommendedFps();
    Vuforia::Renderer::getInstance().setTargetFps(recommendedFps);
    
    // start the camera
    if (!Vuforia::CameraDevice::getInstance().start())
    {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }

    // ask the application to start the tracker(s)
    if (![self.delegate doStartTrackers])
    {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    return YES;
}


- (BOOL) startAR:(NSError **)error
{
    CGSize ARViewBoundsSize = [self getCurrentARViewBoundsSize];
    
    // Start the camera. This causes Vuforia Engine to locate our EAGLView in the view
    // hierarchy, start a render thread, and then call renderFrameVuforia on the
    // view periodically
    if (![self startCameraWithViewWidth:ARViewBoundsSize.width andHeight:ARViewBoundsSize.height error:error])
    {
        return NO;
    }
    
    self.cameraIsActive = YES;
    self.cameraIsStarted = YES;

    return YES;
}

// Stop camera
- (BOOL) stopAR:(NSError **)error
{
    BOOL successfullyStopped = YES;
    
    // Stop the camera
    if (self.cameraIsActive)
    {
        // Stop and deinit the camera
        Vuforia::CameraDevice::getInstance().stop();
        Vuforia::CameraDevice::getInstance().deinit();
        self.cameraIsActive = NO;
    }
    self.cameraIsStarted = NO;

    // ask the application to stop the trackers
    if (![self.delegate doStopTrackers])
    {
        [self NSErrorWithCode:E_STOPPING_TRACKERS error:error];
        successfullyStopped = NO;
    }
    
    // ask the application to unload the data associated to the trackers
    if (![self.delegate doUnloadTrackersData])
    {
        [self NSErrorWithCode:E_UNLOADING_TRACKERS_DATA error:error];
        successfullyStopped = NO;
    }
    
    // ask the application to deinit the trackers
    if (![self.delegate doDeinitTrackers])
    {
        [self NSErrorWithCode:E_DEINIT_TRACKERS error:error];
        successfullyStopped = NO;
    }
    
    // Pause and deinitialize Vuforia Engine
    Vuforia::onPause();
    Vuforia::deinit();
    
    return successfullyStopped;
}

// stop the camera
- (BOOL) stopCamera:(NSError **)error
{
    if (self.cameraIsActive)
    {
        // Stop and deinit the camera
        Vuforia::CameraDevice::getInstance().stop();
        Vuforia::CameraDevice::getInstance().deinit();
        self.cameraIsActive = NO;
    }
    else
    {
        [self NSErrorWithCode:E_CAMERA_NOT_STARTED error:error];
        return NO;
    }
    
    self.cameraIsStarted = NO;
    
    // Stop the trackers
    if (![self.delegate doStopTrackers])
    {
        [self NSErrorWithCode:E_STOPPING_TRACKERS error:error];
        return NO;
    }

    return YES;
}


// Sets the fusion provider type for DeviceTracker optimization
// This setting only affects the Tracker if the DeviceTracker is enabled
// By default, the provider type is set to FUSION_OPTIMIZE_MODEL_TARGETS_AND_SMART_TERRAIN
- (BOOL) setFusionProviderType:(Vuforia::FUSION_PROVIDER_TYPE)providerType
{
    Vuforia::FUSION_PROVIDER_TYPE provider =  Vuforia::getActiveFusionProvider();
    
    if ((provider& ~providerType) != 0)
    {
        if (Vuforia::setAllowedFusionProviders(providerType) == Vuforia::FUSION_PROVIDER_TYPE::FUSION_PROVIDER_INVALID_OPERATION)
        {
            NSLog(@"Failed to set fusion provider type (%d)", providerType);
            return NO;
        }
    }
    
    NSLog(@"Successfully set fusion provider type (%d)", providerType);
    return YES;
}


- (BOOL) resetDeviceTracker:(void (^)(void))completion
{
    BOOL wasTrackerReset = NO;
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::PositionalDeviceTracker* deviceTracker =
    static_cast<Vuforia::PositionalDeviceTracker*>(trackerManager.getTracker(Vuforia::PositionalDeviceTracker::getClassType()));
    
    if (deviceTracker != nullptr)
    {
        wasTrackerReset = deviceTracker->reset();
        
        if (completion != nil)
        {
            completion();
        }
    }
    return wasTrackerReset;
}


- (void) changeOrientation:(UIInterfaceOrientation)ARViewOrientation
{
    self.ARViewOrientation = ARViewOrientation;
    
    CGSize arViewBoundsSize = [self getCurrentARViewBoundsSize];
    int smallerSize = MIN(arViewBoundsSize.width, arViewBoundsSize.height);
    int largerSize = MAX(arViewBoundsSize.width, arViewBoundsSize.height);
    
    // Frames from the camera are always landscape, no matter what the
    // orientation of the device.  Tell Vuforia to rotate the video background (and
    // the projection matrix it provides to us for rendering our augmentation)
    // by the proper angle in order to match the EAGLView orientation
    if (self.ARViewOrientation == UIInterfaceOrientationPortrait)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_90);
    }
    else if (self.ARViewOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_270);
    }
    else if (self.ARViewOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_180);
    }
    else if (self.ARViewOrientation == UIInterfaceOrientationLandscapeRight)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_0);
    }
    
    [self.delegate configureVideoBackgroundWithCameraMode:self.cameraMode
                                                viewWidth:arViewBoundsSize.width
                                                andHeight:arViewBoundsSize.height];
}

////////////////////////////////////////////////////////////////////////////////
// Callback function called by the tracker when each tracking cycle has finished
void VuforiaApplication_UpdateCallback::Vuforia_onUpdate(Vuforia::State& state)
{
    if (mInstance != nil)
    {
        [mInstance vuforia_onUpdate:&state];
    }
}

@end
