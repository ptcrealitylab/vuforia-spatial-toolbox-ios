//
//  ofxUIWebviewController.m
//  ofxiPhoneWebViewController
//
//  Created by Fluid Interfaces Group on 2/22/16.
//
//

#import "ofxWKWebViewInterfaceJavaScript.h"

ofxWKWebViewInterfaceJavaScript::ofxWKWebViewInterfaceJavaScript() {
    isShowingView = false;
}

void ofxWKWebViewInterfaceJavaScript::initialize() {
    // use default delegate
    initializeWithCustomDelegate(0);// use default
}

void ofxWKWebViewInterfaceJavaScript::initializeWithCustomDelegate(ofxWKWebViewDelegateCpp *delegate) {
    // initialize the WKWebView instance
    
    cout << "Initialized WKWebViewInterface" << endl;
    
    CGRect frame = CGRectMake(0, 0, ofGetWindowWidth()/[UIScreen mainScreen].scale, ofGetWindowHeight()/[UIScreen mainScreen].scale);
    
    // create delegate to handle events
    ofxWKWebViewDelegateObjC *delegateObjC = [[ofxWKWebViewDelegateObjC alloc] init];
    [delegateObjC setDelegate:delegate]; // WARNING: set to 0 when using default delegate
    
    // Create the user content controller and add the script to it
    WKUserContentController *userContentController = [WKUserContentController new];
    [userContentController addScriptMessageHandler:delegateObjC name:@"ofxWKWebView"];
    
    // Create the configuration with the user content controller
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    
    //wkWebViewInstance = [[WKWebView alloc] initWithFrame:frame];
    wkWebViewInstance = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    
    // make it transparent
    [wkWebViewInstance setOpaque:NO];
    [wkWebViewInstance setBackgroundColor:[UIColor clearColor]];
    [wkWebViewInstance.window makeKeyAndVisible];
    
    // make it scrollable
    [[wkWebViewInstance scrollView] setScrollEnabled:YES];
    [[wkWebViewInstance scrollView] setBounces:NO];
    
    // set delegate
    [wkWebViewInstance setNavigationDelegate:delegateObjC];
    [wkWebViewInstance setUIDelegate:delegateObjC];
}

void ofxWKWebViewInterfaceJavaScript::loadURL(string url) {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL *nsURL = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:[NSString defaultCStringEncoding]]];
    
    [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];
}

void ofxWKWebViewInterfaceJavaScript::loadLocalFile(string filename) {
    NSString *_filename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_filename ofType:@"html" inDirectory:@"interfaceData"]];
    [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];
    
}

ofxWKWebViewInterfaceJavaScript::~ofxWKWebViewInterfaceJavaScript() {
    
}

void ofxWKWebViewInterfaceJavaScript::activateView() {
    if (!isShowingView) {
        [ofxiPhoneGetGLParentView() addSubview:wkWebViewInstance];
        isShowingView = true;
    }
}

void ofxWKWebViewInterfaceJavaScript::deactivateView() {
    if (isShowingView) {
        [wkWebViewInstance removeFromSuperview];
        isShowingView = false;
    }
}

void ofxWKWebViewInterfaceJavaScript::toggleView() {
    if (isShowingView) {
        deactivateView();
    } else {
        activateView();
    }
}

// relevant for sending the script
void *ofxWKWebViewInterfaceJavaScript::runJavaScriptFromString(NSString *script) {
    if (isShowingView) {
        [wkWebViewInstance evaluateJavaScript:script completionHandler:nil];
    }
}

