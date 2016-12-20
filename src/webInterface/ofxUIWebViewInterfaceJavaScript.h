//
//  ofxUIWebviewController.h
//  ofxiPhoneWebViewController
//
//  Created by Fluid Interfaces Group on 11/8/13.
//
//

#pragma once

//#include "ofMain.h"
//#include "ofxiPhoneExtras.h"
#include "ofxVuforia.h"
#include "ofxWebViewInterface.h"
#include "ofxUIWebViewDelegate.h"

/**
ofxUIWebViewInterface interfaces with EXACTLY ONE UIWebView instance.

ofxUIWebViewInterface supports 2-way communication with the HTML page it is rendering:

1. Application -> HTML/JS:
runJavaScriptFromString(NSString* script)

2. HTML/JS -> Application:
shouldStartLoadWithRequest() of the DELEGATE will be called whenever
window.location.href = "OF://<address>" is run in the javascript.

Therefore, the protocol is up to the interface programmer to define by defining a SUBCLASS of the
ofxUIWebViewDelegate.
*/
@class UIWebViewMultiInteractable;

class ofxUIWebViewInterfaceJavaScript {

public:
    ofxUIWebViewInterfaceJavaScript();

    ~ofxUIWebViewInterfaceJavaScript();

    /** 1. Initialize */
    void initialize(); // use default ofxUIWebViewDelegate: no custom request handling
    void initializeWithCustomDelegate(ofxUIWebViewDelegateCpp *delegate);

    /** 2. Load a URL or a local file to the webview */
    void loadURL(string url);

    void loadLocalFile(string path);

    /** 3. Activating and deactivating a webview */
    void activateView();

    void deactivateView();

    void toggleView();

    /** 4. Running JS code */
    void *runJavaScriptFromString(NSString *script);

    UIWebView *getUIWebViewInstance() {
        return uiWebViewInstance;
    };

private:
    bool isShowingView;
    UIWebView *uiWebViewInstance;

    ofAppiOSWindow thisWindow = *ofxiPhoneGetOFWindow();
    int screenScale = 1;
};