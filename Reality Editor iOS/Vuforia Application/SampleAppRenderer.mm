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
{
    BOOL isRecording;
    GLchar pixels[(1920) * (1080) * 4 + 1]; // sized to fit the 1080p video. the +1 shifts the buffer from RGBA to ARGB. bad side effect is that alpha channel is shifted by 1 pixel, but because the alph channel is uniform it doesn't matter
}

// SampleApplicationControl delegate (receives callbacks in response to particular
// events, such as completion of Vuforia initialisation)
@property (nonatomic, assign) id control;

// Video background shader
@property (nonatomic, readwrite) GLuint vbShaderProgramID;
@property (nonatomic, readwrite) GLint vbVertexHandle;
@property (nonatomic, readwrite) GLint vbTexCoordHandle;
@property (nonatomic, readwrite) GLint vbTexSampler2DHandle;
@property (nonatomic, readwrite) GLint vbProjectionMatrixHandle;

@property (nonatomic, readwrite) GLuint videoRecordingShaderProgramID;
@property (nonatomic, readwrite) GLint videoRecordingVertexHandle;
@property (nonatomic, readwrite) GLint videoRecordingTexCoordHandle;
@property (nonatomic, readwrite) GLint videoRecordingTexSampler2DHandle;
@property (nonatomic, readwrite) GLint videoRecordingProjectionMatrixHandle;

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
    
    
    self.videoRecordingShaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"BackgroundFlipped.vertsh"
                                                                                      fragmentShaderFileName:@"Background.fragsh"];
    
    if (0 < self.videoRecordingShaderProgramID) {
        self.videoRecordingVertexHandle = glGetAttribLocation(self.videoRecordingShaderProgramID, "vertexPosition");
        self.videoRecordingTexCoordHandle = glGetAttribLocation(self.videoRecordingShaderProgramID, "vertexTexCoord");
        self.videoRecordingProjectionMatrixHandle = glGetUniformLocation(self.videoRecordingShaderProgramID, "projectionMatrix");
        self.videoRecordingTexSampler2DHandle = glGetUniformLocation(self.videoRecordingShaderProgramID, "texSampler2D");
    } else {
        NSLog(@"Could not initialize video recording shader");
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
    
    // reloads the pixel buffer containing the background every frame while the video is recording
    if (isRecording) {
        [self refreshBackgroundPixelBuffer];
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

- (float)getSceneScaleFactorWithViewId:(Vuforia::VIEW)viewId cameraCalibration:(const Vuforia::CameraCalibration*)cameraCalib
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
    
    viewSize.width *= [UIScreen mainScreen].nativeScale;
    viewSize.height *= [UIScreen mainScreen].nativeScale;
    
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
- (void) configureVideoBackgroundWithCameraMode:(Vuforia::CameraDevice::MODE)cameraMode viewWidth:(float)viewWidthConfig viewHeight:(float)viewHeightConfig
{
    float viewWidth = viewWidthConfig;
    float viewHeight = viewHeightConfig;
  
    // Get the default video mode
    Vuforia::CameraDevice& cameraDevice = Vuforia::CameraDevice::getInstance();
    Vuforia::VideoMode videoMode = cameraDevice.getVideoMode(cameraMode);

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

- (BOOL)isProjectionMatrixReady
{
    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().getLatestState();
    const Vuforia::CameraCalibration* cameraCalibration = state.getCameraCalibration();

    return (self.currentRenderingPrimitives != nullptr && cameraCalibration != nullptr);
}

- (Vuforia::Matrix44F)getProjectionMatrix
{
    if(self.currentRenderingPrimitives == nullptr) {
        [self updateRenderingPrimitives];
    }
    
    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().getLatestState();

    const Vuforia::CameraCalibration* cameraCalibration = state.getCameraCalibration();
    if (cameraCalibration == nullptr) {
        NSLog(@"no camera calibration yet");
    }
    
    Vuforia::ViewList& viewList = self.currentRenderingPrimitives->getRenderingViews();

    // for now, just assumes there is one view
    Vuforia::VIEW vw = viewList.getView(0);
    self.currentView = vw;
    
 
    
    // Set up the viewport
    Vuforia::Vec4I viewport;
    // We're writing directly to the screen, so the viewport is relative to the screen
    viewport = self.currentRenderingPrimitives->getViewport(vw);
    

    
    Vuforia::Matrix34F projMatrix = self.currentRenderingPrimitives->getProjectionMatrix(vw, cameraCalibration);
    
    Vuforia::Matrix44F rawProjectionMatrixGL = Vuforia::Tool::convertPerspectiveProjection2GLMatrix(projMatrix,
                                                                                                    self.nearPlane,
                                                                                                    self.farPlane);
    
    // Apply the appropriate eye adjustment to the raw projection matrix, and assign to the global variable
    Vuforia::Matrix44F eyeAdjustmentGL = Vuforia::Tool::convert2GLMatrix(self.currentRenderingPrimitives->getEyeDisplayAdjustmentMatrix(vw));
    
    Vuforia::Matrix44F projectionMatrix;
    SampleApplicationUtils::multiplyMatrix(&rawProjectionMatrixGL.data[0], &eyeAdjustmentGL.data[0], &projectionMatrix.data[0]);
    
    return projectionMatrix;
}

- (CVPixelBufferRef)refreshBackgroundPixelBuffer
{
    // Start off-screen rendering by binding all read and write commands to a new frame buffer object
    unsigned int fbo;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo); // TODO: maybe change to type GL_DRAW_FRAMEBUFFER so that we still read from the on-screen buffer but we write to the off-screen one?
    
    // attach at least one (color, depth, or stencil) buffer to the frame buffer
    
    // allocate and attach a render buffer. note that it is write-only, although we can retrieve the frame buffer's contents at the end using glReadPixels
//    unsigned int rbo;
//    glGenRenderbuffers(1, &rbo);
//    glBindRenderbuffer(GL_RENDERBUFFER, rbo);
//
//    // actually attach the render buffer to the frame buffer
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rbo);
//
//    glBindRenderbuffer(GL_RENDERBUFFER, 0); // once we've allocated enough memory we can unbind the render buffer

    
    // allocate a texture that we will attach to the frame buffer
    unsigned int texColorBuffer;
    glGenTextures(1, &texColorBuffer);
    glBindTexture(GL_TEXTURE_2D, texColorBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, (1920), (1080), 0, GL_RGB, GL_UNSIGNED_BYTE, NULL); // TODO: change 600, 400 to screen size
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0); // once we've allocated enough memory we can unbind the texture color buffer
    
    // attach the texture to the frame buffer
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texColorBuffer, 0);
    
    // from this point on, the result of all rendering commands will be stored as a texture image

    // TODO: If you want to render your whole screen to a texture of a smaller or larger size you need to call glViewport again (before rendering to your framebuffer) with the new dimensions of your texture, otherwise only a small part of the texture or screen would be drawn onto the texture.
    
    
    // check that the frame buffer is complete, which means it at least has one complete color buffer attachment
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {
        
        
        // ---------- vuforia renderVideoBackground code ------------ //
        
        //    if (self.currentView == Vuforia::VIEW_POSTPROCESS)
        //    {
        //        return 0;
        //    }
        
        // Use texture unit 0 for the video background - this will hold the camera frame and we want to reuse for all views
        // So need to use a different texture unit for the augmentation
        int vbVideoTextureUnit = 0;
        
        // Bind the video bg texture and get the Texture ID from Vuforia
        Vuforia::GLTextureUnit tex;
        tex.mTextureUnit = vbVideoTextureUnit;
        
        if (! Vuforia::Renderer::getInstance().updateVideoBackgroundTexture(&tex))
        {
            NSLog(@"Unable to bind video background texture!!");
            return 0;
        }
        
        Vuforia::Matrix44F vbProjectionMatrix = Vuforia::Tool::convert2GLMatrix(self.currentRenderingPrimitives->getVideoBackgroundProjectionMatrix(self.currentView));
        
        //    // Apply the scene scale on video see-through eyewear, to scale the video background and augmentation
        //    // so that the display lines up with the real world
        //    // This should not be applied on optical see-through devices, as there is no video background,
        //    // and the calibration ensures that the augmentation matches the real world
        //    if (Vuforia::Device::getInstance().isViewerActive())
        //    {
        //        float sceneScaleFactor = [self getSceneScaleFactorWithViewId:[self currentView] cameraCalibration:state.getCameraCalibration()];
        //        SampleApplicationUtils::scalePoseMatrix(sceneScaleFactor, sceneScaleFactor, 1.0f, vbProjectionMatrix.data);
        //    }
        
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_CULL_FACE);
        glDisable(GL_SCISSOR_TEST);
        
        const Vuforia::Mesh& vbMesh = self.currentRenderingPrimitives->getVideoBackgroundMesh(self.currentView);
        // Load the shader and upload the vertex/texcoord/index data
        glUseProgram(self.videoRecordingShaderProgramID);
        glVertexAttribPointer(self.videoRecordingVertexHandle, 3, GL_FLOAT, false, 0, vbMesh.getPositionCoordinates());
        glVertexAttribPointer(self.videoRecordingTexCoordHandle, 2, GL_FLOAT, false, 0, vbMesh.getUVCoordinates());
        
        glUniform1i(self.vbTexSampler2DHandle, vbVideoTextureUnit);
        
        // Render the video background with the custom shader
        // First, we enable the vertex arrays
        glEnableVertexAttribArray(self.videoRecordingVertexHandle);
        glEnableVertexAttribArray(self.videoRecordingTexCoordHandle);
        
        // Pass the projection matrix to OpenGL
        glUniformMatrix4fv(self.videoRecordingProjectionMatrixHandle, 1, GL_FALSE, vbProjectionMatrix.data);
        
        // Then, we issue the render call
        glDrawElements(GL_TRIANGLES, vbMesh.getNumTriangles() * 3, GL_UNSIGNED_SHORT,
                       vbMesh.getTriangles());
        
        // Finally, we disable the vertex arrays
        glDisableVertexAttribArray(self.videoRecordingVertexHandle);
        glDisableVertexAttribArray(self.videoRecordingTexCoordHandle);
        
//        GLchar pixels[600 * 400 * 4];
        glReadPixels(0, 0, (1920), (1080), GL_RGBA, GL_UNSIGNED_BYTE, pixels+1);
        
        
        
//        NSLog(@"pixels: %@", pixels);
//        NSLog(@"...");
    
        
//        return pixels;
        
        
//        CGSize size = CGSizeMake(600, 400);
//
//        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
//                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
//                                 nil];
//        CVPixelBufferRef pxbuffer = NULL;
//
//        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                              size.width,
//                                              size.height,
//                                              kCVPixelFormatType_32ARGB,
//                                              (__bridge CFDictionaryRef) options,
//                                              &pxbuffer);
//
//        if (status != kCVReturnSuccess){
//            NSLog(@"Failed to create pixel buffer");
//        }
        
        
        
        //    SampleApplicationUtils::checkGlError("Rendering of the video background failed");

    } else {
        NSLog(@"ERROR::FRAMEBUFFER:: Framebuffer is not complete!");
    }
    
    // To make sure all rendering operations will have a visual impact on the main window we need to make the default framebuffer active again by binding to 0
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    // When we're done with all framebuffer operations, do not forget to delete the framebuffer object
    glDeleteFramebuffers(1, &fbo);
    glDeleteTextures(1, &texColorBuffer); // also delete the texture
    
    return 0;
    
}

- (GLchar *)getVideoBackgroundPixels
{
    return pixels;
//    // TODO: return pixels with rows flipped vertically
//    GLchar flippedPixels[(1920) * (1080) * 4 + 1];
//    // Add data for all the pixels in the image
//    for( int row = 0; row < 1080; ++row )
//    {
//        for( int col = 0; col < 1920 ; ++col )
//        {
//            flippedPixels[row * 1920 + col] = pixels[(1079-row) * 1920 + col];
//        }
//    }
//
//    return flippedPixels; // is of length [600 * 400 * 4]; // TODO: resize for full screen size?
}

- (void)recordingStarted
{
    isRecording = true;
}

- (void)recordingStopped
{
    isRecording = false;
}

@end
