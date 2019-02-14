/*===============================================================================
 Copyright (c) 2016-2018 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import <Foundation/Foundation.h>
#import <Vuforia/Matrices.h>


@interface Modelv3d : NSObject

@property (nonatomic, readonly) uint nbVertices;
@property (nonatomic, readonly) uint nbGroups;

@property (nonatomic, readonly) float* vertices;
@property (nonatomic, readonly) float* normals;
@property (nonatomic, readonly) float* texCoords;
@property (nonatomic, readonly) float* materialIndices;
/* materials/groups information */
@property (nonatomic, readonly) float* groupAmbientColors;
@property (nonatomic, readonly) float* groupDiffuseColors;
@property (nonatomic, readonly) float* groupSpecularColors;
@property (nonatomic, readonly) int* groupDiffuseTextureIndexes;
@property (nonatomic, readonly) int* groupVertexRange;

@property (nonatomic, readonly) bool isLoaded;

/* debug methods */
@property (nonatomic, readonly) NSInteger sizeArrayVertices;
@property (nonatomic, readonly) NSInteger sizeArrayNormals;
@property (nonatomic, readonly) NSInteger sizeMaterialIndices;


//- (id)initWithTxtResourceName:(NSString *) name;
//
//-( void) read;

- (bool) loadModel: (NSString *) filename;
- (bool) renderWithModelView:(float[]) modelViewMatrix modelViewProjMatrix:(float[]) modelViewProjMatrix;
- (bool) initShaders;
- (void) unloadModel;
- (void) setLightingColor:(float[]) lightColor;
//Transparency will be disabled if set to 1.0f
- (void) setTransparency:(float) transparencyValue;

@end


