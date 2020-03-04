/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/

#ifndef _VUFORIA_QUAD_H_
#define _VUFORIA_QUAD_H_


static const int kNumQuadVertices = 4;
static const int kNumQuadIndices = 6;


static const float quadVertices[kNumQuadVertices * 3] =
{
   -1.00f,  -1.00f,  0.0f,
    1.00f,  -1.00f,  0.0f,
    1.00f,   1.00f,  0.0f,
   -1.00f,   1.00f,  0.0f,
};

static const float quadTexCoords[kNumQuadVertices * 2] =
{
    0, 0,
    1, 0,
    1, 1,
    0, 1,
};

static const float quadNormals[kNumQuadVertices * 3] =
{
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
};

static const unsigned short quadIndices[kNumQuadIndices] =
{
     0,  1,  2,  0,  2,  3,
};


#endif // _QC_AR_QUAD_H_
