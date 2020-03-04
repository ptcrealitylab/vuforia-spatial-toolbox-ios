//
//  REWebView.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 PTC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#include "WebServerManager.h"

@interface REWebView : WKWebView

- (id)initWithDelegate:(id<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>)delegate;
- (void)loadInterfaceFromLocalServer;
- (void)loadInterfaceFromURL:(NSString *)urlString;
- (void)runJavaScriptFromString:(NSString *)script;
- (void)clearCache;

@end
