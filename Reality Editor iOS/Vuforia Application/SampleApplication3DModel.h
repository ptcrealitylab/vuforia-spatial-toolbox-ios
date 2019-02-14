/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import <Foundation/Foundation.h>

// this class reads a text file describing a 3d Model

@interface SampleApplication3DModel : NSObject

@property (nonatomic, readonly) NSInteger numVertices;
@property (nonatomic, readonly) float* vertices;
@property (nonatomic, readonly) float* normals;
@property (nonatomic, readonly) float* texCoords;

- (id)initWithTxtResourceName:(NSString *) name;

- (void) read;

@end
