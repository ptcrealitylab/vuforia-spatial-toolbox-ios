//
//  VuforiaState.h
//  RealityEditor
//
//  Created by James Hobin on 7/8/16.
//
//  Holds all required information to recreate a given moment of time. Currently this is the camera image and every marker's matrix and name

#ifndef VuforiaState_h
#define VuforiaState_h

class VuforiaState {
public:
    
    VuforiaState(ofImage _image, vector<ofMatrix4x4> _matrix, vector<string> _name) {
        image = _image;
        matrix = _matrix;
        name = _name;
    }
    
    VuforiaState() {
    }
    
    ofImage image;
    vector<ofMatrix4x4> matrix;
    vector<string> name;
};

#endif /* VuforiaState_h */
