/*===============================================================================
Copyright (c) 2015-2018 PTC Inc. All Rights Reserved.

 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "SampleApplicationSession.h"
#import "SampleApplicationUtils.h"
#import <Vuforia/Vuforia.h>
#import <Vuforia/Vuforia_iOS.h>
#import <Vuforia/Tool.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/VideoBackgroundConfig.h>
#import <Vuforia/UpdateCallback.h>

#import <UIKit/UIKit.h>

#import "vuforiaKey.h"

#define DEBUG_SAMPLE_APP 1

namespace {
    // --- Data private to this unit ---
    
    // instance of the seesion
    // used to support the Vuforia callback
    // there should be only one instance of a session
    // at any given point of time
    SampleApplicationSession* instance = nil;
    
    // Vuforia initialisation flags (passed to Vuforia before initialising)
    int mVuforiaInitFlags;
    
    // camera to use for the session
    Vuforia::CameraDevice::CAMERA_DIRECTION mCamera = Vuforia::CameraDevice::CAMERA_DIRECTION_DEFAULT;
    
    // class used to support the Vuforia callback mechanism
    class VuforiaApplication_UpdateCallback : public Vuforia::UpdateCallback {
        virtual void Vuforia_onUpdate(Vuforia::State& state);
    } vuforiaUpdate;

    // NSerror domain for errors coming from the Sample application template classes
    NSString * SAMPLE_APPLICATION_ERROR_DOMAIN = @"vuforia_sample_application";
}

@interface SampleApplicationSession ()

@property (nonatomic, readwrite) UIInterfaceOrientation mARViewOrientation;
@property (nonatomic, readwrite) BOOL cameraIsActive;

@property (nonatomic, readwrite) Vuforia::Device::MODE deviceMode;
@property (nonatomic, readwrite) bool stereo;

// SampleApplicationControl delegate (receives callbacks in response to particular
// events, such as completion of Vuforia initialisation)
@property (nonatomic, assign) id delegate;

@end


@implementation SampleApplicationSession

- (id)initWithDelegate:(id<SampleApplicationControl>) delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        // we keep a reference of the instance in order to implement the Vuforia callback
        instance = self;
    }
    return self;
}

// build a NSError
- (NSError *) NSErrorWithCode:(int) code {
    return [NSError errorWithDomain:SAMPLE_APPLICATION_ERROR_DOMAIN code:code userInfo:nil];
}

- (NSError *) NSErrorWithCode:(NSString *) description code:(NSInteger)code {
    NSDictionary *userInfo = @{
                           NSLocalizedDescriptionKey: description
                           };
    return [NSError errorWithDomain:SAMPLE_APPLICATION_ERROR_DOMAIN
                                     code:code
                                 userInfo:userInfo];
}

- (NSError *) NSErrorWithCode:(int) code error:(NSError **) error{
    if (error != NULL) {
        *error = [self NSErrorWithCode:code];
        return *error;
    }
    return nil;
}

// Determine whether the device has a retina display
- (BOOL)isRetinaDisplay
{
    // If UIScreen mainScreen responds to selector
    // displayLinkWithTarget:selector: and the scale property is larger than 1.0, then this
    // is a retina display
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && 1.0 < [UIScreen mainScreen].scale);
}

// Initialize the Vuforia SDK
- (void) initAR:(int) VuforiaInitFlags orientation:(UIInterfaceOrientation) ARViewOrientation deviceMode:(Vuforia::Device::MODE)deviceMode stereo:(bool)stereo {
    self.cameraIsActive = NO;
    self.cameraIsStarted = NO;
    mVuforiaInitFlags = VuforiaInitFlags;
    self.isRetinaDisplay = [self isRetinaDisplay];
    self.mARViewOrientation = ARViewOrientation;
    self.cameraMode = Vuforia::CameraDevice::MODE_DEFAULT;
    self.deviceMode = deviceMode;
    self.stereo = stereo;

    // Initialising Vuforia is a potentially lengthy operation, so perform it on a
    // background thread
    [self performSelectorInBackground:@selector(initVuforiaInBackground) withObject:nil];
}

// Initialise Vuforia
// (Performed on a background thread)
- (void)initVuforiaInBackground
{
    // Background thread must have its own autorelease pool
    @autoreleasepool {
        Vuforia::setInitParameters(mVuforiaInitFlags, vuforiaKey);
        
        // Vuforia::init() will return positive numbers up to 100 as it progresses
        // towards success.  Negative numbers indicate error conditions
        NSInteger initSuccess = 0;
        do {
            initSuccess = Vuforia::init();
        } while (0 <= initSuccess && 100 > initSuccess);
        
        if (100 == initSuccess) {
            // We can now continue the initialization of Vuforia
            // (on the main thread)
            [self performSelectorOnMainThread:@selector(prepareAR) withObject:nil waitUntilDone:NO];
        }
        else {
            // Failed to initialise Vuforia:
            if (Vuforia::INIT_NO_CAMERA_ACCESS == initSuccess) {
                // On devices running iOS 8+, the user is required to explicitly grant
                // camera access to an App.
                // If camera access is denied, Vuforia::init will return
                // Vuforia::INIT_NO_CAMERA_ACCESS.
                // This case should be handled gracefully, e.g.
                // by warning and instructing the user on how
                // to restore the camera access for this app
                // via Device Settings > Privacy > Camera
                [self performSelectorOnMainThread:@selector(showCameraAccessWarning) withObject:nil waitUntilDone:YES];
            }
            else {
                NSError * error;
                switch(initSuccess) {
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
                // Vuforia initialization error
                [self.delegate onInitARDone:error];
            }
        }
    }
}


// Prompts a dialog to warn the user that
// the camera access was not granted to this App and
// to provide instructions on how to restore it.
-(void) showCameraAccessWarning
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    NSString *message = [NSString stringWithFormat:@"User denied camera access to this App. To restore camera access, go to: \nSettings > Privacy > Camera > %@ and turn it ON as well as \nSettings > General > Restrictions > Camera and turn it ON.", appName];
    
    UIAlertController *uiAlertController =
    [UIAlertController alertControllerWithTitle:@"Camera Access Warning"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction =
    [UIAlertAction actionWithTitle:@"Close"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {
                               // Quit the app when the user dismisses the camera access alert dialog
                               if ([uiAlertController.title isEqualToString:@"Camera Access Warning"])
                               {
                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"kDismissAppViewController" object:nil];
                               }
                           }];
    
    [uiAlertController addAction:defaultAction];
    [uiAlertController presentViewController:uiAlertController animated:YES completion:nil];
}


// Resume Vuforia
- (bool) resumeAR:(NSError **)error {
    Vuforia::onResume();
    
    // if the camera was previously started, but not currently active, then
    // we restart it
    if ((self.cameraIsStarted) && (! self.cameraIsActive)) {
        
        // initialize the camera
        if (! Vuforia::CameraDevice::getInstance().init(mCamera)) {
            [self NSErrorWithCode:E_INITIALIZING_CAMERA error:error];
            return NO;
        }
        
        // select the video mode
        if(! Vuforia::CameraDevice::getInstance().selectVideoMode(self.cameraMode)) {
            [self NSErrorWithCode:-1 error:error];
            return NO;
        }
        
        // configure Vuforia video background
        CGSize ARViewBoundsSize = [self getCurrentARViewBoundsSize];
        [self.delegate configureVideoBackgroundWithViewWidth:ARViewBoundsSize.width
                                                   andHeight:ARViewBoundsSize.height];
        
        // set the FPS to its recommended value
        int recommendedFps = Vuforia::Renderer::getInstance().getRecommendedFps();
        Vuforia::Renderer::getInstance().setTargetFps(recommendedFps);
        
        // start the camera
        if (!Vuforia::CameraDevice::getInstance().start()) {
            [self NSErrorWithCode:E_STARTING_CAMERA error:error];
            return NO;
        }
        
        self.cameraIsActive = YES;
    }
    return YES;
}


// Pause Vuforia
- (bool)pauseAR:(NSError **)error {
    if (self.cameraIsActive) {
        // Stop and deinit the camera
        if(! Vuforia::CameraDevice::getInstance().stop()) {
            [self NSErrorWithCode:E_STOPPING_CAMERA error:error];
            return NO;
        }
        if(! Vuforia::CameraDevice::getInstance().deinit()) {
            [self NSErrorWithCode:E_DEINIT_CAMERA error:error];
            return NO;
        }
        self.cameraIsActive = NO;
    }
    Vuforia::onPause();
    return YES;
}

- (void) Vuforia_onUpdate:(Vuforia::State *) state {
    if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(onVuforiaUpdate:)]) {
        [self.delegate onVuforiaUpdate:state];
    }
}

- (CGSize)getCurrentARViewBoundsSize
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize viewSize = screenBounds.size;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == self.isRetinaDisplay) {
        viewSize.width *= [UIScreen mainScreen].nativeScale;
        viewSize.height *= [UIScreen mainScreen].nativeScale;
    }
    return viewSize;
}

- (void) prepareAR  {
    // we register for the Vuforia callback
    Vuforia::registerCallback(&vuforiaUpdate);
    
    // Tell Vuforia we've created a drawing surface
    Vuforia::onSurfaceCreated();
    
    CGSize viewBoundsSize = [self getCurrentARViewBoundsSize];
    int smallerSize = MIN(viewBoundsSize.width, viewBoundsSize.height);
    int largerSize = MAX(viewBoundsSize.width, viewBoundsSize.height);
    
    // Frames from the camera are always landscape, no matter what the
    // orientation of the device.  Tell Vuforia to rotate the video background (and
    // the projection matrix it provides to us for rendering our augmentation)
    // by the proper angle in order to match the EAGLView orientation
    if (self.mARViewOrientation == UIInterfaceOrientationPortrait)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_90);
    }
    else if (self.mARViewOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_270);
    }
    else if (self.mARViewOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_180);
    }
    else if (self.mARViewOrientation == UIInterfaceOrientationLandscapeRight)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_0);
    }
    
    [self initTracker];
}

- (void) initTracker {
    // ask the application to initialize its trackers
    if (! [self.delegate doInitTrackers]) {
        [self.delegate onInitARDone:[self NSErrorWithCode:E_INIT_TRACKERS]];
        return;
    }
    [self loadTrackerData];
}


- (void) loadTrackerData {
    // Loading tracker data is a potentially lengthy operation, so perform it on
    // a background thread
    [self performSelectorInBackground:@selector(loadTrackerDataInBackground) withObject:nil];
}

// *** Performed on a background thread ***
- (void)loadTrackerDataInBackground
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
    
    Vuforia::Device& device = Vuforia::Device::getInstance();
    if (!device.setMode(self.deviceMode)) {
        NSLog(@"ERROR: failed to set the device mode");
    };
    device.setViewerActive(self.stereo);
}


// Start Vuforia camera with the specified view size
- (bool)startCamera:(Vuforia::CameraDevice::CAMERA_DIRECTION)camera viewWidth:(float)viewWidth andHeight:(float)viewHeight error:(NSError **)error
{
    // initialize the camera
    if (! Vuforia::CameraDevice::getInstance().init(camera)) {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    // select the default video mode
    if(! Vuforia::CameraDevice::getInstance().selectVideoMode(Vuforia::CameraDevice::MODE_DEFAULT)) {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    // configure Vuforia video background
    [self.delegate configureVideoBackgroundWithViewWidth:viewWidth andHeight:viewHeight];
    
    // set the FPS to its recommended value
    int recommendedFps = Vuforia::Renderer::getInstance().getRecommendedFps();
    Vuforia::Renderer::getInstance().setTargetFps(recommendedFps);
    
    // start the camera
    if (!Vuforia::CameraDevice::getInstance().start()) {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    // we keep track of the current camera to restart this
    // camera when the application comes back to the foreground
    mCamera = camera;
    
    // ask the application to start the tracker(s)
    if(! [self.delegate doStartTrackers] ) {
        [self NSErrorWithCode:-1 error:error];
        return NO;
    }
    
    return YES;
}


- (bool) startAR:(Vuforia::CameraDevice::CAMERA_DIRECTION)camera error:(NSError **)error {
    CGSize ARViewBoundsSize = [self getCurrentARViewBoundsSize];
    
    // Start the camera.  This causes Vuforia to locate our EAGLView in the view
    // hierarchy, start a render thread, and then call renderFrameVuforia on the
    // view periodically
    if (! [self startCamera: camera viewWidth:ARViewBoundsSize.width andHeight:ARViewBoundsSize.height error:error]) {
        return NO;
    }
    self.cameraIsActive = YES;
    self.cameraIsStarted = YES;

    return YES;
}

// Stop Vuforia camera
- (bool)stopAR:(NSError **)error {
    // Stop the camera
    if (self.cameraIsActive) {
        // Stop and deinit the camera
        Vuforia::CameraDevice::getInstance().stop();
        Vuforia::CameraDevice::getInstance().deinit();
        self.cameraIsActive = NO;
    }
    self.cameraIsStarted = NO;

    // ask the application to stop the trackers
    if(! [self.delegate doStopTrackers]) {
        [self NSErrorWithCode:E_STOPPING_TRACKERS error:error];
        return NO;
    }
    
    // ask the application to unload the data associated to the trackers
    if(! [self.delegate doUnloadTrackersData]) {
        [self NSErrorWithCode:E_UNLOADING_TRACKERS_DATA error:error];
        return NO;
    }
    
    // ask the application to deinit the trackers
    if(! [self.delegate doDeinitTrackers]) {
        [self NSErrorWithCode:E_DEINIT_TRACKERS error:error];
        return NO;
    }
    
    // Pause and deinitialise Vuforia
    Vuforia::onPause();
    Vuforia::deinit();
    
    return YES;
}

// stop the camera
- (bool) stopCamera:(NSError **)error {
    if (self.cameraIsActive) {
        // Stop and deinit the camera
        Vuforia::CameraDevice::getInstance().stop();
        Vuforia::CameraDevice::getInstance().deinit();
        self.cameraIsActive = NO;
    } else {
        [self NSErrorWithCode:E_CAMERA_NOT_STARTED error:error];
        return NO;
    }
    self.cameraIsStarted = NO;
    
    // Stop the trackers
    if(! [self.delegate doStopTrackers]) {
        [self NSErrorWithCode:E_STOPPING_TRACKERS error:error];
        return NO;
    }

    return YES;
}



- (void) changeOrientation:(UIInterfaceOrientation) ARViewOrientation {
    self.mARViewOrientation = ARViewOrientation;
    
    CGSize arViewBoundsSize = [self getCurrentARViewBoundsSize];
    int smallerSize = MIN(arViewBoundsSize.width, arViewBoundsSize.height);
    int largerSize = MAX(arViewBoundsSize.width, arViewBoundsSize.height);
    
    // Frames from the camera are always landscape, no matter what the
    // orientation of the device.  Tell Vuforia to rotate the video background (and
    // the projection matrix it provides to us for rendering our augmentation)
    // by the proper angle in order to match the EAGLView orientation
    if (self.mARViewOrientation == UIInterfaceOrientationPortrait)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_90);
    }
    else if (self.mARViewOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        Vuforia::onSurfaceChanged(smallerSize, largerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_270);
    }
    else if (self.mARViewOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_180);
    }
    else if (self.mARViewOrientation == UIInterfaceOrientationLandscapeRight)
    {
        Vuforia::onSurfaceChanged(largerSize, smallerSize);
        Vuforia::setRotation(Vuforia::ROTATE_IOS_0);
    }
    
    [self.delegate configureVideoBackgroundWithViewWidth:arViewBoundsSize.width andHeight:arViewBoundsSize.height];
    
}

- (void) errorMessage:(NSString *) message
{
    
    UIAlertController *uiAlertController =
    [UIAlertController alertControllerWithTitle:SAMPLE_APPLICATION_ERROR_DOMAIN
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *action) {

                           }];
    
    [uiAlertController addAction:defaultAction];
    [uiAlertController presentViewController:uiAlertController animated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
// Callback function called by the tracker when each tracking cycle has finished
void VuforiaApplication_UpdateCallback::Vuforia_onUpdate(Vuforia::State& state)
{
    if (instance != nil) {
        [instance Vuforia_onUpdate:&state];
    }
}

@end
