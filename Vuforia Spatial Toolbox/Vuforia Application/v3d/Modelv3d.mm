/*===============================================================================
 Copyright (c) 2016-2018 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/



#import <Foundation/NSByteOrder.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "Modelv3d.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"

static const GLsizei SHADERS_BUFFER_NUM = 5;
static const int GEOMETRY_ARRAY = 0;
static const int NORMALS_ARRAY = 1;
static const int OBJ_MTL_EXTRA_ARRAY = 2;
static const int OBJ_AMBIENT_ARRAY = 3;
static const int OBJ_DIFFUSE_ARRAY = 4;

@interface Modelv3d ()

@property (nonatomic, readwrite) NSData *data;
@property (nonatomic, readwrite) NSUInteger location;

@property (nonatomic, readwrite) uint nbVertices;
@property (nonatomic, readwrite) uint nbFaces;
@property (nonatomic, readwrite) uint nbGroups;
@property (nonatomic, readwrite) uint nbMaterials;

@property (nonatomic, readwrite) float* vertices;
@property (nonatomic, readwrite) float* normals;
@property (nonatomic, readwrite) float* texCoords;
@property (nonatomic, readwrite) float* materialIndices;
@property (nonatomic, readwrite) float* groupAmbientColors;
@property (nonatomic, readwrite) float* groupDiffuseColors;
@property (nonatomic, readwrite) float* groupSpecularColors;
@property (nonatomic, readwrite) int* groupVertexRange;

@property (nonatomic, readwrite) bool isLoaded;

@property (nonatomic, readwrite) float transparencyValue;
@property (nonatomic, readwrite) float* lightColor;

@property (nonatomic) GLuint * shaderBuffers;

@property (nonatomic) int* mTexturesIds;


@property (nonatomic) GLuint objMtlProgramID;
@property (nonatomic) GLint objMtlVertexHandle;
@property (nonatomic) GLint objMtlNormalHandle;
@property (nonatomic) GLint objMtlMvpMatrixHandle;
@property (nonatomic) GLint objMtlMvMatrixHandle;
@property (nonatomic) GLint objMtlNormalMatrixHandle;
@property (nonatomic) GLint objMtlLightPosHandle;
@property (nonatomic) GLint objMtlLightColorHandle;

@property (nonatomic) GLint objMtlExtra;
@property (nonatomic) GLint objMtlGroupAmbientColorsHandle;
@property (nonatomic) GLint objMtlGroupDiffuseColorsHandle;
@property (nonatomic) GLint objMtlGroupSpecularColorsHandle;
@property (nonatomic) GLint objTransparencyHandle;

@end


@implementation Modelv3d

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.transparencyValue = 1;
        
        self.lightColor = new float[4];
        float lightColor[] = {.5f, .5f, .5f, 1.0f};
        [self setLightingColor:lightColor];
    }
    return self;
}

- (uint) readUint {
    uint value;
    NSRange range = {self.location, 4};
    [self.data getBytes:&value range:range];
    self.location += 4;
    
   return NSSwapInt(value);
    
}

- (uint) readInt {
    int value;
    NSRange range = {self.location, 4};
    [self.data getBytes:&value range:range];
    self.location += 4;
    
    return (int)NSSwapInt(value);
    
}

- (float) readFloat {
    uint32_t value;
    NSRange range = {self.location, 4};
    [self.data getBytes:&value range:range];
    self.location += 4;
    
//    uint32_t hostData = CFSwapInt32LittleToHost(value);
    uint32_t hostData = CFSwapInt32BigToHost(value);
    return *(float *)(&hostData);
}

- (bool) loadModel: (NSString *) filename {
    const int FLOAT_BYTES = sizeof(float);
    const int INT_BYTES = sizeof(int);
    int ignoreInt;
    float ignoreFloat;
    
    if( FLOAT_BYTES != 4 || INT_BYTES != 4) {
        NSLog(@"sizes mismatched");
        return false;
    }
    
    NSString* path = [[NSBundle mainBundle] pathForResource:filename ofType:@"v3d"];
    self.data = [NSData dataWithContentsOfFile:path];
    self.location = 0;
    
    uint magicNumber = [self readUint];
    NSLog(@"magicNumber: %4x", magicNumber);
    
    float version = [self readFloat];
    NSLog(@"version: %7.5f", version);
    
    // Read vertices number
    self.nbVertices = [self readUint];
    NSLog(@"nbVertices: %d", self.nbVertices);
    
    // Read faces number
    self.nbFaces = [self readUint];;
    NSLog(@"nbFaces: %d", self.nbFaces);
    
    // Read material number
    self.nbMaterials = [self readUint];;
    NSLog(@"nbMaterials: %d", self.nbMaterials);
    self.nbGroups = self.nbMaterials;
    
    // Read vertices
    int numFloatsToRead = self.nbFaces * 3 * 3; // 3 vertices per face, 3 values per vertex x, y, z
    self.vertices = (float *)malloc( numFloatsToRead * sizeof(float));
    
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.vertices[i] = [self readFloat];
    }
    NSLog(@"First vertex %12.6f %12.6f %12.6f", self.vertices[0], self.vertices[1], self.vertices[2]);
    
    
    // Read normals
    numFloatsToRead = self.nbFaces * 3 * 3; // 3 vertices per face, 3 values per vertex x, y, z
    self.normals = (float *)malloc( numFloatsToRead * sizeof(float));
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.normals[i] = [self readFloat];
    }
    NSLog(@"First normal %12.6f %12.6f %12.6f", self.normals[0], self.normals[1], self.normals[2]);
    
    // Read texture coordinates
    numFloatsToRead = self.nbFaces * 3 * 2; // 3 vertices per face, 2 values per vertex u, v
    self.texCoords = (float *)malloc( numFloatsToRead * sizeof(float));
    
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.texCoords[i] = [self readFloat];
    }
    
    // Read material per face and shininess
    numFloatsToRead = self.nbFaces * 3 * 2; // 3 vertices per face, 2 values per vertex material, shininess
    self.materialIndices = (float *)malloc( numFloatsToRead * sizeof(float));
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.materialIndices[i] = [self readFloat];
    }
    NSLog(@"First material and shininess: %12.6f %12.6f", self.materialIndices[0], self.materialIndices[1]);
    
    // Read material ambient color
    numFloatsToRead = self.nbMaterials * 4; // 4 values per material r, g, b, a
    self.groupAmbientColors = (float *)malloc( numFloatsToRead * sizeof(float));
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.groupAmbientColors[i] = [self readFloat];
    }
    NSLog(@"First ambient color: %12.6f %12.6f %12.6f %12.6f",self.groupAmbientColors[0],self.groupAmbientColors[1],self.groupAmbientColors[2],self.groupAmbientColors[3]);

    // Read material diffuse color
    numFloatsToRead = self.nbMaterials * 4; // 4 values per material r, g, b, a
    self.groupDiffuseColors = (float *)malloc( numFloatsToRead * sizeof(float));
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.groupDiffuseColors[i] = [self readFloat];
    }
//    for(int n = 0, i=0; n < numFloatsToRead ; n++) {
//        NSLog(@"diffuse color{%d]: %12.6f %12.6f %12.6f %12.6f",n, self.groupDiffuseColors[i++],self.groupDiffuseColors[i++],self.groupDiffuseColors[i++],self.groupDiffuseColors[i++]);
//    }

    // Read material specular color
    numFloatsToRead = _nbMaterials * 4; // 4 values per material r, g, b, a
    self.groupSpecularColors = (float *)malloc( numFloatsToRead * sizeof(float));
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.groupSpecularColors[i] = [self readFloat];
    }
    NSLog(@"First specular color: %12.6f %12.6f %12.6f %12.6f",self.groupSpecularColors[0],self.groupSpecularColors[1],self.groupSpecularColors[2],self.groupSpecularColors[3]);
    
    // Read material diffuse texture indexes (ignored)
    numFloatsToRead = _nbMaterials; // 1 index per material
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        ignoreInt = [self readInt];
    }
    
    // Read material dissolve value (transparency) -- IGNORED
    numFloatsToRead = _nbMaterials; // 1 value per material
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        ignoreFloat = [self readFloat];
    }
    
    // Read vertex range per group
    numFloatsToRead = _nbMaterials * 2; // 2 values per material
    self.groupVertexRange = (int *)malloc( numFloatsToRead * sizeof(int));
    for(int i = 0; i < numFloatsToRead; ++i)
    {
        self.groupVertexRange[i] = [self readInt];
    }
    NSLog(@"First material diffuse texture index:%d , %d",self.groupVertexRange[0],self.groupVertexRange[1]);
    
    uint magicNumberEnd = [self readUint];
    NSLog(@"magicNumber (end): %4x", magicNumberEnd);

    // we don't need to read anymore data
    self.data = nil;

    
    if (magicNumber != magicNumberEnd) {
        // sanity check to see if we read properly the magic number at the end of the file
        NSLog(@"Error while reading the q3d file %@", filename);
        [self unloadModel];
        return false;
    }
    
    [self initShaders];
    self.isLoaded = true;

    return true;
}

- (void) unloadModel {
    if (self.isLoaded) {
        self.isLoaded = false;
        glDeleteBuffers(SHADERS_BUFFER_NUM, self.shaderBuffers);
        delete [] self.shaderBuffers;
        
        free(self.vertices);
        free(self.normals);
        free(self.texCoords);
        free(self.materialIndices);
        free(self.groupAmbientColors);
        free(self.groupDiffuseColors);
        free(self.groupSpecularColors);
        free(self.groupVertexRange);
    }
}

- (bool) initShaders {
    NSLog(@"initShaders");
    
    self.shaderBuffers = new GLuint[SHADERS_BUFFER_NUM];
    
    if (self.transparencyValue < 1.0f)
    {
        self.objMtlProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"DiffuseLightMaterials.vertsh"     fragmentShaderFileName:@"DiffuseLightMaterials.fragsh"];
        
        SampleApplicationUtils::checkGlError("v3d GLInitRendering #0");
        
        self.objMtlVertexHandle = glGetAttribLocation(self.objMtlProgramID, "a_vertexPosition");
        self.objMtlNormalHandle = glGetAttribLocation(self.objMtlProgramID, "a_vertexNormal");
    }
    else
    {
        self.objMtlProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"DiffuseLight.vertsh"     fragmentShaderFileName:@"DiffuseLight.fragsh"];
        
        SampleApplicationUtils::checkGlError("v3d GLInitRendering #0");
        
        self.objMtlVertexHandle = glGetAttribLocation(self.objMtlProgramID, "a_position");
        self.objMtlNormalHandle = glGetAttribLocation(self.objMtlProgramID, "a_normal");
    }
    
    
    if (self.objMtlProgramID == 0) {
        NSLog(@"Could not initialise augmentation shader");
        return false;
    }
    
    
    self.objMtlExtra = glGetAttribLocation(self.objMtlProgramID, "a_vertexExtra");
    
    NSLog(@">GL> objMtlVertexHandle= %d" , self.objMtlVertexHandle);
    NSLog(@">GL> objMtlExtra= %d" , self.objMtlExtra);
    
    self.objMtlMvpMatrixHandle = glGetUniformLocation(self.objMtlProgramID,
                                                        "u_mvpMatrix");
    self.objMtlMvMatrixHandle = glGetUniformLocation(self.objMtlProgramID, "u_mvMatrix");
    self.objMtlNormalMatrixHandle = glGetUniformLocation(self.objMtlProgramID,
                                                           "u_normalMatrix");
    
    self.objMtlLightPosHandle = glGetUniformLocation(self.objMtlProgramID, "u_lightPos");
    self.objMtlLightColorHandle = glGetUniformLocation(self.objMtlProgramID,
                                                         "u_lightColor");
    self.objTransparencyHandle = glGetUniformLocation(self.objMtlProgramID, "u_transparency");
    
    self.objMtlGroupAmbientColorsHandle = glGetUniformLocation(self.objMtlProgramID,
                                                                 "u_groupAmbientColors");
    self.objMtlGroupDiffuseColorsHandle = glGetUniformLocation(self.objMtlProgramID,
                                                                 "u_groupDiffuseColors");
    self.objMtlGroupSpecularColorsHandle = glGetUniformLocation(self.objMtlProgramID,
                                                                  "u_groupSpecularColors");
    
    SampleApplicationUtils::checkGlError("v3d GLInitRendering #1");
    
    
#ifdef XXXX
    int * total = new int[1];
    glGetProgramiv(self.objMtlProgramID, GL_ACTIVE_UNIFORMS, total, 0);
    
    if (Build.VERSION.SDK_INT > Build.VERSION_CODES.JELLY_BEAN)
    {
        NSLog(@"@@ nb uniforms: " + total[0]);
        for (int i = 0; i < total[0]; ++i) {
            int[] uniformType = new int[1];
            int[] uniformSize = new int[1];
            String name = glGetActiveUniform(objMtlProgramID, i, uniformSize, 0, uniformType, 0);
            int location = glGetUniformLocation(objMtlProgramID, name);
            NSLog(@"@@ uniform(" + name + "), location= " + location);
        }
    }
#endif
    
    glGenBuffers(SHADERS_BUFFER_NUM, self.shaderBuffers);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[GEOMETRY_ARRAY]);
    glBufferData(GL_ARRAY_BUFFER, self.nbVertices * 3 * sizeof(float), self.vertices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[NORMALS_ARRAY]);
    glBufferData(GL_ARRAY_BUFFER, self.nbVertices * 3 * sizeof(float), self.normals, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[OBJ_MTL_EXTRA_ARRAY]);
    glBufferData(GL_ARRAY_BUFFER, self.nbVertices * 2 * sizeof(float), self.materialIndices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[OBJ_AMBIENT_ARRAY]);
    glBufferData(GL_ARRAY_BUFFER, self.nbGroups * sizeof(float), self.groupAmbientColors, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[OBJ_DIFFUSE_ARRAY]);
    glBufferData(GL_ARRAY_BUFFER, self.nbGroups * sizeof(float), self.groupDiffuseColors, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    NSLog(@"end of initShaders");
    
    return true;
}


- (bool) renderWithModelView:(float[]) modelViewMatrix modelViewProjMatrix:(float[]) modelViewProjMatrix
{
    glUseProgram(self.objMtlProgramID);
    
    if(self.isLoaded) {
        glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[GEOMETRY_ARRAY]);
        glVertexAttribPointer(self.objMtlVertexHandle, 3, GL_FLOAT, false, 0,
                                     0);
        
        glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[NORMALS_ARRAY]);
        glVertexAttribPointer(self.objMtlNormalHandle, 3, GL_FLOAT, false, 0,
                                     0);
        glBindBuffer(GL_ARRAY_BUFFER, self.shaderBuffers[OBJ_MTL_EXTRA_ARRAY]);
        glVertexAttribPointer(self.objMtlExtra, 2, GL_FLOAT, false, 0,
                                     0);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        glEnableVertexAttribArray(self.objMtlVertexHandle);
        glEnableVertexAttribArray(self.objMtlNormalHandle);
        glEnableVertexAttribArray(self.objMtlExtra);
        

        if(self.objMtlMvpMatrixHandle >= 0) {
            glUniformMatrix4fv(self.objMtlMvpMatrixHandle, 1, false,
                                      modelViewProjMatrix);
        }
        
        glUniformMatrix4fv(self.objMtlMvMatrixHandle, 1, false,
                                  modelViewMatrix);
        
        GLKMatrix4 mvMatrix = GLKMatrix4MakeWithArray (modelViewMatrix);
        
        bool isInvertible;
        
        GLKMatrix4 normalMatrix = GLKMatrix4InvertAndTranspose ( mvMatrix, &isInvertible );
        
        glUniformMatrix4fv(self.objMtlNormalMatrixHandle, 1, false,
                                  normalMatrix.m);
        
        glUniform4fv(self.objMtlGroupAmbientColorsHandle, self.nbGroups,
                            self.groupAmbientColors);
        glUniform4fv(self.objMtlGroupDiffuseColorsHandle, self.nbGroups,
                            self.groupDiffuseColors);
        
        glUniform4fv(self.objMtlGroupSpecularColorsHandle, self.nbGroups,
                            self.groupSpecularColors);
        
        glUniform4f(self.objMtlLightPosHandle, 0.2f, -1.0f, 0.5f, -1.0f);
        glUniform4f(self.objMtlLightColorHandle, self.lightColor[0], self.lightColor[1], self.lightColor[2], self.lightColor[3]);
        glUniform1f(self.objTransparencyHandle, self.transparencyValue);

        BOOL enableBlending = NO;
        if(self.transparencyValue < 1.0f)
        {
            enableBlending = YES;
        }
        
        if(enableBlending)
        {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        
        glDrawArrays(GL_TRIANGLES, 0, self.nbVertices);
        
        if(enableBlending)
        {
            glDisable(GL_BLEND);
        }
    }
    else {
        NSLog(@"Not Rendering V3d");
    }
    
    SampleApplicationUtils::checkGlError("v3d renderframe");

    
    glDisableVertexAttribArray(self.objMtlVertexHandle);
    glDisableVertexAttribArray(self.objMtlNormalHandle);
    glDisableVertexAttribArray(self.objMtlExtra);
    
    return true;
}

-(void) setTransparency:(float)transparencyValue
{
    self.transparencyValue = MIN(1.0f, transparencyValue);
}

- (void) setLightingColor:(float[]) lightColor
{
    for(int i = 0; i < 4; i++)
        self.lightColor[i] = lightColor[i];
}
@end
