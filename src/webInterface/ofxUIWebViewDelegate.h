//
//  ofxUIWebViewDelegate.h
//  ofxiPhoneWebViewController
//
//  Created by Fluid Interfaces Group on 11/8/13.
//
//

#pragma once

///#import <Foundation/Foundation.h>

@class ofxUIWebViewDelegateObjC; // forward declaration

// An abstract class
class ofxUIWebViewDelegateCpp {

public:
    /******************* !!!! *************************************************
    Interface designers MUST override handleCustomRequest() when subclassing
    this class. Designers then define their own protocol to communicate
    from the HTML/JS layer to the C++ layer.
    **************************************************************************/
    virtual void handleCustomRequest(NSString *request) = 0;

private:
    ofxUIWebViewDelegateObjC *delegate;
};

@interface ofxUIWebViewDelegateObjC : NSObject <UIWebViewDelegate>

@property(nonatomic, assign) ofxUIWebViewDelegateCpp *delegate;

@end