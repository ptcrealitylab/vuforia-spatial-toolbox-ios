/*===============================================================================
 Copyright (c) 2015-2018 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#include <math.h>
#include <stdio.h>
#include <string.h>
#include "SampleApplicationUtils.h"
#include <stdlib.h>


namespace SampleApplicationUtils
{
    // Print a 4x4 matrix
    void
    printMatrix(const float* mat)
    {
        for (int r = 0; r < 4; r++, mat += 4) {
            printf("%7.3f %7.3f %7.3f %7.3f", mat[0], mat[1], mat[2], mat[3]);
        }
    }
    
    
    // Print GL error information
    void
    checkGlError(const char* operation)
    { 
        for (GLint error = glGetError(); error; error = glGetError()) {
            printf("after %s() glError (0x%x)\n", operation, error);
        }
    }
    
    
    // Set identity 4x4 matrix
    void
    setIdentityMatrix(float *matrix)
    {
        for(int i = 0; i < 4; i++) {
            for(int j = 0; j < 4; j++) {
                if(i == j)
                    matrix[i*4 + j] = 1.0;
                else
                    matrix[i*4 + j] = 0;
            }
        }
        
    }
    
    
    Vuforia::Matrix44F
    Matrix44FIdentity()
    {
        Vuforia::Matrix44F r;
        
        for (int i = 0; i < 16; i++)
            r.data[i] = 0.0f;
        
        r.data[0] = 1.0f;
        r.data[5] = 1.0f;
        r.data[10] = 1.0f;
        r.data[15] = 1.0f;
        
        return r;
    }
    
    Vuforia::Matrix34F
    Matrix34FIdentity()
    {
        Vuforia::Matrix34F r;
        
        for (int i = 0; i < 12; i++)
            r.data[i] = 0.0f;
        
        r.data[0] = 1.0f;
        r.data[5] = 1.0f;
        r.data[10] = 1.0f;
        
        return r;
    }
    
    
    Vuforia::Matrix44F copyMatrix(const Vuforia::Matrix44F& m)
    {
        return m;
    }
    

    Vuforia::Matrix34F copyMatrix(const Vuforia::Matrix34F& m)
    {
        return m;
    }
    
    
    void
    makeRotationMatrix(float angle, const Vuforia::Vec3F& axis, Vuforia::Matrix44F& m)
    {
        double radians, c, s, c1, u[3], length;
        int i, j;
        
        m = Matrix44FIdentity();
        
        radians = (angle * M_PI) / 180.0;
        
        c = cos(radians);
        s = sin(radians);
        
        c1 = 1.0 - cos(radians);
        
        length = sqrt(axis.data[0] * axis.data[0] + axis.data[1] * axis.data[1] + axis.data[2] * axis.data[2]);
        
        u[0] = axis.data[0] / length;
        u[1] = axis.data[1] / length;
        u[2] = axis.data[2] / length;
        
        for (i = 0; i < 16; i++)
            m.data[i] = 0.0;
        
        m.data[15] = 1.0;
        
        for (i = 0; i < 3; i++)
        {
            m.data[i * 4 + (i + 1) % 3] = (float)(u[(i + 2) % 3] * s);
            m.data[i * 4 + (i + 2) % 3] = (float)(-u[(i + 1) % 3] * s);
        }
        
        for (i = 0; i < 3; i++)
        {
            for (j = 0; j < 3; j++)
                m.data[i * 4 + j] += (float)(c1 * u[i] * u[j] + (i == j ? c : 0.0));
        }
    }
    
    
    void
    makeTranslationMatrix(const Vuforia::Vec3F& trans, Vuforia::Matrix44F& m)
    {
        m = Matrix44FIdentity();
        
        m.data[12] = trans.data[0];
        m.data[13] = trans.data[1];
        m.data[14] = trans.data[2];
    }
    
    
    void
    makeScalingMatrix(const Vuforia::Vec3F& scale, Vuforia::Matrix44F& m)
    {
        m = Matrix44FIdentity();
        
        m.data[0] = scale.data[0];
        m.data[5] = scale.data[1];
        m.data[10] = scale.data[2];
    }
    

    // Set the rotation components of a 4x4 matrix
    void
    setRotationMatrix(float angle, float x, float y, float z, 
                                   float *matrix)
    {
        double radians, c, s, c1, u[3], length;
        int i, j;
        
        radians = (angle * M_PI) / 180.0;
        
        c = cos(radians);
        s = sin(radians);
        
        c1 = 1.0 - cos(radians);
        
        length = sqrt(x * x + y * y + z * z);
        
        u[0] = x / length;
        u[1] = y / length;
        u[2] = z / length;
        
        for (i = 0; i < 16; i++) {
            matrix[i] = 0.0;
        }
        
        matrix[15] = 1.0;
        
        for (i = 0; i < 3; i++) {
            matrix[i * 4 + (i + 1) % 3] = u[(i + 2) % 3] * s;
            matrix[i * 4 + (i + 2) % 3] = -u[(i + 1) % 3] * s;
        }
        
        for (i = 0; i < 3; i++) {
            for (j = 0; j < 3; j++) {
                matrix[i * 4 + j] += c1 * u[i] * u[j] + (i == j ? c : 0.0);
            }
        }
    }
    
    
    // Set the translation components of a 4x4 matrix
    void
    translatePoseMatrix(float x, float y, float z, float* matrix)
    {
        if (matrix) {
            // matrix * translate_matrix
            matrix[12] += (matrix[0] * x + matrix[4] * y + matrix[8]  * z);
            matrix[13] += (matrix[1] * x + matrix[5] * y + matrix[9]  * z);
            matrix[14] += (matrix[2] * x + matrix[6] * y + matrix[10] * z);
            matrix[15] += (matrix[3] * x + matrix[7] * y + matrix[11] * z);
        }
    }
    

    void
    translatePoseMatrix(float x, float y, float z, Vuforia::Matrix44F& m)
    {
        // m = m * translate_m
        m.data[12] +=
        (m.data[0] * x + m.data[4] * y + m.data[8] * z);
        
        m.data[13] +=
        (m.data[1] * x + m.data[5] * y + m.data[9] * z);
        
        m.data[14] +=
        (m.data[2] * x + m.data[6] * y + m.data[10] * z);
        
        m.data[15] +=
        (m.data[3] * x + m.data[7] * y + m.data[11] * z);
    }
    

    // Apply a rotation
    void
    rotatePoseMatrix(float angle, float x, float y, float z,
                                  float* matrix)
    {
        if (matrix) {
            float rotate_matrix[16];
            setRotationMatrix(angle, x, y, z, rotate_matrix);
            
            // matrix * scale_matrix
            multiplyMatrix(matrix, rotate_matrix, matrix);
        }
    }
    
    
    void
    rotatePoseMatrix(float angle, float x, float y, float z, Vuforia::Matrix44F& m)
    {
        Vuforia::Matrix44F rotationMatrix;
        
        // create a rotation matrix
        makeRotationMatrix(angle, Vuforia::Vec3F(x,y,z), rotationMatrix);
        
        multiplyMatrix(m, rotationMatrix, m);
    }

    
    // Apply a scaling transformation
    void
    scalePoseMatrix(float x, float y, float z, float* matrix)
    {
        if (matrix) {
            // matrix * scale_matrix
            matrix[0]  *= x;
            matrix[1]  *= x;
            matrix[2]  *= x;
            matrix[3]  *= x;
            
            matrix[4]  *= y;
            matrix[5]  *= y;
            matrix[6]  *= y;
            matrix[7]  *= y;
            
            matrix[8]  *= z;
            matrix[9]  *= z;
            matrix[10] *= z;
            matrix[11] *= z;
        }
    }
    
    void
    scalePoseMatrix(float x, float y, float z, Vuforia::Matrix44F& matrix)
    {
        // matrix * scale_matrix
        matrix.data[0]  *= x;
        matrix.data[1]  *= x;
        matrix.data[2]  *= x;
        matrix.data[3]  *= x;
            
        matrix.data[4]  *= y;
        matrix.data[5]  *= y;
        matrix.data[6]  *= y;
        matrix.data[7]  *= y;
            
        matrix.data[8]  *= z;
        matrix.data[9]  *= z;
        matrix.data[10] *= z;
        matrix.data[11] *= z;
    }
    

    // Multiply the two matrices A and B and write the result to C
    void
    multiplyMatrix(float *matrixA, float *matrixB, float *matrixC)
    {
        int i, j, k;
        float aTmp[16];
        
        for (i = 0; i < 4; i++) {
            for (j = 0; j < 4; j++) {
                aTmp[j * 4 + i] = 0.0;
                
                for (k = 0; k < 4; k++) {
                    aTmp[j * 4 + i] += matrixA[k * 4 + i] * matrixB[j * 4 + k];
                }
            }
        }
        
        for (i = 0; i < 16; i++) {
            matrixC[i] = aTmp[i];
        }
    }

    
    void
    multiplyMatrix(const Vuforia::Matrix44F& matrixA, const Vuforia::Matrix44F& matrixB, Vuforia::Matrix44F& matrixC)
    {
        int i, j, k;
        Vuforia::Matrix44F aTmp;
        
        // matrixC= matrixA * matrixB
        for (i = 0; i < 4; i++)
        {
            for (j = 0; j < 4; j++)
            {
                aTmp.data[j * 4 + i] = 0.0;
                
                for (k = 0; k < 4; k++)
                    aTmp.data[j * 4 + i] += matrixA.data[k * 4 + i] * matrixB.data[j * 4 + k];
            }
        }
        
        for (i = 0; i < 16; i++)
            matrixC.data[i] = aTmp.data[i];
    }
    
    
    Vuforia::Matrix44F
    Matrix44FTranspose(const Vuforia::Matrix44F& m)
    {
        Vuforia::Matrix44F r;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                r.data[i*4+j] = m.data[i+4*j];
        return r;
    }
    
    
    float
    Matrix44FDeterminate(const Vuforia::Matrix44F& m)
    {
        return  m.data[12] * m.data[9] * m.data[6] * m.data[3] - m.data[8] * m.data[13] * m.data[6] * m.data[3] -
        m.data[12] * m.data[5] * m.data[10] * m.data[3] + m.data[4] * m.data[13] * m.data[10] * m.data[3] +
        m.data[8] * m.data[5] * m.data[14] * m.data[3] - m.data[4] * m.data[9] * m.data[14] * m.data[3] -
        m.data[12] * m.data[9] * m.data[2] * m.data[7] + m.data[8] * m.data[13] * m.data[2] * m.data[7] +
        m.data[12] * m.data[1] * m.data[10] * m.data[7] - m.data[0] * m.data[13] * m.data[10] * m.data[7] -
        m.data[8] * m.data[1] * m.data[14] * m.data[7] + m.data[0] * m.data[9] * m.data[14] * m.data[7] +
        m.data[12] * m.data[5] * m.data[2] * m.data[11] - m.data[4] * m.data[13] * m.data[2] * m.data[11] -
        m.data[12] * m.data[1] * m.data[6] * m.data[11] + m.data[0] * m.data[13] * m.data[6] * m.data[11] +
        m.data[4] * m.data[1] * m.data[14] * m.data[11] - m.data[0] * m.data[5] * m.data[14] * m.data[11] -
        m.data[8] * m.data[5] * m.data[2] * m.data[15] + m.data[4] * m.data[9] * m.data[2] * m.data[15] +
        m.data[8] * m.data[1] * m.data[6] * m.data[15] - m.data[0] * m.data[9] * m.data[6] * m.data[15] -
        m.data[4] * m.data[1] * m.data[10] * m.data[15] + m.data[0] * m.data[5] * m.data[10] * m.data[15] ;
    }
    
    
    Vuforia::Matrix44F
    Matrix44FInverse(const Vuforia::Matrix44F& m)
    {
        Vuforia::Matrix44F r;
        
        float det = 1.0f / Matrix44FDeterminate(m);
        
        r.data[0]   = m.data[6]*m.data[11]*m.data[13] - m.data[7]*m.data[10]*m.data[13]
        + m.data[7]*m.data[9]*m.data[14] - m.data[5]*m.data[11]*m.data[14]
        - m.data[6]*m.data[9]*m.data[15] + m.data[5]*m.data[10]*m.data[15];
        
        r.data[4]   = m.data[3]*m.data[10]*m.data[13] - m.data[2]*m.data[11]*m.data[13]
        - m.data[3]*m.data[9]*m.data[14] + m.data[1]*m.data[11]*m.data[14]
        + m.data[2]*m.data[9]*m.data[15] - m.data[1]*m.data[10]*m.data[15];
        
        r.data[8]   = m.data[2]*m.data[7]*m.data[13] - m.data[3]*m.data[6]*m.data[13]
        + m.data[3]*m.data[5]*m.data[14] - m.data[1]*m.data[7]*m.data[14]
        - m.data[2]*m.data[5]*m.data[15] + m.data[1]*m.data[6]*m.data[15];
        
        r.data[12]  = m.data[3]*m.data[6]*m.data[9] - m.data[2]*m.data[7]*m.data[9]
        - m.data[3]*m.data[5]*m.data[10] + m.data[1]*m.data[7]*m.data[10]
        + m.data[2]*m.data[5]*m.data[11] - m.data[1]*m.data[6]*m.data[11];
        
        r.data[1]   = m.data[7]*m.data[10]*m.data[12] - m.data[6]*m.data[11]*m.data[12]
        - m.data[7]*m.data[8]*m.data[14] + m.data[4]*m.data[11]*m.data[14]
        + m.data[6]*m.data[8]*m.data[15] - m.data[4]*m.data[10]*m.data[15];
        
        r.data[5]   = m.data[2]*m.data[11]*m.data[12] - m.data[3]*m.data[10]*m.data[12]
        + m.data[3]*m.data[8]*m.data[14] - m.data[0]*m.data[11]*m.data[14]
        - m.data[2]*m.data[8]*m.data[15] + m.data[0]*m.data[10]*m.data[15];
        
        r.data[9]   = m.data[3]*m.data[6]*m.data[12] - m.data[2]*m.data[7]*m.data[12]
        - m.data[3]*m.data[4]*m.data[14] + m.data[0]*m.data[7]*m.data[14]
        + m.data[2]*m.data[4]*m.data[15] - m.data[0]*m.data[6]*m.data[15];
        
        r.data[13]  = m.data[2]*m.data[7]*m.data[8] - m.data[3]*m.data[6]*m.data[8]
        + m.data[3]*m.data[4]*m.data[10] - m.data[0]*m.data[7]*m.data[10]
        - m.data[2]*m.data[4]*m.data[11] + m.data[0]*m.data[6]*m.data[11];
        
        r.data[2]   = m.data[5]*m.data[11]*m.data[12] - m.data[7]*m.data[9]*m.data[12]
        + m.data[7]*m.data[8]*m.data[13] - m.data[4]*m.data[11]*m.data[13]
        - m.data[5]*m.data[8]*m.data[15] + m.data[4]*m.data[9]*m.data[15];
        
        r.data[6]   = m.data[3]*m.data[9]*m.data[12] - m.data[1]*m.data[11]*m.data[12]
        - m.data[3]*m.data[8]*m.data[13] + m.data[0]*m.data[11]*m.data[13]
        + m.data[1]*m.data[8]*m.data[15] - m.data[0]*m.data[9]*m.data[15];
        
        r.data[10]  = m.data[1]*m.data[7]*m.data[12] - m.data[3]*m.data[5]*m.data[12]
        + m.data[3]*m.data[4]*m.data[13] - m.data[0]*m.data[7]*m.data[13]
        - m.data[1]*m.data[4]*m.data[15] + m.data[0]*m.data[5]*m.data[15];
        
        r.data[14]  = m.data[3]*m.data[5]*m.data[8] - m.data[1]*m.data[7]*m.data[8]
        - m.data[3]*m.data[4]*m.data[9] + m.data[0]*m.data[7]*m.data[9]
        + m.data[1]*m.data[4]*m.data[11] - m.data[0]*m.data[5]*m.data[11];
        
        r.data[3]   = m.data[6]*m.data[9]*m.data[12] - m.data[5]*m.data[10]*m.data[12]
        - m.data[6]*m.data[8]*m.data[13] + m.data[4]*m.data[10]*m.data[13]
        + m.data[5]*m.data[8]*m.data[14] - m.data[4]*m.data[9]*m.data[14];
        
        r.data[7]  = m.data[1]*m.data[10]*m.data[12] - m.data[2]*m.data[9]*m.data[12]
        + m.data[2]*m.data[8]*m.data[13] - m.data[0]*m.data[10]*m.data[13]
        - m.data[1]*m.data[8]*m.data[14] + m.data[0]*m.data[9]*m.data[14];
        
        r.data[11]  = m.data[2]*m.data[5]*m.data[12] - m.data[1]*m.data[6]*m.data[12]
        - m.data[2]*m.data[4]*m.data[13] + m.data[0]*m.data[6]*m.data[13]
        + m.data[1]*m.data[4]*m.data[14] - m.data[0]*m.data[5]*m.data[14];
        
        r.data[15]  = m.data[1]*m.data[6]*m.data[8] - m.data[2]*m.data[5]*m.data[8]
        + m.data[2]*m.data[4]*m.data[9] - m.data[0]*m.data[6]*m.data[9]
        - m.data[1]*m.data[4]*m.data[10] + m.data[0]*m.data[5]*m.data[10];
        
        for (int i = 0; i < 16; i++)
            r.data[i] *= det;
        
        return r;
    }
    
    
    void
    convertPoseBetweenWorldAndCamera(const Vuforia::Matrix44F& matrixIn, Vuforia::Matrix44F& matrixOut)
    {
        Vuforia::Matrix44F convertCS;
        makeRotationMatrix(180.0f, Vuforia::Vec3F(1.0f, 0.0f, 0.0f), convertCS);
        
        Vuforia::Matrix44F tmp;
        multiplyMatrix(convertCS, matrixIn, tmp);
        
        for (int i = 0; i < 16; i++)
            matrixOut.data[i] = tmp.data[i];
    }

    
    // Initialise a shader
    int
    initShader(GLenum nShaderType, const char* pszSource, const char* pszDefs)
    {
        GLuint shader = glCreateShader(nShaderType);
        
        if (shader) {
            if(pszDefs == NULL)
            {
                glShaderSource(shader, 1, &pszSource, NULL);
            }
            else
            {   
                const char* finalShader[2] = {pszDefs,pszSource};
                GLint finalShaderSizes[2] = {static_cast<GLint>(strlen(pszDefs)), static_cast<GLint>(strlen(pszSource))};
                glShaderSource(shader, 2, finalShader, finalShaderSizes);
            }
            
            glCompileShader(shader);
            GLint compiled = 0;
            glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
            
            if (!compiled) {
                GLint infoLen = 0;
                glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
                
                if (infoLen) {
                    char* buf = new char[infoLen];
                    glGetShaderInfoLog(shader, infoLen, NULL, buf);
                    printf("Could not compile shader %d: %s\n", shader, buf);
                    delete[] buf;
                }
            }
        }
        
        return shader;
    }
    
    
    // Create a shader program
    int
    createProgramFromBuffer(const char* pszVertexSource,
                            const char* pszFragmentSource,
                            const char* pszVertexShaderDefs,
                            const char* pszFragmentShaderDefs)

    {
        GLuint program = 0;
        GLuint vertexShader = initShader(GL_VERTEX_SHADER, pszVertexSource, pszVertexShaderDefs);
        GLuint fragmentShader = initShader(GL_FRAGMENT_SHADER, pszFragmentSource, pszFragmentShaderDefs);
        
        if (vertexShader && fragmentShader) {
            program = glCreateProgram();
            
            if (program) {
                glAttachShader(program, vertexShader);
                checkGlError("glAttachShader");
                glAttachShader(program, fragmentShader);
                checkGlError("glAttachShader");
                
                glLinkProgram(program);
                GLint linkStatus;
                glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
                
                if (GL_TRUE != linkStatus) {
                    GLint infoLen = 0;
                    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
                    
                    if (infoLen) {
                        char* buf = new char[infoLen];
                        glGetProgramInfoLog(program, infoLen, NULL, buf);
                        printf("Could not link program %d: %s\n", program, buf);
                        delete[] buf;
                    }
                }
            }
        }
        
        return program;
    }
    
    
    void
    setOrthoMatrix(float nLeft, float nRight, float nBottom, float nTop, 
                                float nNear, float nFar, float *nProjMatrix)
    {
        if (!nProjMatrix)
        {
            //         arLogMessage(AR_LOG_LEVEL_ERROR, "PLShadersExample", "Orthographic projection matrix pointer is NULL");
            return;
        }       
        
        for (int i = 0; i < 16; i++)
            nProjMatrix[i] = 0.0f;
        
        nProjMatrix[0] = 2.0f / (nRight - nLeft);
        nProjMatrix[5] = 2.0f / (nTop - nBottom);
        nProjMatrix[10] = 2.0f / (nNear - nFar);
        nProjMatrix[12] = -(nRight + nLeft) / (nRight - nLeft);
        nProjMatrix[13] = -(nTop + nBottom) / (nTop - nBottom);
        nProjMatrix[14] = (nFar + nNear) / (nFar - nNear);
        nProjMatrix[15] = 1.0f;
    }
    
    void
    setOrthoMatrix(float nLeft, float nRight, float nBottom, float nTop, float nNear, float nFar, Vuforia::Matrix44F& nProjMatrix)
    {
        nProjMatrix = Matrix44FIdentity();
        
        nProjMatrix.data[0] = 2.0f / (nRight - nLeft);
        nProjMatrix.data[5] = 2.0f / (nTop - nBottom);
        nProjMatrix.data[10] = 2.0f / (nNear - nFar);
        nProjMatrix.data[12] = -(nRight + nLeft) / (nRight - nLeft);
        nProjMatrix.data[13] = -(nTop + nBottom) / (nTop - nBottom);
        nProjMatrix.data[14] = (nFar + nNear) / (nFar - nNear);
        nProjMatrix.data[15] = 1.0f;
    }
    
    // Transforms a screen pixel to a pixel onto the camera image,
    // taking into account e.g. cropping of camera image to fit different aspect ratio screen.
    // for the camera dimensions, the width is always bigger than the height (always landscape orientation)
    // Top left of screen/camera is origin
    void
    screenCoordToCameraCoord(int screenX, int screenY, int screenDX, int screenDY,
                             int screenWidth, int screenHeight, int cameraWidth, int cameraHeight,
                             int * cameraX, int* cameraY, int * cameraDX, int * cameraDY)
    {
        
        printf("screenCoordToCameraCoord:%d,%d %d,%d, %d,%d, %d,%d",screenX, screenY, screenDX, screenDY,
              screenWidth, screenHeight, cameraWidth, cameraHeight );

        
        bool isPortraitMode = (screenWidth < screenHeight);
        float videoWidth, videoHeight;
        videoWidth = (float)cameraWidth;
        videoHeight = (float)cameraHeight;
        if (isPortraitMode)
        {
            // the width and height of the camera are always
            // based on a landscape orientation
            // videoWidth = (float)cameraHeight;
            // videoHeight = (float)cameraWidth;
            
            
            // as the camera coordinates are always in landscape
            // we convert the inputs into a landscape based coordinate system
            int tmp = screenX;
            screenX = screenY;
            screenY = screenWidth - tmp;
            
            tmp = screenDX;
            screenDX = screenDY;
            screenDY = tmp;
            
            tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
            
        }
        else
        {
            videoWidth = (float)cameraWidth;
            videoHeight = (float)cameraHeight;
        }
        
        float videoAspectRatio = videoHeight / videoWidth;
        float screenAspectRatio = (float) screenHeight / (float) screenWidth;
        
        float scaledUpX;
        float scaledUpY;
        float scaledUpVideoWidth;
        float scaledUpVideoHeight;
        
        if (videoAspectRatio < screenAspectRatio)
        {
            // the video height will fit in the screen height
            scaledUpVideoWidth = (float)screenHeight / videoAspectRatio;
            scaledUpVideoHeight = screenHeight;
            scaledUpX = (float)screenX + ((scaledUpVideoWidth - (float)screenWidth) / 2.0f);
            scaledUpY = (float)screenY;
        }
        else
        {
            // the video width will fit in the screen width
            scaledUpVideoHeight = (float)screenWidth * videoAspectRatio;
            scaledUpVideoWidth = screenWidth;
            scaledUpY = (float)screenY + ((scaledUpVideoHeight - (float)screenHeight)/2.0f);
            scaledUpX = (float)screenX;
        }
        
        if (cameraX)
        {
            *cameraX = (int)((scaledUpX / (float)scaledUpVideoWidth) * videoWidth);
        }
        
        if (cameraY)
        {
            *cameraY = (int)((scaledUpY / (float)scaledUpVideoHeight) * videoHeight);
        }
        
        if (cameraDX)
        {
            *cameraDX = (int)(((float)screenDX / (float)scaledUpVideoWidth) * videoWidth);
        }
        
        if (cameraDY)
        {
            *cameraDY = (int)(((float)screenDY / (float)scaledUpVideoHeight) * videoHeight);
        }
    }
    
    unsigned int
    createTexture(Vuforia::Image * image)
    {
        unsigned int glTextureID = -1;
        
        glGenTextures(1, &glTextureID);
        
        glBindTexture(GL_TEXTURE_2D, glTextureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        auto pixelFormat = image->getFormat();
        
        GLenum format;
        GLenum type;
        switch (pixelFormat)
        {
            case Vuforia::UNKNOWN_FORMAT:
            case Vuforia::YUV:
                return -1;
                
            case Vuforia::RGB565:
                type = GL_UNSIGNED_SHORT_5_6_5;
                format = GL_RGB;
                break;
            case Vuforia::RGB888:
                type = GL_UNSIGNED_BYTE;
                format = GL_RGB;
                break;
                
            case Vuforia::RGBA8888:
                type = GL_UNSIGNED_BYTE;
                format = GL_RGBA;
                break;
                
            case Vuforia::GRAYSCALE:
                type = GL_UNSIGNED_BYTE;
                format = GL_LUMINANCE;
                break;
                
            default:
                return -1;
        }
        
        glTexImage2D(GL_TEXTURE_2D, 0, format , image->getWidth(), image->getHeight(), 0,
                     format, type, image->getPixels());
        glBindTexture(GL_TEXTURE_2D, 0);
        
        return glTextureID;
    }
    
}   // namespace ShaderUtils
