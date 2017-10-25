//
//  javaScriptInterface.hpp
//  RealityEditor
//
//  Created by Valentin Heun on 10/24/17.
//

#ifndef javaScriptInterface_mm
#define javaScriptInterface_mm
#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"


class javaScriptInterface {

    
public:
    void adapter(string function);
  string* parseJavaScriptFunctionString(string function, string* arguments);
private:
   
    size_t pos = 0;
 
};


#endif /* javaScriptInterface_hpp */
