/*===============================================================================
Copyright (c) 2020 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/


#ifndef _VUFORIA_SAMPLEMATH_H_
#define _VUFORIA_SAMPLEMATH_H_

// Includes:
#include <Vuforia/Tool.h>

/// A utility class used by the Vuforia Engine samples.
class SampleMath
{
public:
    
    static Vuforia::Vec2F Vec2FSub(Vuforia::Vec2F v1, Vuforia::Vec2F v2);
    
    static float Vec2FDist(Vuforia::Vec2F v1, Vuforia::Vec2F v2);
    
    static Vuforia::Vec3F Vec3FAdd(Vuforia::Vec3F v1, Vuforia::Vec3F v2);
    
    static Vuforia::Vec3F Vec3FSub(Vuforia::Vec3F v1, Vuforia::Vec3F v2);
    
    static Vuforia::Vec3F Vec3FScale(Vuforia::Vec3F v, float s);
    
    static float Vec3FDot(Vuforia::Vec3F v1, Vuforia::Vec3F v2);
    
    static Vuforia::Vec3F Vec3FCross(Vuforia::Vec3F v1, Vuforia::Vec3F v2);
    
    static Vuforia::Vec3F Vec3FNormalize(Vuforia::Vec3F v);
    
    static Vuforia::Vec3F Vec3FTransform(Vuforia::Vec3F& v, Vuforia::Matrix44F& m);
    
    static Vuforia::Vec3F Vec3FTransformNormal(Vuforia::Vec3F& v, Vuforia::Matrix44F& m);
    
    static Vuforia::Vec4F Vec4FTransform(Vuforia::Vec4F& v, Vuforia::Matrix44F& m);
    
    static Vuforia::Vec4F Vec4FDiv(Vuforia::Vec4F v, float s);
    
    static Vuforia::Matrix44F Matrix44FIdentity();
    
    static Vuforia::Matrix44F Matrix44FTranspose(Vuforia::Matrix44F m);
    
    static float Matrix44FDeterminate(Vuforia::Matrix44F& m);
    
    static Vuforia::Matrix44F Matrix44FInverse(Vuforia::Matrix44F& m);
    
};

#endif // _VUFORIA_SAMPLEMATH_H_
