/*===============================================================================
Copyright (c) 2020 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <Vuforia/Vuforia.h>
#import <Vuforia/State.h>
#import <Vuforia/Tool.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/TrackableResult.h>
#import <Vuforia/DeviceTrackableResult.h>
#import <Vuforia/ImageTargetResult.h>
#import <Vuforia/VideoBackgroundConfig.h>

#import "ImageTargetsEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"


//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the Vuforia Engine camera, which causes Vuforia Engine to locate our
//    EAGLView and start the render thread.
// 3) Vuforia Engine calls our renderFrameVuforia method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


namespace {
    // --- Data private to this unit ---

    // Teapot texture filenames
    const char* textureFilenames[] = {
        "TextureTeapotBrass.png",
        "TextureTeapotBlue.png",
        "TextureTeapotRed.png",
        "Buildings.png"
    };
    
    // Model scale factor
    const float kObjectScaleNormal = 0.003f;
    const float kObjectScaleOffTargetTracking = 0.012f;
    
    const float kObjectTranslateOffTargetTracking = -0.06f;
}


@interface ImageTargetsEAGLView()

- (void) initShaders;
- (void) createFramebuffer;
- (void) deleteFramebuffer;
- (void) setFramebuffer;
- (BOOL) presentFramebuffer;

@property (nonatomic, weak) SampleApplicationSession * vapp;
@property (nonatomic, readwrite) BOOL isDeviceTrackerRelocalizing;
@property (nonatomic, readwrite) BOOL offTargetTrackingEnabled;
@property (nonatomic, weak) id<SampleAppsUIControl> uiControl;

@end

@implementation ImageTargetsEAGLView

@synthesize vapp, offTargetTrackingEnabled, isDeviceTrackerRelocalizing;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id) initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *)app andSampleUIUpdater:(id<SampleAppsUIControl>)sampleAppsUIControl
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.vapp = app;
        self.uiControl = sampleAppsUIControl;

        [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        
        // Load the augmentation textures
        for (int i = 0; i < kNumAugmentationTextures; ++i)
        {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
        }

        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext])
        {
            [EAGLContext setCurrentContext:context];
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < kNumAugmentationTextures; ++i)
        {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
        }

        self.offTargetTrackingEnabled = NO;
        self.isDeviceTrackerRelocalizing = NO;
        sampleAppRenderer = [[SampleAppRenderer alloc]initWithSampleAppRendererControl:self nearPlane:0.01 farPlane:5];
        
        [self loadBuildingsModel];
        [self initShaders];
        
        // we initialize the rendering method of the SampleAppRenderer
        [sampleAppRenderer initRendering];
    }
    
    return self;
}


- (CGSize) getCurrentARViewBoundsSize
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize viewSize = screenBounds.size;
    
    viewSize.width *= [UIScreen mainScreen].nativeScale;
    viewSize.height *= [UIScreen mainScreen].nativeScale;
    return viewSize;
}


- (void) dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context)
    {
        [EAGLContext setCurrentContext:nil];
    }

    for (int i = 0; i < kNumAugmentationTextures; ++i)
    {
        augmentationTexture[i] = nil;
    }
}


- (void) finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void) freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

- (void) setOffTargetTrackingMode:(BOOL)enabled
{
    self.offTargetTrackingEnabled = enabled;
}

- (void) loadBuildingsModel
{
    buildingModel = [[SampleApplication3DModel alloc] initWithTxtResourceName:@"buildings"];
    [buildingModel read];
}


- (void) updateRenderingPrimitives
{
    [sampleAppRenderer updateRenderingPrimitives];
}


//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by Vuforia Engine when it wishes to render the current frame to
// the screen.
//
// *** Vuforia Engine will call this method periodically on a background thread ***
- (void) renderFrameVuforia
{
    if (!self.vapp.cameraIsStarted)
    {
        return;
    }
    
    [sampleAppRenderer renderFrameVuforia];
}

- (void) renderFrameWithState:(const Vuforia::State&)state projectMatrix:(Vuforia::Matrix44F&)projectionMatrix
{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    [sampleAppRenderer renderVideoBackgroundWithState:state];
    
    glEnable(GL_DEPTH_TEST);

    if (self.offTargetTrackingEnabled)
    {
        glDisable(GL_CULL_FACE);
    }
    else
    {
        glEnable(GL_CULL_FACE);
    }
    
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);   //Back camera

    // Set the device pose matrix to identity
    Vuforia::Matrix44F devicePoseMatrix = SampleApplicationUtils::Matrix44FIdentity();
    Vuforia::Matrix44F modelMatrix = SampleApplicationUtils::Matrix44FIdentity();
    
    // Get the device pose
    if (state.getDeviceTrackableResult() != nullptr)
    {
        if (state.getDeviceTrackableResult()->getStatus() != Vuforia::TrackableResult::NO_POSE)
        {
            modelMatrix = Vuforia::Tool::convertPose2GLMatrix(state.getDeviceTrackableResult()->getPose());
            devicePoseMatrix = SampleApplicationUtils::Matrix44FTranspose(SampleApplicationUtils::Matrix44FInverse(modelMatrix));
        }
        
        Vuforia::TrackableResult::STATUS_INFO currentStatusInfo = state.getDeviceTrackableResult()->getStatusInfo();
        // If the current status and the previous do not match then we update the state and UI
        if (self.isDeviceTrackerRelocalizing ^ (currentStatusInfo == Vuforia::TrackableResult::STATUS_INFO::RELOCALIZING))
        {
            self.isDeviceTrackerRelocalizing = !self.isDeviceTrackerRelocalizing;
            [self.uiControl setIsInRelocalizationState:self.isDeviceTrackerRelocalizing];
        }
    }
    
    const auto& trackableResultList = state.getTrackableResults();
    
    // If any target is being tracked, stop the relocalization timer
    for (const auto result: trackableResultList)
    {
        if (!result->isOfType(Vuforia::DeviceTrackableResult::getClassType()))
        {
            int currentStatus = result->getStatus();
            int currentStatusInfo = result->getStatusInfo();
            
            if (currentStatus == Vuforia::TrackableResult::STATUS::TRACKED
                || currentStatusInfo == Vuforia::TrackableResult::STATUS_INFO::NORMAL)
            {
                [self.uiControl setIsTargetTracked:YES];
            }
        }
    }
    
    for (const auto result : trackableResultList)
    {
        if (!result->isOfType(Vuforia::ImageTargetResult::getClassType()) || result->getStatus() == Vuforia::TrackableResult::STATUS::LIMITED)
        {
            continue;
        }
        
        const Vuforia::Trackable& trackable = result->getTrackable();
        modelMatrix = Vuforia::Tool::convertPose2GLMatrix(result->getPose());
        
        // Choose the texture based on the target name
        int targetIndex = 0; // "stones"
        if (!strcmp(trackable.getName(), "chips"))
            targetIndex = 1;
        else if (!strcmp(trackable.getName(), "tarmac"))
            targetIndex = 2;
        
        [self renderModelWithProjection:&projectionMatrix.data[0] withViewMatrix:&devicePoseMatrix.data[0] withModelMatrix:&modelMatrix.data[0] andTextureIndex:targetIndex];
        
        SampleApplicationUtils::checkGlError("EAGLView renderFrameVuforia");
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    [self presentFramebuffer];
}

- (void) renderModelWithProjection:(float*)projectionMatrix
                    withViewMatrix:(float*)viewMatrix
                   withModelMatrix:(float*)modelMatrix
                   andTextureIndex:(int)textureIndex
{
    // OpenGL 2
    Vuforia::Matrix44F modelViewProjection;
    
    // Apply local transformation to our model
    if (self.offTargetTrackingEnabled)
    {
        SampleApplicationUtils::translatePoseMatrix(0.0f, kObjectTranslateOffTargetTracking, 0.0f, modelMatrix);
        SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0, modelMatrix);
        SampleApplicationUtils::scalePoseMatrix(kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, kObjectScaleOffTargetTracking, modelMatrix);
    }
    else
    {
        SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScaleNormal, modelMatrix);
        SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, modelMatrix);
    }
    
    // Combine device pose (view matrix) with model matrix
    SampleApplicationUtils::multiplyMatrix(viewMatrix, modelMatrix,  modelMatrix);
    
    // Do the final combination with the projection matrix
    SampleApplicationUtils::multiplyMatrix(projectionMatrix, modelMatrix, &modelViewProjection.data[0]);
    
    // Activate the shader program and bind the vertex/normal/tex coords
    glUseProgram(shaderProgramID);
    
    if (self.offTargetTrackingEnabled)
    {
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.vertices);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.normals);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.texCoords);
    }
    else
    {
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotVertices);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotNormals);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)teapotTexCoords);
    }
    
    glEnableVertexAttribArray(vertexHandle);
    glEnableVertexAttribArray(normalHandle);
    glEnableVertexAttribArray(textureCoordHandle);
    
    glActiveTexture(GL_TEXTURE0);
    
    if (self.offTargetTrackingEnabled)
    {
        glBindTexture(GL_TEXTURE_2D, augmentationTexture[3].textureID);
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, augmentationTexture[textureIndex].textureID);
    }
    
    // Pass the model view matrix to the shader
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
    glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
    
    // Draw the augmentation
    if (self.offTargetTrackingEnabled)
    {
        glDrawArrays(GL_TRIANGLES, 0, (int)buildingModel.numVertices);
    }
    else
    {
        glDrawElements(GL_TRIANGLES, NUM_TEAPOT_OBJECT_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)teapotIndices);
    }
    
    // Disable the enabled arrays
    glDisableVertexAttribArray(vertexHandle);
    glDisableVertexAttribArray(normalHandle);
    glDisableVertexAttribArray(textureCoordHandle);
}

- (void) configureVideoBackgroundWithCameraMode:(Vuforia::CameraDevice::MODE)cameraMode viewWidth:(float)viewWidth viewHeight:(float)viewHeight
{
    [sampleAppRenderer configureVideoBackgroundWithCameraMode:[vapp getCameraMode]
                                                    viewWidth:viewWidth
                                                   viewHeight:viewHeight];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void) initShaders
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"Simple.fragsh"];

    if (0 < shaderProgramID)
    {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else
    {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context)
    {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer)
        {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer)
        {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer)
        {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext])
    {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer)
    {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
