/*===============================================================================
 Copyright (c) 2016-2018 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "SampleAppRenderer.h"
#import <UIKit/UIKit.h>

#import <Vuforia/UIGLViewProtocol.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/Tool.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/RotationalDeviceTracker.h>
#import <Vuforia/StateUpdater.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/GLRenderer.h>
#import <Vuforia/VideoBackgroundConfig.h>


#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"


@interface SampleAppRenderer ()

// SampleApplicationControl delegate (receives callbacks in response to particular
// events, such as completion of Vuforia initialisation)
@property (nonatomic, assign) id control;

// Video background shader
@property (nonatomic, readwrite) GLuint vbShaderProgramID;
@property (nonatomic, readwrite) GLint vbVertexHandle;
@property (nonatomic, readwrite) GLint vbTexCoordHandle;
@property (nonatomic, readwrite) GLint vbTexSampler2DHandle;
@property (nonatomic, readwrite) GLint vbProjectionMatrixHandle;
@property (nonatomic, readwrite) CGFloat nearPlane;
@property (nonatomic, readwrite) CGFloat farPlane;
@property (nonatomic, readwrite) Vuforia::VIEW currentView;
@property (nonatomic, readwrite) BOOL mIsActivityInPortraitMode;
// The current set of rendering primitives
@property (nonatomic, readwrite) Vuforia::RenderingPrimitives *currentRenderingPrimitives;

@end


@implementation SampleAppRenderer

- (id)initWithSampleAppRendererControl:(id<SampleAppRendererControl>)control nearPlane:(float)nearPlane farPlane:(float)farPlane {
    self = [super init];
    if (self) {
        self.control = control;
        [self setNearPlane:nearPlane farPlane:farPlane];
    }
    return self;
}

- (void) initRendering {
    // Video background rendering
    self.vbShaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Background.vertsh"
                                                                     fragmentShaderFileName:@"Background.fragsh"];
    
    if (0 < self.vbShaderProgramID) {
        self.vbVertexHandle = glGetAttribLocation(self.vbShaderProgramID, "vertexPosition");
        self.vbTexCoordHandle = glGetAttribLocation(self.vbShaderProgramID, "vertexTexCoord");
        self.vbProjectionMatrixHandle = glGetUniformLocation(self.vbShaderProgramID, "projectionMatrix");
        self.vbTexSampler2DHandle = glGetUniformLocation(self.vbShaderProgramID, "texSampler2D");
    }
    else {
        NSLog(@"Could not initialise video background shader");
    }
    
}


- (void) setNearPlane:(CGFloat) near farPlane:(CGFloat) far {
    self.nearPlane = near;
    self.farPlane = far;
}

- (void)updateRenderingPrimitives
{
    @synchronized(self)
    {
        delete self.currentRenderingPrimitives;
        self.currentRenderingPrimitives = new Vuforia::RenderingPrimitives(Vuforia::Device::getInstance().getRenderingPrimitives());
    }
}

// Draw the current frame using OpenGL
//
// This method is called by Vuforia when it wishes to render the current frame to
// the screen.
//
// *** Vuforia will call this method periodically on a background thread ***
- (void)renderFrameVuforia
{
    @synchronized(self)
    {
        [self renderFrameVuforiaInternal];
    }
}

- (void)renderFrameVuforiaInternal
{
    Vuforia::Renderer& mRenderer = Vuforia::Renderer::getInstance();
    
    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().updateState();
    mRenderer.begin(state);
    
    // We must detect if background reflection is active and adjust the
    // culling direction.
    // If the reflection is active, this means the pose matrix has been
    // reflected as well,
    // therefore standard counter clockwise face culling will result in
    // "inside out" models.
    if(Vuforia::Renderer::getInstance().getVideoBackgroundConfig().mReflection == Vuforia::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW);   //Back camera
    
    if(self.currentRenderingPrimitives == nullptr)
        [self updateRenderingPrimitives];
    
    Vuforia::ViewList& viewList = self.currentRenderingPrimitives->getRenderingViews();
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    // Iterate over the ViewList
    for (int viewIdx = 0; viewIdx < viewList.getNumViews(); viewIdx++) {
        Vuforia::VIEW vw = viewList.getView(viewIdx);
        self.currentView = vw;
        
        // Set up the viewport
        Vuforia::Vec4I viewport;
        // We're writing directly to the screen, so the viewport is relative to the screen
        viewport = self.currentRenderingPrimitives->getViewport(vw);
        
        // Set viewport for current view
        glViewport(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        
        //set scissor
        glScissor(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        
        Vuforia::Matrix34F projMatrix = self.currentRenderingPrimitives->getProjectionMatrix(vw, state.getCameraCalibration());

        Vuforia::Matrix44F rawProjectionMatrixGL = Vuforia::Tool::convertPerspectiveProjection2GLMatrix(projMatrix,
                                                                                                        self.nearPlane,
                                                                                                        self.farPlane);
        
        // Apply the appropriate eye adjustment to the raw projection matrix, and assign to the global variable
        Vuforia::Matrix44F eyeAdjustmentGL = Vuforia::Tool::convert2GLMatrix(self.currentRenderingPrimitives->getEyeDisplayAdjustmentMatrix(vw));
        
        Vuforia::Matrix44F projectionMatrix;
        SampleApplicationUtils::multiplyMatrix(&rawProjectionMatrixGL.data[0], &eyeAdjustmentGL.data[0], &projectionMatrix.data[0]);
        
        if (self.currentView != Vuforia::VIEW_POSTPROCESS) {
            [self.control renderFrameWithState:state projectMatrix:projectionMatrix];
        }
        
        glDisable(GL_SCISSOR_TEST);
        
    }
    
    mRenderer.end();
    
}

- (void)renderVideoBackgroundWithState:(const Vuforia::State&)state
{
    if (self.currentView == Vuforia::VIEW_POSTPROCESS)
    {
        return;
    }
    
    // Use texture unit 0 for the video background - this will hold the camera frame and we want to reuse for all views
    // So need to use a different texture unit for the augmentation
    int vbVideoTextureUnit = 0;
    
    // Bind the video bg texture and get the Texture ID from Vuforia
    Vuforia::GLTextureUnit tex;
    tex.mTextureUnit = vbVideoTextureUnit;
    
    if (! Vuforia::Renderer::getInstance().updateVideoBackgroundTexture(&tex))
    {
        NSLog(@"Unable to bind video background texture!!");
        return;
    }
    
    Vuforia::Matrix44F vbProjectionMatrix = Vuforia::Tool::convert2GLMatrix(
        self.currentRenderingPrimitives->getVideoBackgroundProjectionMatrix(self.currentView));
    
    // Apply the scene scale on video see-through eyewear, to scale the video background and augmentation
    // so that the display lines up with the real world
    // This should not be applied on optical see-through devices, as there is no video background,
    // and the calibration ensures that the augmentation matches the real world
    if (Vuforia::Device::getInstance().isViewerActive())
    {
        float sceneScaleFactor = [self getSceneScaleFactorWithViewId:[self currentView] cameraCalibration:state.getCameraCalibration()];
        SampleApplicationUtils::scalePoseMatrix(sceneScaleFactor, sceneScaleFactor, 1.0f, vbProjectionMatrix.data);
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST);
    
    const Vuforia::Mesh& vbMesh = self.currentRenderingPrimitives->getVideoBackgroundMesh(self.currentView);
    // Load the shader and upload the vertex/texcoord/index data
    glUseProgram(self.vbShaderProgramID);
    glVertexAttribPointer(self.vbVertexHandle, 3, GL_FLOAT, false, 0, vbMesh.getPositionCoordinates());
    glVertexAttribPointer(self.vbTexCoordHandle, 2, GL_FLOAT, false, 0, vbMesh.getUVCoordinates());
    
    glUniform1i(self.vbTexSampler2DHandle, vbVideoTextureUnit);
    
    // Render the video background with the custom shader
    // First, we enable the vertex arrays
    glEnableVertexAttribArray(self.vbVertexHandle);
    glEnableVertexAttribArray(self.vbTexCoordHandle);
    
    // Pass the projection matrix to OpenGL
    glUniformMatrix4fv(self.vbProjectionMatrixHandle, 1, GL_FALSE, vbProjectionMatrix.data);
    
    // Then, we issue the render call
    glDrawElements(GL_TRIANGLES, vbMesh.getNumTriangles() * 3, GL_UNSIGNED_SHORT,
                   vbMesh.getTriangles());
    
    // Finally, we disable the vertex arrays
    glDisableVertexAttribArray(self.vbVertexHandle);
    glDisableVertexAttribArray(self.vbTexCoordHandle);
    
    SampleApplicationUtils::checkGlError("Rendering of the video background failed");
}


-(float)getSceneScaleFactorWithViewId:(Vuforia::VIEW)viewId cameraCalibration:(const Vuforia::CameraCalibration*)cameraCalib
{
    if (cameraCalib == nullptr)
    {
        NSLog(@"Cannot compute scene scale factor, camera calibration is invalid");
        return 0.0f;
    }

    // Get the y-dimension of the physical camera field of view
    Vuforia::Vec2F fovVector = cameraCalib->getFieldOfViewRads();
    float cameraFovYRads = fovVector.data[1];
    
    // Get the y-dimension of the virtual camera field of view
    Vuforia::Vec4F virtualFovVector = self.currentRenderingPrimitives->getEffectiveFov(viewId); // {left, right, bottom, top}
    float virtualFovYRads = virtualFovVector.data[2] + virtualFovVector.data[3];
    
    // The scene-scale factor represents the proportion of the viewport that is filled by
    // the video background when projected onto the same plane.
    // In order to calculate this, let 'd' be the distance between the cameras and the plane.
    // The height of the projected image 'h' on this plane can then be calculated:
    //   tan(fov/2) = h/2d
    // which rearranges to:
    //   2d = h/tan(fov/2)
    // Since 'd' is the same for both cameras, we can combine the equations for the two cameras:
    //   hPhysical/tan(fovPhysical/2) = hVirtual/tan(fovVirtual/2)
    // Which rearranges to:
    //   hPhysical/hVirtual = tan(fovPhysical/2)/tan(fovVirtual/2)
    // ... which is the scene-scale factor
    return tan(cameraFovYRads / 2) / tan(virtualFovYRads / 2);
}


- (CGSize)getCurrentARViewBoundsSize
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize viewSize = screenBounds.size;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    BOOL isRetinaDisplay = [[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && 1.0 < [UIScreen mainScreen].scale;
    
    if (YES == isRetinaDisplay) {
        viewSize.width *= [UIScreen mainScreen].nativeScale;
        viewSize.height *= [UIScreen mainScreen].nativeScale;
    }
    return viewSize;
}


- (void)updateOrientation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        self.mIsActivityInPortraitMode = YES;
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        self.mIsActivityInPortraitMode = NO;
    }
}


// Configure Vuforia with the video background size
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidthConfig andHeight:(float)viewHeightConfig
{
    float viewWidth = viewWidthConfig;
    float viewHeight = viewHeightConfig;
  
    // Get the default video mode
    Vuforia::CameraDevice& cameraDevice = Vuforia::CameraDevice::getInstance();
    Vuforia::VideoMode videoMode = cameraDevice.getVideoMode(Vuforia::CameraDevice::MODE_DEFAULT);
  
    // Configure the video background
    Vuforia::VideoBackgroundConfig config;
    config.mPosition.data[0] = 0.0f;
    config.mPosition.data[1] = 0.0f;
    
    [self performSelectorOnMainThread:@selector(updateOrientation) withObject:self waitUntilDone:YES];
    
    // Determine the orientation of the view.  Note, this simple test assumes
    // that a view is portrait if its height is greater than its width.  This is
    // not always true: it is perfectly reasonable for a view with portrait
    // orientation to be wider than it is high.  The test is suitable for the
    // dimensions used in this sample
    if (self.mIsActivityInPortraitMode) {
        // --- View is portrait ---
      
        // Compare aspect ratios of video and screen.  If they are different we
        // use the full screen size while maintaining the video's aspect ratio,
        // which naturally entails some cropping of the video
        float aspectRatioVideo = (float)videoMode.mWidth / (float)videoMode.mHeight;
        float aspectRatioView = viewHeight / viewWidth;
      
        if (aspectRatioVideo < aspectRatioView) {
            // Video (when rotated) is wider than the view: crop left and right
            // (top and bottom of video)
          
            // --============--
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // --============--
          
            config.mSize.data[0] = (int)videoMode.mHeight * (viewHeight / (float)videoMode.mWidth);
            config.mSize.data[1] = (int)viewHeight;
        }
        else {
            // Video (when rotated) is narrower than the view: crop top and
            // bottom (left and right of video).  Also used when aspect ratios
            // match (no cropping)
          
            // ------------
            // -          -
            // -          -
            // ============
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // ============
            // -          -
            // -          -
            // ------------
          
            config.mSize.data[0] = (int)viewWidth;
            config.mSize.data[1] = (int)videoMode.mWidth * (viewWidth / (float)videoMode.mHeight);
        }
      
    }
    else {
        // --- View is landscape ---
        if (viewWidth < viewHeight) {
            // Swap width/height: this is neded on iOS7 and below
            // as the view width is always reported as if in portrait.
            // On IOS 8, the swap is not needed, because the size is
            // orientation-dependent; so, this swap code in practice
            // will only be executed on iOS 7 and below.
            float temp = viewWidth;
            viewWidth = viewHeight;
            viewHeight = temp;
        }
      
        // Compare aspect ratios of video and screen.  If they are different we
        // use the full screen size while maintaining the video's aspect ratio,
        // which naturally entails some cropping of the video
        float aspectRatioVideo = (float)videoMode.mWidth / (float)videoMode.mHeight;
        float aspectRatioView = viewWidth / viewHeight;
      
        if (aspectRatioVideo < aspectRatioView) {
            // Video is taller than the view: crop top and bottom
          
            // --------------------
            // ====================
            // =                  =
            // =                  =
            // =                  =
            // =                  =
            // ====================
            // --------------------
          
            config.mSize.data[0] = (int)viewWidth;
            config.mSize.data[1] = (int)videoMode.mHeight * (viewWidth / (float)videoMode.mWidth);
        }
        else {
            // Video is wider than the view: crop left and right.  Also used
            // when aspect ratios match (no cropping)
          
            // ---====================---
            // -  =                  =  -
            // -  =                  =  -
            // -  =                  =  -
            // -  =                  =  -
            // ---====================---
          
            config.mSize.data[0] = (int)videoMode.mWidth * (viewHeight / (float)videoMode.mHeight);
            config.mSize.data[1] = (int)viewHeight;
        }
      
    }
  
    // Calculate the viewport for the app to use when rendering
  
#ifdef DEBUG_SAMPLE_APP
    NSLog(@"VideoBackgroundConfig: size: %d,%d", config.mSize.data[0], config.mSize.data[1]);
    NSLog(@"VideoMode:w=%d h=%d", videoMode.mWidth, videoMode.mHeight);
    NSLog(@"width=%7.3f height=%7.3f", viewWidth, viewHeight);
    //NSLog(@"ViewPort: X,Y: %d,%d Size X,Y:%d,%d", viewport.posX,viewport.posY,viewport.sizeX,viewport.sizeY);
#endif
  
    // Set the config
    Vuforia::Renderer::getInstance().setVideoBackgroundConfig(config);
}

@end
