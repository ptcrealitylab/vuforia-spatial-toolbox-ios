/*===============================================================================
Copyright (c) 2020 PTC Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

#ifndef __MODELS_H__
#define __MODELS_H__


// SQUARE MODEL
static const unsigned short NUM_SQUARE_VERTEX = 4;
static const unsigned short NUM_SQUARE_INDEX = 6;
static const unsigned short NUM_SQUARE_WIREFRAME_INDEX = 8;

static const float squareVertices[NUM_SQUARE_VERTEX * 3] =
    {
        -0.50f, -0.50f, 0.00f,
         0.50f, -0.50f, 0.00f,
         0.50f,  0.50f, 0.00f,
        -0.50f,  0.50f, 0.00f
    };

static const float squareTexCoords[NUM_SQUARE_VERTEX * 2] =
    {
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f
    };

static const unsigned short squareIndices[NUM_SQUARE_INDEX] =
    {
        0, 1, 2, 0, 2, 3
    };

static const unsigned short squareWireframeIndices[NUM_SQUARE_WIREFRAME_INDEX] =
    {
        0, 1, 1, 2, 2, 3, 3, 0
    };
// END SQUARE MODEL


// CUBE MODEL
static const unsigned short NUM_CUBE_VERTEX = 24;
static const unsigned short NUM_CUBE_INDEX = 36;
static const unsigned short NUM_CUBE_WIREFRAME_INDEX = 24;


static const float cubeVertices[NUM_CUBE_VERTEX * 3] =
    {
        -0.50f, -0.50f,  0.50f, // front
         0.50f, -0.50f,  0.50f,
         0.50f,  0.50f,  0.50f,
        -0.50f,  0.50f,  0.50f,

        -0.50f, -0.50f, -0.50f, // back
         0.50f, -0.50f, -0.50f,
         0.50f,  0.50f, -0.50f,
        -0.50f,  0.50f, -0.50f,

        -0.50f, -0.50f, -0.50f, // left
        -0.50f, -0.50f,  0.50f,
        -0.50f,  0.50f,  0.50f,
        -0.50f,  0.50f, -0.50f,

         0.50f, -0.50f, -0.50f, // right
         0.50f, -0.50f,  0.50f,
         0.50f,  0.50f,  0.50f,
         0.50f,  0.50f, -0.50f,

        -0.50f,  0.50f,  0.50f, // top
         0.50f,  0.50f,  0.50f,
         0.50f,  0.50f, -0.50f,
        -0.50f,  0.50f, -0.50f,

        -0.50f, -0.50f,  0.50f, // bottom
         0.50f, -0.50f,  0.50f,
         0.50f, -0.50f, -0.50f,
        -0.50f, -0.50f, -0.50f
    };

static const float cubeTexCoords[NUM_CUBE_VERTEX * 2] =
    {
        0, 0,
        1, 0,
        1, 1,
        0, 1,

        1, 0,
        0, 0,
        0, 1,
        1, 1,

        0, 0,
        1, 0,
        1, 1,
        0, 1,

        1, 0,
        0, 0,
        0, 1,
        1, 1,

        0, 0,
        1, 0,
        1, 1,
        0, 1,

        1, 0,
        0, 0,
        0, 1,
        1, 1
    };

static const float cubeNormals[NUM_CUBE_VERTEX * 3] =
    {
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,

        0, 0, -1,
        0, 0, -1,
        0, 0, -1,
        0, 0, -1,

        0, -1, 0,
        0, -1, 0,
        0, -1, 0,
        0, -1, 0,

        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,

        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,

        -1, 0, 0,
        -1, 0, 0,
        -1, 0, 0,
        -1, 0, 0
    };

static const unsigned short cubeIndices[NUM_CUBE_INDEX] =
    {
        0, 1, 2, 0, 2, 3, // front
        4, 6, 5, 4, 7, 6, // back
        8, 9, 10, 8, 10, 11, // left
        12, 14, 13, 12, 15, 14, // right
        16, 17, 18, 16, 18, 19, // top
        20, 22, 21, 20, 23, 22  // bottom
    };

static const unsigned short cubeWireframeIndices[NUM_CUBE_WIREFRAME_INDEX] =
    {
        0, 1, 1, 2, 2, 3, 3, 0, // front
        4, 5, 5, 6, 6, 7, 7, 4, // back
        0, 4, 1, 5, 2, 6, 3, 7 // side
    };
// END CUBE MODEL


// AXIS MODEL
static const unsigned short NUM_AXIS_VERTEX = 6;
static const unsigned short NUM_AXIS_COLOR = 6;
static const unsigned short NUM_AXIS_INDEX = 6;

static const float axisVertices[NUM_AXIS_VERTEX * 3] =
    {
        0.00f, 0.00f, 0.00f, // origin
        1.00f, 0.00f, 0.00f, // x axis
        0.00f, 0.00f, 0.00f, // origin
        0.00f, 1.00f, 0.00f,// y axis
        0.00f, 0.00f, 0.00f, // origin
        0.00f, 0.00f, 1.00f // z axis
    };

static const float axisColors[NUM_AXIS_COLOR * 4] =
    {
        1.00f, 0.00f, 0.00f, 1.00f, // red
        1.00f, 0.00f, 0.00f, 1.00f, // red
        0.00f, 1.00f, 0.00f, 1.00f, // green
        0.00f, 1.00f, 0.00f, 1.00f, // green
        0.00f, 0.00f, 1.00f, 1.00f, // blue
        0.00f, 0.00f, 1.00f, 1.00f // blue
    };

static const unsigned short axisIndices[NUM_AXIS_INDEX] =
    {
        0, 1, 2, 3, 4, 5
    };
// END AXIS MODEL


#endif //__MODELS_H__
