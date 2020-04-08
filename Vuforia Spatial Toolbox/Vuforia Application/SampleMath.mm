/*===============================================================================
Copyright (c) 2020 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#include "SampleMath.h"

#include <math.h>
#include <stdlib.h>


Vuforia::Vec2F
SampleMath::Vec2FSub(Vuforia::Vec2F v1, Vuforia::Vec2F v2)
{
    Vuforia::Vec2F r;
    r.data[0] = v1.data[0] - v2.data[0];
    r.data[1] = v1.data[1] - v2.data[1];
    return r;
}


float
SampleMath::Vec2FDist(Vuforia::Vec2F v1, Vuforia::Vec2F v2)
{
    float dx = v1.data[0] - v2.data[0];
    float dy = v1.data[1] - v2.data[1];
    return sqrt(dx * dx + dy * dy);
}


Vuforia::Vec3F
SampleMath::Vec3FAdd(Vuforia::Vec3F v1, Vuforia::Vec3F v2)
{
    Vuforia::Vec3F r;
    r.data[0] = v1.data[0] + v2.data[0];
    r.data[1] = v1.data[1] + v2.data[1];
    r.data[2] = v1.data[2] + v2.data[2];
    return r;
}


Vuforia::Vec3F
SampleMath::Vec3FSub(Vuforia::Vec3F v1, Vuforia::Vec3F v2)
{
    Vuforia::Vec3F r;
    r.data[0] = v1.data[0] - v2.data[0];
    r.data[1] = v1.data[1] - v2.data[1];
    r.data[2] = v1.data[2] - v2.data[2];
    return r;
}


Vuforia::Vec3F
SampleMath::Vec3FScale(Vuforia::Vec3F v, float s)
{
    Vuforia::Vec3F r;
    r.data[0] = v.data[0] * s;
    r.data[1] = v.data[1] * s;
    r.data[2] = v.data[2] * s;
    return r;
}


float
SampleMath::Vec3FDot(Vuforia::Vec3F v1, Vuforia::Vec3F v2)
{
    return v1.data[0] * v2.data[0] + v1.data[1] * v2.data[1] + v1.data[2] * v2.data[2];
}


Vuforia::Vec3F
SampleMath::Vec3FCross(Vuforia::Vec3F v1, Vuforia::Vec3F v2)
{
    Vuforia::Vec3F r;
    r.data[0] = v1.data[1] * v2.data[2] - v1.data[2] * v2.data[1];
    r.data[1] = v1.data[2] * v2.data[0] - v1.data[0] * v2.data[2];
    r.data[2] = v1.data[0] * v2.data[1] - v1.data[1] * v2.data[0];
    return r;
}


Vuforia::Vec3F
SampleMath::Vec3FNormalize(Vuforia::Vec3F v)
{
    Vuforia::Vec3F r;
    
    float length = sqrt(v.data[0] * v.data[0] + v.data[1] * v.data[1] + v.data[2] * v.data[2]);
    if (length != 0.0f)
        length = 1.0f / length;
    
    r.data[0] = v.data[0] * length;
    r.data[1] = v.data[1] * length;
    r.data[2] = v.data[2] * length;
    
    return r;
}


Vuforia::Vec3F
SampleMath::Vec3FTransform(Vuforia::Vec3F& v, Vuforia::Matrix44F& m)
{
    Vuforia::Vec3F r;
    
    float lambda;
    lambda    = m.data[12] * v.data[0] +
                m.data[13] * v.data[1] +
                m.data[14] * v.data[2] +
                m.data[15];
	
    r.data[0] = m.data[0] * v.data[0] +
                m.data[1] * v.data[1] +
                m.data[2] * v.data[2] +
                m.data[3];
    r.data[1] = m.data[4] * v.data[0] +
                m.data[5] * v.data[1] +
                m.data[6] * v.data[2] +
                m.data[7];
    r.data[2] = m.data[8] * v.data[0] +
                m.data[9] * v.data[1] +
                m.data[10] * v.data[2] +
                m.data[11];
    
    r.data[0] /= lambda;
    r.data[1] /= lambda;
    r.data[2] /= lambda;
	
    return r;
}


Vuforia::Vec3F
SampleMath::Vec3FTransformNormal(Vuforia::Vec3F& v, Vuforia::Matrix44F& m)
{
    Vuforia::Vec3F r;
    
    r.data[0] = m.data[0] * v.data[0] +
                m.data[1] * v.data[1] +
                m.data[2] * v.data[2];
    r.data[1] = m.data[4] * v.data[0] +
                m.data[5] * v.data[1] +
                m.data[6] * v.data[2];
    r.data[2] = m.data[8] * v.data[0] +
                m.data[9] * v.data[1] +
                m.data[10] * v.data[2];
    
    return r;
}


Vuforia::Vec4F
SampleMath::Vec4FTransform(Vuforia::Vec4F& v, Vuforia::Matrix44F& m)
{
    Vuforia::Vec4F r;
    
    r.data[0] = m.data[0] * v.data[0] +
                m.data[1] * v.data[1] +
                m.data[2] * v.data[2] +
                m.data[3] * v.data[3];
    r.data[1] = m.data[4] * v.data[0] +
                m.data[5] * v.data[1] +
                m.data[6] * v.data[2] +
                m.data[7] * v.data[3];
    r.data[2] = m.data[8] * v.data[0] +
                m.data[9] * v.data[1] +
                m.data[10] * v.data[2] +
                m.data[11] * v.data[3];
    r.data[3] = m.data[12] * v.data[0] +
                m.data[13] * v.data[1] +
                m.data[14] * v.data[2] +
                m.data[15] * v.data[3];
    
    return r;
}


Vuforia::Vec4F
SampleMath::Vec4FDiv(Vuforia::Vec4F v, float s)
{
    Vuforia::Vec4F r;
    r.data[0] = v.data[0] / s;
    r.data[1] = v.data[1] / s;
    r.data[2] = v.data[2] / s;
    r.data[3] = v.data[3] / s;
    return r;
}


Vuforia::Matrix44F
SampleMath::Matrix44FIdentity()
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


Vuforia::Matrix44F
SampleMath::Matrix44FTranspose(Vuforia::Matrix44F m)
{
    Vuforia::Matrix44F r;
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            r.data[i*4+j] = m.data[i+4*j];
    return r;
}


float
SampleMath::Matrix44FDeterminate(Vuforia::Matrix44F& m)
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
SampleMath::Matrix44FInverse(Vuforia::Matrix44F& m)
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
