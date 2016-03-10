//
//  ofxWebViewInterface.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 3/9/16.
//
//

#include "ofxWebViewInterface.h"

bool ofxWebViewInterfaceJavaScript::shouldUseWKWebView()
{
//    bool canUseWKWebView = (NSClassFromString(@"WKWebView"));
    float minDeviceVersion = 9.0;
    bool canUseWKWebView = ([[[UIDevice currentDevice] systemVersion] floatValue] >= minDeviceVersion);
    if (canUseWKWebView) {
        cout << "Can use WKWebView" << endl;
    } else {
        cout << "Can NOT use WKWebView" << endl;
    }
    return canUseWKWebView;
}

NSObject* ofxWebViewInterfaceJavaScript::getWebViewInstance() {
    if (shouldUseWKWebView()) {
        return wkWebViewInstance;
    } else {
        return uiWebViewInstance;
    }
}

ofxWebViewInterfaceJavaScript::ofxWebViewInterfaceJavaScript() {
    isShowingView = false;
}

void ofxWebViewInterfaceJavaScript::initialize() {
    // use default delegate
    initializeWithCustomDelegate(0);// use default
}

void ofxWebViewInterfaceJavaScript::initializeWithCustomDelegate(ofxWebViewDelegateCpp *delegate) {
    // initialize the UIWebView instance
    
    CGRect frame = CGRectMake(0, 0, ofGetWindowWidth()/[UIScreen mainScreen].scale, ofGetWindowHeight()/[UIScreen mainScreen].scale);
    
    ofxWebViewDelegateObjC *delegateObjC = [[ofxWebViewDelegateObjC alloc] init];
    [delegateObjC setDelegate:delegate]; // WARNING: set to 0 when using default delegate

    if (shouldUseWKWebView()) {
        cout << "Initialized WKWebViewInterface" << endl;

        // Create the configuration with the user content controller
        WKUserContentController *userContentController = [WKUserContentController new];
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.userContentController = userContentController;
        
        wkWebViewInstance = [[WKWebView alloc] initWithFrame:frame configuration:configuration];

        // set delegate
        [wkWebViewInstance setNavigationDelegate:delegateObjC];
        [wkWebViewInstance setUIDelegate:delegateObjC];
        
        // make it transparent
        [wkWebViewInstance setOpaque:NO];
        [wkWebViewInstance setBackgroundColor:[UIColor clearColor]];
        [wkWebViewInstance.window makeKeyAndVisible];
        
        // make it scrollable
        [[wkWebViewInstance scrollView] setScrollEnabled:YES];
        [[wkWebViewInstance scrollView] setBounces:NO];
        
    } else {
        cout << "Initialized UIWebViewInterface" << endl;
        uiWebViewInstance = [[UIWebView alloc] initWithFrame:frame];
        
        // set delegate to handle events
        [uiWebViewInstance setDelegate:delegateObjC];
        
        // make it transparent
        [uiWebViewInstance setOpaque:NO];
        [uiWebViewInstance setBackgroundColor:[UIColor clearColor]];
        [uiWebViewInstance.window makeKeyAndVisible];
        
        // make it scrollable
        [[uiWebViewInstance scrollView] setScrollEnabled:YES];
        [[uiWebViewInstance scrollView] setBounces:NO];
    }



}

void ofxWebViewInterfaceJavaScript::loadURL(string url) {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL *nsURL = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:[NSString defaultCStringEncoding]]];
    
    if (shouldUseWKWebView()) {
        [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];
    } else {
        [uiWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];
    }
}

void ofxWebViewInterfaceJavaScript::loadLocalFile(string filename) {
    NSString *_filename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_filename ofType:@"html" inDirectory:@"interfaceData"]];
    
    if (shouldUseWKWebView()) {
        [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];
    } else {
        [uiWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];
    }
    
}

void ofxWebViewInterfaceJavaScript::activateView() {
    if (!isShowingView) {
        if (shouldUseWKWebView()) {
            [ofxiPhoneGetGLParentView() addSubview:wkWebViewInstance];
        } else {
            [ofxiPhoneGetGLParentView() addSubview:uiWebViewInstance];
        }
        isShowingView = true;
    }
}

void ofxWebViewInterfaceJavaScript::deactivateView() {
    if (isShowingView) {
        if (shouldUseWKWebView()) {
            [wkWebViewInstance removeFromSuperview];
        } else {
            [uiWebViewInstance removeFromSuperview];
        }
        isShowingView = false;
    }
}

void ofxWebViewInterfaceJavaScript::toggleView() {
    if (isShowingView) {
        deactivateView();
    } else {
        activateView();
    }
}

// relevant for sending the script
void *ofxWebViewInterfaceJavaScript::runJavaScriptFromString(NSString *script) {
    if (isShowingView) {
        if (shouldUseWKWebView()) {
            [wkWebViewInstance evaluateJavaScript:script completionHandler:nil];
        } else {
            [uiWebViewInstance stringByEvaluatingJavaScriptFromString:script];
        }
    }
}

ofxWebViewInterfaceJavaScript::~ofxWebViewInterfaceJavaScript() {
    
}

