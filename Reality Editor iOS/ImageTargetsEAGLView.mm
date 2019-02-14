/*===============================================================================
Copyright (c) 2016-2018 PTC Inc. All Rights Reserved.

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


//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the Vuforia camera, which causes Vuforia to locate our EAGLView and start
//    the render thread.
// 3) Vuforia calls our renderFrameVuforia method periodically on the render thread.
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
    
    // Model scale factor
    const float kObjectScaleNormal = 0.003f;
    const float kObjectScaleOffTargetTracking = 0.012f;
    
    const float kObjectTranslateOffTargetTracking = -0.06f;
}


@interface ImageTargetsEAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end


@implementation ImageTargetsEAGLView {
    Vuforia::Matrix44F teapotModelViewMatrix;
}

@synthesize vapp = vapp;

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:[UIScreen mainScreen].nativeScale];
        }

        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }

        offTargetTrackingEnabled = NO;
        sampleAppRenderer = [[SampleAppRenderer alloc]initWithSampleAppRendererControl:self nearPlane:0.01 farPlane:5];
        
        [self initShaders];
        
        // we initialize the rendering method of the SampleAppRenderer
        [sampleAppRenderer initRendering];
    }
    
    return self;
}


- (CGSize)getCurrentARViewBoundsSize
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGSize viewSize = screenBounds.size;
    
    viewSize.width *= [UIScreen mainScreen].nativeScale;
    viewSize.height *= [UIScreen mainScreen].nativeScale;
    return viewSize;
}


- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

- (void) setOffTargetTrackingMode:(BOOL) enabled {
    offTargetTrackingEnabled = enabled;
}

//- (void) loadBuildingsModel {
//    buildingModel = [[SampleApplication3DModel alloc] initWithTxtResourceName:@"buildings"];
//    [buildingModel read];
//}


- (void) updateRenderingPrimitives
{
    [sampleAppRenderer updateRenderingPrimitives];
}


//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by Vuforia when it wishes to render the current frame to
// the screen.
//
// *** Vuforia will call this method periodically on a background thread ***
- (void)renderFrameVuforia
{
    if (! vapp.cameraIsStarted) {
        return;
    }
    
    [sampleAppRenderer renderFrameVuforia];
}

- (void) renderFrameWithState:(const Vuforia::State&) state projectMatrix:(Vuforia::Matrix44F&) projectionMatrix {
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    [sampleAppRenderer renderVideoBackgroundWithState:state];
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.
    if (offTargetTrackingEnabled) {
        glDisable(GL_CULL_FACE);
    } else {
        glEnable(GL_CULL_FACE);
    }
    glCullFace(GL_BACK);
    
    // Set the device pose matrix to identity
    Vuforia::Matrix44F devicePoseMatrix = SampleApplicationUtils::Matrix44FIdentity();
    Vuforia::Matrix44F modelMatrix = SampleApplicationUtils::Matrix44FIdentity();
    
    // Get the device pose
    if (state.getDeviceTrackableResult() != nullptr
        && state.getDeviceTrackableResult()->getStatus() != Vuforia::TrackableResult::NO_POSE)
    {
        modelMatrix = Vuforia::Tool::convertPose2GLMatrix(
               state.getDeviceTrackableResult()->getPose());
//        NSLog(@"%f, %f, %f, %f", modelMatrix.data[12], modelMatrix.data[13], modelMatrix.data[14], modelMatrix.data[15]);
        devicePoseMatrix = SampleApplicationUtils::Matrix44FTranspose(
               SampleApplicationUtils::Matrix44FInverse(modelMatrix));
    }
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i)
    {
        // Get the trackable
        const Vuforia::TrackableResult* result = state.getTrackableResult(i);
        
        if (!result->isOfType(Vuforia::ImageTargetResult::getClassType()))
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

- (Vuforia::Matrix44F)getModelViewProjectionForImageTrackable:(const Vuforia::TrackableResult*)imageTrackableResult deviceTrackable:(const Vuforia::TrackableResult*)deviceTrackableResult andProjection:(Vuforia::Matrix44F&) projectionMatrix
{
    if (!imageTrackableResult->isOfType(Vuforia::ImageTargetResult::getClassType())) { return SampleApplicationUtils::Matrix44FIdentity(); }
    
    // Set the device pose matrix to identity
    Vuforia::Matrix44F devicePoseMatrix = SampleApplicationUtils::Matrix44FIdentity();
    Vuforia::Matrix44F deviceModelMatrix = SampleApplicationUtils::Matrix44FIdentity();
    Vuforia::Matrix44F temp = SampleApplicationUtils::Matrix44FIdentity();

    float a;
    float b;
    float c;
    
    // Get the device pose
    if (deviceTrackableResult != nullptr
        && deviceTrackableResult->getStatus() != Vuforia::TrackableResult::NO_POSE)
    {
        deviceModelMatrix = Vuforia::Tool::convertPose2GLMatrix(deviceTrackableResult->getPose());
        //        NSLog(@"%f, %f, %f, %f", modelMatrix.data[12], modelMatrix.data[13], modelMatrix.data[14], modelMatrix.data[15]);
        devicePoseMatrix = SampleApplicationUtils::Matrix44FTranspose(SampleApplicationUtils::Matrix44FInverse(deviceModelMatrix));
        
        NSLog(@"deviceModelMatrix: %@", [self stringFromMatrix44F:deviceModelMatrix]);
        NSLog(@"devicePoseMatrix0: %@", [self stringFromMatrix44F:devicePoseMatrix]);
        
        
//        devicePoseMatrix = SampleApplicationUtils::Matrix44FInverse(deviceModelMatrix);
//        devicePoseMatrix = SampleApplicationUtils::copyMatrix(devicePoseMatrix); //SampleApplicationUtils::Matrix44FInverse(deviceModelMatrix);
        
//        SampleApplicationUtils::convertPoseBetweenWorldAndCamera(SampleApplicationUtils::Matrix44FTranspose(deviceModelMatrix), devicePoseMatrix);
        
        // TODO: go back to the next line maybe
//        devicePoseMatrix = SampleApplicationUtils::copyMatrix(deviceModelMatrix); //SampleApplicationUtils::Matrix44FInverse(deviceModelMatrix);
//        SampleApplicationUtils::convertPoseBetweenWorldAndCamera(deviceModelMatrix, devicePoseMatrix);
        
        // transpose the first 3x3 of the matrix
//        float temp1 = devicePoseMatrix.data[1];
        float new1 = devicePoseMatrix.data[4];
        
//        float temp3 = devicePoseMatrix.data[2];
        float new2 = devicePoseMatrix.data[8];
        
//        float temp5 = devicePoseMatrix.data[6];
        float new6 = devicePoseMatrix.data[9];
        
        devicePoseMatrix.data[4] = devicePoseMatrix.data[1];
        devicePoseMatrix.data[1] = new1;
        devicePoseMatrix.data[8] = devicePoseMatrix.data[2];
        devicePoseMatrix.data[2] = new2;
        devicePoseMatrix.data[9] = devicePoseMatrix.data[6];
        devicePoseMatrix.data[6] = new6;
        
//        devicePoseMatrix;
        
//        float roll, pitch, yaw;
//        yaw = arctan();
        
        // either x-roll
//        devicePoseMatrix.data[6] *= -1;
//        devicePoseMatrix.data[9] *= -1;
        // or y-roll
//        devicePoseMatrix.data[2] *= -1;
//        devicePoseMatrix.data[7] *= -1;
        
        
////        // or z-roll
//        devicePoseMatrix.data[1] *= -1;
//        devicePoseMatrix.data[4] *= -1;
//
//        devicePoseMatrix.data[14] *= -1;
        
        
//                Vuforia::Matrix44F tmp;
//                SampleApplicationUtils::multiplyMatrix(convertCS, devicePoseMatrix, tmp);
//
//                for (int i = 0; i < 16; i++)
//                    devicePoseMatrix.data[i] = deviceModelMatrix.data[i];
        
//        SampleApplicationUtils::rotatePoseMatrix(180, 0, 0, 1, devicePoseMatrix);
        
//        devicePoseMatrix.data[5] *= -1;
//        devicePoseMatrix.data[6] *= -1;
//        devicePoseMatrix.data[9] *= -1;
//        devicePoseMatrix.data[10] *= -1;
        
//        devicePoseMatrix.data[0] *= -1;
//        devicePoseMatrix.data[1] *= -1;
//        devicePoseMatrix.data[4] *= -1;
//        devicePoseMatrix.data[5] *= -1;

        
//        devicePoseMatrix.data[14] *= -1;
        
//        devicePoseMatrix = SampleApplicationUtils::Matrix44FTranspose(devicePoseMatrix);

//        devicePoseMatrix.data[0] *= -1;
//        devicePoseMatrix.data[1] *= -1;
//        devicePoseMatrix.data[2] *= -1;
//
//        devicePoseMatrix.data[8] *= -1;
//        devicePoseMatrix.data[9] *= -1;
//        devicePoseMatrix.data[10] *= -1;
        
//        devicePoseMatrix.data[3] *= -1;
//        devicePoseMatrix.data[7] *= -1;
//        devicePoseMatrix.data[11] *= -1;
        
//        devicePoseMatrix.data[12] *= -1;
//        devicePoseMatrix.data[13] *= -1;
//        devicePoseMatrix.data[14] *= -1;
        
        devicePoseMatrix.data[2] *= -1;
        devicePoseMatrix.data[6] *= -1;
        devicePoseMatrix.data[10] *= -1;
        
//        devicePoseMatrix.data[14] *= -1;
        
//        SampleApplicationUtils::rotatePoseMatrix(180, 0, 0, 1, devicePoseMatrix);
        
//        devicePoseMatrix.data[8] *= -1;
//        devicePoseMatrix.data[9] *= -1;
//        devicePoseMatrix.data[10] *= -1;
//        devicePoseMatrix.data[14] *= -1;

//        devicePoseMatrix.data[4] *= -1;
//        devicePoseMatrix.data[5] *= -1;
//        devicePoseMatrix.data[6] *= -1;
        
        devicePoseMatrix.data[1] *= -1;
        devicePoseMatrix.data[5] *= -1;
        devicePoseMatrix.data[9] *= -1;
        devicePoseMatrix.data[13] *= -1;

//        SampleApplicationUtils::rotatePoseMatrix(180, 1, 0, 0, devicePoseMatrix);
//        SampleApplicationUtils::rotatePoseMatrix(180, 0, 1, 0, devicePoseMatrix);
//        SampleApplicationUtils::rotatePoseMatrix(180, 0, 0, 1, devicePoseMatrix);
        
//        Vuforia::Matrix44F convertCS;
//        SampleApplicationUtils::makeRotationMatrix(180.0f, Vuforia::Vec3F(0.0f, 1.0f, 0.0f), convertCS);
//
//        Vuforia::Matrix44F tmp;
//        SampleApplicationUtils::multiplyMatrix(convertCS, devicePoseMatrix, tmp);
//
//        for (int i = 0; i < 16; i++)
//            devicePoseMatrix.data[i] = tmp.data[i];
        
        // swap rows
        
//        int a1 = 0;
//        int a2 = 4;
//        int a3 = 8;
//
//        int b1 = 2;
//        int b2 = 6;
//        int b3 = 10;
//
//        a = devicePoseMatrix.data[a1];
//        b = devicePoseMatrix.data[a2];
//        c = devicePoseMatrix.data[a3];
//
//        devicePoseMatrix.data[a1] = devicePoseMatrix.data[b1];
//        devicePoseMatrix.data[a2] = devicePoseMatrix.data[b2];
//        devicePoseMatrix.data[a3] = devicePoseMatrix.data[b3];
//
//        devicePoseMatrix.data[b1] = a;
//        devicePoseMatrix.data[b2] = b;
//        devicePoseMatrix.data[b3] = c;
        
        
//
//        devicePoseMatrix.data[4] *= -1;
//        devicePoseMatrix.data[5] *= -1;
//        devicePoseMatrix.data[6] *= -1;
        
    }
    
//    return teapotModelViewMatrix;
    
//    Vuforia::Matrix44F imageModelMatrixTemp = Vuforia::Tool::convertPose2GLMatrix(imageTrackableResult->getPose());
    Vuforia::Matrix44F imageModelMatrix = Vuforia::Tool::convertPose2GLMatrix(imageTrackableResult->getPose());

//    SampleApplicationUtils::convertPoseBetweenWorldAndCamera(imageModelMatrixTemp, imageModelMatrix);
    
//    imageModelMatrix.data[3] *= -1;
//    imageModelMatrix.data[7] *= -1;
//    imageModelMatrix.data[11] *= -1;
    
//    imageModelMatrix.data[0] *= -1;
//    imageModelMatrix.data[1] *= -1;
//    imageModelMatrix.data[2] *= -1;

//    SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, kObjectScaleNormal, imageModelMatrix);
//    SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormal, kObjectScaleNormal, kObjectScaleNormal, imageModelMatrix);

//    NSLog(@"model: %@", [self stringFromMatrix44F:imageModelMatrix]);
    
    // Combine device pose (view matrix) with model matrix
    SampleApplicationUtils::multiplyMatrix(&devicePoseMatrix.data[0], &imageModelMatrix.data[0], &imageModelMatrix.data[0]);
    
//    NSLog(@"view: %@", [self stringFromMatrix44F:devicePoseMatrix]);
    [self prettyPrintMatrix:imageModelMatrix];
//    SampleApplicationUtils::printMatrix(&devicePoseMatrix.data[0]);
    
//    NSLog(@"\n\n editor: ");
//    SampleApplicationUtils::printMatrix(&imageModelMatrix.data[0]);
//    NSLog(@"\n teapot: ");
//    SampleApplicationUtils::printMatrix(&teapotModelViewMatrix.data[0]);

//    NSLog(@"mv: %@", [self stringFromMatrix44F:imageModelMatrix]);

    Vuforia::Matrix44F modelViewProjection;
    // Do the final combination with the projection matrix
    SampleApplicationUtils::multiplyMatrix(&projectionMatrix.data[0], &imageModelMatrix.data[0], &modelViewProjection.data[0]);
    
    return modelViewProjection;
}

- (void)prettyPrintMatrix:(Vuforia::Matrix44F)vuforiaMatrix
{
//    vuforiaMatrix = SampleApplicationUtils::Matrix44FTranspose(vuforiaMatrix);
    
    NSLog(@"%@", [NSString stringWithFormat:@"[\n%.3f,%.3f,%.3f,%.3f,\n%.3f,%.3f,%.3f,%.3f,\n%.3f,%.3f,%.3f,%.3f,\n%.3f,%.3f,%.3f,%.3f\n]",
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
                  ]);
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


- (void) renderModelWithProjection: (float*) projectionMatrix withViewMatrix: (float*) viewMatrix withModelMatrix: (float*) modelMatrix andTextureIndex: (int) textureIndex
{
    // OpenGL 2
    Vuforia::Matrix44F modelViewProjection;

    // Apply local transformation to our model
    if (offTargetTrackingEnabled)
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
    
    //teapotModelViewMatrix = modelMatrix;
    
//    SampleApplicationUtils::convertPoseBetweenWorldAndCamera(modelMatrix, teapotModelViewMatrix);
    
//    teapotModelViewMatrix
//    Vuforia::Matrix44F r;
    for (int i = 0; i < 16; i++)
        teapotModelViewMatrix.data[i] = modelMatrix[i];

    // Do the final combination with the projection matrix
    SampleApplicationUtils::multiplyMatrix(projectionMatrix, modelMatrix, &modelViewProjection.data[0]);
    
//    NSLog(@"\n");
//    SampleApplicationUtils::printMatrix(modelMatrix);
//    NSLog(@"\n");

    // Activate the shader program and bind the vertex/normal/tex coords
    glUseProgram(shaderProgramID);

    if (offTargetTrackingEnabled)
    {
//        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.vertices);
//        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.normals);
//        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)buildingModel.texCoords);
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

    // Pass the model view matrix to the shader
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
    glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);

    // Draw the augmentation
    if (offTargetTrackingEnabled)
    {
//        glDrawArrays(GL_TRIANGLES, 0, (int)buildingModel.numVertices);
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

- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    [sampleAppRenderer configureVideoBackgroundWithViewWidth:viewWidth andHeight:viewHeight];
}

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)initShaders
{
    shaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"Simple.vertsh"
                                                   fragmentShaderFileName:@"Simple.fragsh"];

    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
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
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
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
