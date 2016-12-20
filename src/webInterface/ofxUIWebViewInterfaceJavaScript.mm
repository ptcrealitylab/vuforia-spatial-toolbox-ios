//
//  ofxUIWebviewController.m
//  ofxiPhoneWebViewController
//
//  Created by Fluid Interfaces Group on 11/8/13.
//
//

#import "ofxUIWebViewInterfaceJavaScript.h"

ofxUIWebViewInterfaceJavaScript::ofxUIWebViewInterfaceJavaScript() {
    isShowingView = false;
}

void ofxUIWebViewInterfaceJavaScript::initialize() {
    // use default delegate
    initializeWithCustomDelegate(0);// use default
}

void ofxUIWebViewInterfaceJavaScript::initializeWithCustomDelegate(ofxUIWebViewDelegateCpp *delegate) {
    // initialize the UIWebView instance

    cout << "Initialized UIWebViewInterface" << endl;

    CGRect frame = CGRectMake(0, 0, ofGetWindowWidth() / [UIScreen mainScreen].scale, ofGetWindowHeight() / [UIScreen mainScreen].scale);


    uiWebViewInstance = [[UIWebView alloc] initWithFrame:frame];

    // make it transparent
    [uiWebViewInstance setOpaque:NO];
    [uiWebViewInstance setBackgroundColor:[UIColor clearColor]];
    [uiWebViewInstance.window makeKeyAndVisible];

    /*   // make it NOT scrollable
       [[uiWebViewInstance scrollView] setScrollEnabled:NO];
       [[uiWebViewInstance scrollView] setBounces:NO];
       */

    // make it NOT scrollable
    [[uiWebViewInstance scrollView] setScrollEnabled:YES];
    [[uiWebViewInstance scrollView] setBounces:NO];


    //  [uiWebViewInstance scalesPageToFit];

    // uiWebViewInstance.scalesPageToFit = YES;

    // set delegate to handle events
    ofxUIWebViewDelegateObjC *delegateObjC = [[ofxUIWebViewDelegateObjC alloc] init];
    [delegateObjC setDelegate:delegate]; // WARNING: set to 0 when using default delegate
    [uiWebViewInstance setDelegate:delegateObjC];
}

void ofxUIWebViewInterfaceJavaScript::loadURL(string url) {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL *nsURL = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:[NSString defaultCStringEncoding]]];

    [uiWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];

}

void ofxUIWebViewInterfaceJavaScript::loadLocalFile(string filename) {
    NSString *_filename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_filename ofType:@"html" inDirectory:@"interfaceData"]];
    [uiWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];

}

ofxUIWebViewInterfaceJavaScript::~ofxUIWebViewInterfaceJavaScript() {

}

void ofxUIWebViewInterfaceJavaScript::activateView() {
    if (!isShowingView) {
        [ofxiPhoneGetGLParentView() addSubview:uiWebViewInstance];
        isShowingView = true;
    }
}

void ofxUIWebViewInterfaceJavaScript::deactivateView() {
    if (isShowingView) {
        [uiWebViewInstance removeFromSuperview];
        isShowingView = false;
    }
}

void ofxUIWebViewInterfaceJavaScript::toggleView() {
    if (isShowingView) {
        deactivateView();
    } else {
        activateView();
    }
}

// relevant for sending the script
void *ofxUIWebViewInterfaceJavaScript::runJavaScriptFromString(NSString *script) {
    if (isShowingView) {
        [uiWebViewInstance stringByEvaluatingJavaScriptFromString:script];
    }
}

