/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/


#import "SampleApplication3DModel.h"

@interface SampleApplication3DModel ()

@property (nonatomic, strong) NSString* path;

// public properties redefined here as private 'readwrite'
@property (nonatomic, readwrite) NSInteger numVertices;
@property (nonatomic, readwrite) float* vertices;
@property (nonatomic, readwrite) float* normals;
@property (nonatomic, readwrite) float* texCoords;

@end

@implementation SampleApplication3DModel

- (id)initWithTxtResourceName:(NSString *) name
{
    self = [super init];
    if (self) {
        _path = [[NSBundle mainBundle] pathForResource:name ofType:@"txt"];
    }
    return self;
}

- (void)dealloc
{
    free (_vertices);
    free (_normals);
    free (_texCoords);
    
    _vertices = nil;
    _normals = nil;
    _texCoords = nil;
}

- (void) read {
    char buffer[132];
    int nbItems = 0;
    int index = 0;
    float *data = NULL;
    
    const char *fileCStr = [[NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    int state = 0;
    const char *curLine = fileCStr;
    while (curLine)
    {
        char * nextLine = strchr(curLine, '\n');
        
        char ch = curLine[0];
        int ci = 0;
        while ((ch != '\n') && (ch != '\0')) {
            ch = buffer[ci] = curLine[ci];
            ci++;
        }
        
        curLine = nextLine ? (nextLine+1) : NULL;
        
        if (buffer[0] == ':') {
            if ((state > 0) && (index != nbItems)) {
                // check that we got all the data we needed
                NSLog(@"buffer underflow!");
            }
            state++;
            nbItems = atoi(&buffer[1]);
            index  = 0;
            
            switch(state) {
                case 1:
                    _numVertices = nbItems / 3;
                    _vertices = malloc( nbItems * sizeof(float));
                    data = _vertices;
                    break;
                case 2:
                    _normals = malloc( nbItems * sizeof(float));
                    data = _normals;
                    break;
                case 3:
                    _texCoords = malloc( nbItems * sizeof(float));
                    data = _texCoords;
                    break;
            }
        } else {
            if (index >= nbItems) {
                // check that we don't get too many data
                NSLog(@"buffer overflow!");
            } else {
                data[index++] = atof(buffer);
            }
        }
    }
}
@end
