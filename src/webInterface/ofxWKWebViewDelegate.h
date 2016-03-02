//
//  ofxUIWebViewDelegate.h
//  ofxiPhoneWebViewController
//
//  Created by Fluid Interfaces Group on 2/22/16.
//
//

#pragma once

#import <WebKit/WebKit.h>

@class ofxWKWebViewDelegateObjC; // forward declaration

// An abstract class
class ofxWKWebViewDelegateCpp {
    
public:
    /******************* !!!! *************************************************
     Interface designers MUST override handleCustomRequest() when subclassing
     this class. Designers then define their own protocol to communicate
     from the HTML/JS layer to the C++ layer.
     **************************************************************************/
    virtual void handleCustomRequest(NSString *request) = 0;
    
private:
    ofxWKWebViewDelegateObjC *delegate;
};

@interface ofxWKWebViewDelegateObjC : NSObject <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property(nonatomic, assign) ofxWKWebViewDelegateCpp *delegate;

@end