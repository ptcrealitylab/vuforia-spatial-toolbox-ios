/*===============================================================================
 Copyright (c) 2015-2018 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#ifndef __SHADERUTILS_H__
#define __SHADERUTILS_H__


#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Vuforia/Matrices.h>
#import <Vuforia/Image.h>
#import <Vuforia/Vectors.h>


namespace SampleApplicationUtils
{
    // Print a 4x4 matrix
    void printMatrix(const float* matrix);
    
    // Print GL error information
    void checkGlError(const char* operation);
    
    // Set identity matrix
    void setIdentityMatrix(float *matrix);
    
    // Make matrices functions
    Vuforia::Matrix44F Matrix44FIdentity();
    Vuforia::Matrix34F Matrix34FIdentity();
    Vuforia::Matrix44F copyMatrix(const Vuforia::Matrix44F& m);
    Vuforia::Matrix34F copyMatrix(const Vuforia::Matrix34F& m);
    void makeRotationMatrix(float angle, const Vuforia::Vec3F& axis, Vuforia::Matrix44F& m);
    void makeTranslationMatrix(const Vuforia::Vec3F& trans, Vuforia::Matrix44F& m);
    void makeScalingMatrix(const Vuforia::Vec3F& scale, Vuforia::Matrix44F& m);
    
    // Set the rotation components of a 4x4 matrix
    void setRotationMatrix(float angle, float x, float y, float z, 
                           float *nMatrix);
    
    // Set the translation components of a 4x4 matrix
    void translatePoseMatrix(float x, float y, float z,
                             float* nMatrix);
    void translatePoseMatrix(float x, float y, float z, Vuforia::Matrix44F& m);
    
    // Apply a rotation
    void rotatePoseMatrix(float angle, float x, float y, float z, 
                          float* nMatrix);
    void rotatePoseMatrix(float angle, float x, float y, float z, Vuforia::Matrix44F& m);
    
    // Apply a scaling transformation
    void scalePoseMatrix(float x, float y, float z, float* nMatrix);
    void scalePoseMatrix(float x, float y, float z, Vuforia::Matrix44F& m);

    // Multiply the two matrices A and B and write the result to C
    void multiplyMatrix(float *matrixA, float *matrixB, 
                        float *matrixC);
    void multiplyMatrix(const Vuforia::Matrix44F& matrixA, const Vuforia::Matrix44F& matrixB, Vuforia::Matrix44F& matrixC);
    
    // Transpose and inverse functions for 4x4 matrices
    Vuforia::Matrix44F Matrix44FTranspose(const Vuforia::Matrix44F& m);
    float Matrix44FDeterminate(const Vuforia::Matrix44F& m);
    Vuforia::Matrix44F Matrix44FInverse(const Vuforia::Matrix44F& m);
    
    // Transform pose from World Coordinate System to Camera Coordinate System (180 degree rotation between both CS)
    void convertPoseBetweenWorldAndCamera(const Vuforia::Matrix44F& matrixIn, Vuforia::Matrix44F& matrixOut);
    
    // Initialise a shader
    int initShader(GLenum nShaderType, const char* pszSource, const char* pszDefs = NULL);
    
    // Create a shader program
//    int createProgramFromBuffer(const char* pszVertexSource,
//                                const char* pszFragmentSource,
//                                const char* pszVertexShaderDefs = NULL,
//                                const char* pszFragmentShaderDefs = NULL);
    
    void setOrthoMatrix(float nLeft, float nRight, float nBottom, float nTop,
                        float nNear, float nFar, float *nProjMatrix);
    void setOrthoMatrix(float nLeft, float nRight, float nBottom, float nTop,
                        float nNear, float nFar, Vuforia::Matrix44F& nProjMatrix);
    
    void screenCoordToCameraCoord(int screenX, int screenY, int screenDX, int screenDY,
                                  int screenWidth, int screenHeight, int cameraWidth, int cameraHeight,
                                  int * cameraX, int* cameraY, int * cameraDX, int * cameraDY);
    
    // Creates an OpenGL texture handle from a Vuforia Image    
    unsigned int createTexture(Vuforia::Image * image);
}

#endif  // __SHADERUTILS_H__
