/**
 * @preserve
 *
 *                                      .,,,;;,'''..
 *                                  .'','...     ..',,,.
 *                                .,,,,,,',,',;;:;,.  .,l,
 *                               .,',.     ...     ,;,   :l.
 *                              ':;.    .'.:do;;.    .c   ol;'.
 *       ';;'                   ;.;    ', .dkl';,    .c   :; .'.',::,,'''.
 *      ',,;;;,.                ; .,'     .'''.    .'.   .d;''.''''.
 *     .oxddl;::,,.             ',  .'''.   .... .'.   ,:;..
 *      .'cOX0OOkdoc.            .,'.   .. .....     'lc.
 *     .:;,,::co0XOko'              ....''..'.'''''''.
 *     .dxk0KKdc:cdOXKl............. .. ..,c....
 *      .',lxOOxl:'':xkl,',......'....    ,'.
 *           .';:oo:...                        .
 *                .cd,      ╔═╗┌┬┐┬┌┬┐┌─┐┬─┐    .
 *                  .l;     ║╣  │││ │ │ │├┬┘    '
 *                    'l.   ╚═╝─┴┘┴ ┴ └─┘┴└─   '.
 *                     .o.                   ...
 *                      .''''','.;:''.........
 *                           .'  .l
 *                          .:.   l'
 *                         .:.    .l.
 *                        .x:      :k;,.
 *                        cxlc;    cdc,,;;.
 *                       'l :..   .c  ,
 *                       o.
 *                      .,
 *
 *      ╦═╗┌─┐┌─┐┬  ┬┌┬┐┬ ┬  ╔═╗┌┬┐┬┌┬┐┌─┐┬─┐  ╔═╗┬─┐┌─┐ ┬┌─┐┌─┐┌┬┐
 *      ╠╦╝├┤ ├─┤│  │ │ └┬┘  ║╣  │││ │ │ │├┬┘  ╠═╝├┬┘│ │ │├┤ │   │
 *      ╩╚═└─┘┴ ┴┴─┘┴ ┴  ┴   ╚═╝─┴┘┴ ┴ └─┘┴└─  ╩  ┴└─└─┘└┘└─┘└─┘ ┴
 *
 *
 * Created by Benjamin Reynolds on 7/14/16.
 *
 * Copyright (c) 2015 Valentin Heun
 *
 * All ascii characters above must be included in any redistribution.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#include "ofxWebViewInterface.h"
#include <CommonCrypto/CommonCrypto.h>

#define IS_IOS11orHIGHER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0)

static const string securityNamespace = "realityEditor.device.security";

ofxWebViewInterfaceJavaScript::ofxWebViewInterfaceJavaScript() {
    isShowingView = false;
}

void ofxWebViewInterfaceJavaScript::initialize() {
    // use default delegate
    initializeWithCustomDelegate(0);// use default
}

void ofxWebViewInterfaceJavaScript::initializeWithCustomDelegate(ofxWebViewDelegateCpp *delegate) {
    // initialize the UIWebView instance
    
//    CGRect frame = CGRectMake(0, 0, ofGetWindowWidth()/[UIScreen mainScreen].scale-0.1, ofGetWindowHeight()/[UIScreen mainScreen].scale-0.1);
    CGFloat xOffset = 0;
    #ifdef IS_IOS11orHIGHER
        UILayoutGuide* layoutGuide = [[UIApplication sharedApplication] keyWindow].safeAreaLayoutGuide;
        xOffset = layoutGuide.layoutFrame.origin.x;
    #endif
    CGRect frame = CGRectMake(-1 * xOffset, 0, xOffset + ofGetWindowWidth()/[UIScreen mainScreen].scale-0.1/* - xOffset*/, ofGetWindowHeight()/[UIScreen mainScreen].scale-0.1);
    
    ofxWebViewDelegateObjC *delegateObjC = [[ofxWebViewDelegateObjC alloc] init];
    [delegateObjC setDelegate:delegate]; // WARNING: is set to 0 when using default delegate - make sure to set delegate
    
    cout << "Initialized WKWebViewInterface" << endl;
    
    // Create the configuration with the user content controller
    WKUserContentController *userContentController = [WKUserContentController new];
    [userContentController addScriptMessageHandler:delegateObjC name:@"realityEditor"];

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaPlaybackRequiresUserAction = NO;
    configuration.requiresUserActionForMediaPlayback = NO;
    
    wkWebViewInstance = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    
    // set delegate
    [wkWebViewInstance setNavigationDelegate:delegateObjC];
    [wkWebViewInstance setUIDelegate:delegateObjC];
    
    // make it transparent
    [wkWebViewInstance setOpaque:NO];
    [wkWebViewInstance setBackgroundColor:[UIColor clearColor]];
    [wkWebViewInstance.window makeKeyAndVisible];
 
    
    // make it scrollable
    [[wkWebViewInstance scrollView] setScrollEnabled:NO];
    [[wkWebViewInstance scrollView] setBounces:NO];
    
    // create a static server with the interface as early as possible to reduce waiting time on start
    [WebServerManager sharedManager];
}

void ofxWebViewInterfaceJavaScript::loadInterfaceFromLocalServer() {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL* serverURL = [[WebServerManager sharedManager] getServerURL];

    [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:serverURL]];
}

void ofxWebViewInterfaceJavaScript::loadURL(string url) {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL *nsURL = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:[NSString defaultCStringEncoding]]];
    
    [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:nsURL]];
}

void ofxWebViewInterfaceJavaScript::loadLocalFile(string filename) {
    NSString *_filename = [NSString stringWithCString:filename.c_str() encoding:[NSString defaultCStringEncoding]];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:_filename ofType:@"html" inDirectory:@"userinterface"]];
    
    [wkWebViewInstance loadRequest:[NSURLRequest requestWithURL:url]];
}

void ofxWebViewInterfaceJavaScript::activateView() {
    if (!isShowingView) {
        [ofxiPhoneGetGLParentView() addSubview:wkWebViewInstance];
        isShowingView = true;
    }
}

void ofxWebViewInterfaceJavaScript::deactivateView() {
    if (isShowingView) {
        [wkWebViewInstance removeFromSuperview];
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
void ofxWebViewInterfaceJavaScript::runJavaScriptFromString(NSString *script) {
    if (isShowingView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [wkWebViewInstance evaluateJavaScript:script completionHandler:nil];
        });
    }
}

ofxWebViewInterfaceJavaScript::~ofxWebViewInterfaceJavaScript() {
    
}

#pragma mark - Debugging

void ofxWebViewInterfaceJavaScript::clearCache() {
    NSSet *dataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache,
                                             WKWebsiteDataTypeMemoryCache,
                                             ]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:dataTypes
                                               modifiedSince:[NSDate dateWithTimeIntervalSince1970:0]
                                           completionHandler:^{
                                           }];
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

