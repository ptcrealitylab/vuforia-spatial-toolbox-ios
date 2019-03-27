/*===============================================================================
 Copyright (c) 2016-2018 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Vuforia/Device.h>
#import <Vuforia/State.h>

@protocol SampleAppRendererControl
// This method has to be implemented by the Renderer class which handles the content rendering
// of the sample, this one is called from SampleAppRendering class for each view inside a loop
- (void) renderFrameWithState:(const Vuforia::State&) state projectMatrix:(Vuforia::Matrix44F&) projectionMatrix;

@end

@interface SampleAppRenderer : NSObject
// Encapsulates the rendering primitives usage

//Initializes the instance with a SampleAppRendererControl so we can call it to render a frame for the current view, the
//device mode is also provided for AR/VR, the stereo setting and near/far planes for the projection matrix
- (id)initWithSampleAppRendererControl:(id<SampleAppRendererControl>)control nearPlane:(float)nearPlane farPlane:(float)farPlane;

//Initializes the shaders to render the video background using the texture provided by the sdk
- (void) initRendering;

//Set near and far planes for the projection matrix to be used to render the augmentations
- (void) setNearPlane:(CGFloat) near farPlane:(CGFloat) far;

//Encapsulates the rendering primitives usage going through the available views and calling renderFrameWithState from SampleAppRendererControl
- (void) renderFrameVuforia;

//Renders the video background using the texture provided by the sdk
- (void) renderVideoBackgroundWithState:(const Vuforia::State&)state;

//Configure the video backgound size
- (void) configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight;

//Updates the rendering primitives to be called when there is a change of screen size or orientation
- (void) updateRenderingPrimitives;

@end
