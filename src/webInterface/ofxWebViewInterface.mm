//
//  ofxWebViewInterface.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 3/9/16.
//
//

#include "ofxWebViewInterface.h"
#include <CommonCrypto/CommonCrypto.h>

#define wkOff floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_1
#define wkOn floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_1

static const string securityNamespace = "realityEditor.device.security";

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

#pragma mark - Touch Security

void ofxWebViewInterfaceJavaScript::promptForTouch() {
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    NSString *myLocalizedReasonString = @"Authentication is needed to lock or unlock secured objects";
    
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:myLocalizedReasonString
                            reply:^(BOOL success, NSError *error) {
                                if (success) {
                                    // User authenticated successfully, take appropriate action
                                    touchAuthSucceeded();
                                    
                                } else {
                                    // User did not authenticate successfully, look at error and take appropriate action
                                    NSLog(@"User did not authenticate successfully, look at error and take appropriate action");
                                    touchAuthFailed();
                                    
                                }
                            }];
    } else {
        // Could not evaluate policy; look at authError and present an appropriate message to user
        NSLog(@"Could not evaluate policy; look at authError and present an appropriate message to user");
        touchAuthFailed();
        
    }
}

NSString* ofxWebViewInterfaceJavaScript::sha256HashFor(NSString *input)
{
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (uint)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

NSString* ofxWebViewInterfaceJavaScript::encryptIdString(NSString *idString) {
    NSString *salt = @"qFAxGpq1f2";
    NSString *saltedId = [NSString stringWithFormat:@"%@%@", idString, salt];
    return sha256HashFor(saltedId);
}

void ofxWebViewInterfaceJavaScript::touchAuthSucceeded() {
    NSLog(@"User authenticated successfully, take appropriate action");
    NSString *userId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    
    NSString *encryptedIdString = encryptIdString(userId);
    
    //    if let idString : String = UIDevice.currentDevice().identifierForVendor?.UUIDString {
    
    NSString *jsString = [NSString stringWithFormat:@"%s.authenticateSessionForUser('%@');", securityNamespace.c_str(), encryptedIdString];
    NSLog(@"%@", jsString);
    runJavaScriptFromString(jsString);
}

void ofxWebViewInterfaceJavaScript::touchAuthFailed() {
    NSString *jsString = [NSString stringWithFormat:@"%s.authenticateSessionForUser(null);", securityNamespace.c_str()];
    NSLog(@"%@", jsString);
    runJavaScriptFromString(jsString);
}

