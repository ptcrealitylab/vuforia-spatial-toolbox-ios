//
//  ofxWebViewDelegate.h
//  RealityEditor
//
//  Created by Benjamin Reynolds on 3/8/16.
//
//

#pragma once

#include "ofMain.h"
#include <WebKit/WebKit.h>
#include <UIKit/UIKit.h>

@class ofxWebViewDelegateObjC; // forward declaration

// An abstract class
class ofxWebViewDelegateCpp {
    
public:
    /******************* !!!! *************************************************
     Interface designers MUST override handleCustomRequest() when subclassing
     this class. Designers then define their own protocol to communicate
     from the HTML/JS layer to the C++ layer.
     **************************************************************************/
    virtual void handleCustomRequest(NSString *request) = 0;
    
private:
    ofxWebViewDelegateObjC *delegate;
};

@interface ofxWebViewDelegateObjC : NSObject <UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property(nonatomic, assign) ofxWebViewDelegateCpp *delegate;

@end
