//
//  ofxWebViewInterface.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 3/9/16.
//
//

#include "ofxWebViewInterface.h"

#define wkOff floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_1
#define wkOn floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_1

NSObject* ofxWebViewInterfaceJavaScript::getWebViewInstance() {
    if (wkOn) {
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
    
    if (wkOn) {
        cout << "Initialized WKWebViewInterface" << endl;
        
        // Create the configuration with the user content controller
        WKUserContentController *userContentController = [WKUserContentController new];
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.userContentController = userContentController;
        configuration.allowsInlineMediaPlayback = YES;
        
        
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
        [uiWebViewInstance setAllowsInlineMediaPlayback:YES];
        
        // make it scrollable
        [[uiWebViewInstance scrollView] setScrollEnabled:YES];
        [[uiWebViewInstance scrollView] setBounces:NO];
    }
    
    
    
}

void ofxWebViewInterfaceJavaScript::loadURL(string url) {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL *nsURL = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:[NSString defaultCStringEncoding]]];
    
    if (wkOn) {
        [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];
    } else {
        [uiWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];
    }
}

void ofxWebViewInterfaceJavaScript::loadLocalFile(string filename) {
    NSString *_filename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_filename ofType:@"html" inDirectory:@"editor_private"]];
    
    if (wkOn) {
        [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];
    } else {
        [uiWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];
    }
    
}

void ofxWebViewInterfaceJavaScript::activateView() {
    if (!isShowingView) {
        if (wkOn) {
            [ofxiPhoneGetGLParentView() addSubview:wkWebViewInstance];
        } else {
            [ofxiPhoneGetGLParentView() addSubview:uiWebViewInstance];
        }
        isShowingView = true;
    }
}

void ofxWebViewInterfaceJavaScript::deactivateView() {
    if (isShowingView) {
        if (wkOn) {
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
        if (wkOn) {
            [wkWebViewInstance evaluateJavaScript:script completionHandler:nil];
        } else {
            [uiWebViewInstance stringByEvaluatingJavaScriptFromString:script];
        }
    }
}

ofxWebViewInterfaceJavaScript::~ofxWebViewInterfaceJavaScript() {
    
}

