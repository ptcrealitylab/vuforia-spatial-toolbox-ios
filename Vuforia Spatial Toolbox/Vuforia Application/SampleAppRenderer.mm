/*===============================================================================
 Copyright (c) 2020 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import "SampleAppRenderer.h"
#import <UIKit/UIKit.h>

#import <Vuforia/iOS/UIGLViewProtocol.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/Tool.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/StateUpdater.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/GLRenderer.h>
#import <Vuforia/VideoBackgroundConfig.h>


#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"


@interface SampleAppRenderer ()
{
    #pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application (private fields)
    BOOL isRecording;
    CGSize maxScreenSize; // if the screen is bigger than this, we clip it when writing to video
    GLchar pixels[(1920) * (1080) * 4 + 1]; // allocates at least enough memory for the video, since we don't know the exact screen resolution until runtime. sized to fit the 1080p video. ensure maxScreenSize is set to the same dimensions. the +1 shifts the buffer from RGBA to ARGB. bad side effect is that alpha channel is shifted by 1 pixel, but because the alph channel is uniform it doesn't matter
    #pragma mark -
}
// SampleApplicationControl delegate (receives callbacks in response to particular
// events, such as completion of Vuforia Engine initialization)
@property (nonatomic, assign) id control;

// Video background shader
@property (nonatomic, readwrite) GLuint vbShaderProgramID;
@property (nonatomic, readwrite) GLint vbVertexHandle;
@property (nonatomic, readwrite) GLint vbTexCoordHandle;
@property (nonatomic, readwrite) GLint vbTexSampler2DHandle;
@property (nonatomic, readwrite) GLint vbProjectionMatrixHandle;
@property (nonatomic, readwrite) CGFloat nearPlane;
@property (nonatomic, readwrite) CGFloat farPlane;
@property (nonatomic, readwrite) BOOL mIsActivityInPortraitMode;

// The current set of rendering primitives
@property (nonatomic, readwrite) Vuforia::RenderingPrimitives *currentRenderingPrimitives;

#pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application (private properties)
@property (nonatomic, readwrite) Vuforia::VIEW currentView;

@property (nonatomic, readwrite) GLuint videoRecordingShaderProgramID;
@property (nonatomic, readwrite) GLint videoRecordingVertexHandle;
@property (nonatomic, readwrite) GLint videoRecordingTexCoordHandle;
@property (nonatomic, readwrite) GLint videoRecordingTexSampler2DHandle;
@property (nonatomic, readwrite) GLint videoRecordingProjectionMatrixHandle;
#pragma mark -


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
    
#pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application (private properties)
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
#pragma mark -
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
// This method is called by Vuforia Engine when it wishes to render the current frame to
// the screen.
//
// *** Vuforia Engine will call this method periodically on a background thread ***
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
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    // Set up the viewport
    Vuforia::Vec4I viewport;
    
    // We're writing directly to the screen, so the viewport is relative to the screen
    viewport = self.currentRenderingPrimitives->getViewport(Vuforia::VIEW_SINGULAR);
        
    // Set viewport for current view
    glViewport(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        
    //set scissor
    glScissor(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        
    Vuforia::Matrix34F projMatrix = self.currentRenderingPrimitives->getProjectionMatrix(Vuforia::VIEW_SINGULAR, state.getCameraCalibration());

    Vuforia::Matrix44F projectionMatrixGL = Vuforia::Tool::convertPerspectiveProjection2GLMatrix(projMatrix,
                                                                                                     self.nearPlane,
                                                                                                     self.farPlane);
        
    [self.control renderFrameWithState:state projectMatrix:projectionMatrixGL];
    
    glDisable(GL_SCISSOR_TEST);
    
#pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application
    // reloads the pixel buffer containing the background every frame while the video is recording
    if (isRecording) {
        [self refreshBackgroundPixelBuffer];
    }
#pragma mark -

    mRenderer.end();
    
}

- (void)renderVideoBackgroundWithState:(const Vuforia::State&)state
{
    // Use texture unit 0 for the video background - this will hold the camera frame and we want to reuse for all views
    // So need to use a different texture unit for the augmentation
    int vbVideoTextureUnit = 0;
    
    // Bind the video bg texture and get the Texture ID from Vuforia Engine
    Vuforia::GLTextureUnit tex;
    tex.mTextureUnit = vbVideoTextureUnit;
    
    if (! Vuforia::Renderer::getInstance().updateVideoBackgroundTexture(&tex))
    {
        NSLog(@"Unable to bind video background texture!!");
        return;
    }
    
    Vuforia::Matrix44F vbProjectionMatrix = Vuforia::Tool::convert2GLMatrix(
        self.currentRenderingPrimitives->getVideoBackgroundProjectionMatrix(Vuforia::VIEW_SINGULAR));
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST);
    
    const Vuforia::Mesh& vbMesh = self.currentRenderingPrimitives->getVideoBackgroundMesh(Vuforia::VIEW_SINGULAR);
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

#pragma mark - Spatial Toolbox Extensions to Vuforia Sample Application
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

- (BOOL)isProjectionMatrixReady
{
    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().getLatestState();
    const Vuforia::CameraCalibration* cameraCalibration = state.getCameraCalibration();

    return (self.currentRenderingPrimitives != nullptr && cameraCalibration != nullptr);
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

    CGSize screenSize = [self getCurrentARViewBoundsSize];
    
    // allocate a texture that we will attach to the frame buffer
    unsigned int texColorBuffer;
    glGenTextures(1, &texColorBuffer);
    glBindTexture(GL_TEXTURE_2D, texColorBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, screenSize.width, screenSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
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
        
        // ---------- final step, different from renderVideoBackground ------------ //
        
        // read the resulting image into the pixels byte array, for future reference
        glReadPixels(0, 0, screenSize.width, screenSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixels+1);

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
}

- (void)recordingStarted
{
    isRecording = true;
}

- (void)recordingStopped
{
    isRecording = false;
}

#pragma mark -

@end
