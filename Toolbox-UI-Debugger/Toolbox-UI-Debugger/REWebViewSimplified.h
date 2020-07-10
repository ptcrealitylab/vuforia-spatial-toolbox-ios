//
//  REWebViewSimplified.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This is a modified version of REWebView.h, which removes all references to the Node.js server
// as that server is unnecessary for debugging layout of the app UI

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface REWebViewSimplified : WKWebView

- (id)initWithDelegate:(id<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>)delegate;
- (void)loadInterfaceFromURL:(NSString *)urlString;
- (void)runJavaScriptFromString:(NSString *)script;
- (void)clearCache;

@end
