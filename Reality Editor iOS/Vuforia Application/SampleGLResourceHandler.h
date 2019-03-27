/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

@protocol SampleGLResourceHandler

@required
- (void) freeOpenGLESResources;
- (void) finishOpenGLESCommands;

@end