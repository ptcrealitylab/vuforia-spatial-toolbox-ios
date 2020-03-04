//
//  ViewController.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
//#import "ImageTargetsEAGLView.h"
//#import "SampleApplicationSession.h"
//#import "GCDAsyncUdpSocket.h"
#import "JavaScriptAPIHandler.h"

@class REWebView;

@interface MainViewController : UIViewController <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, JavaScriptCallbackDelegate>

@property (nonatomic, strong) REWebView* webView;
@property (nonatomic, strong) JavaScriptAPIHandler* apiHandler;
@property (nonatomic) BOOL callbacksEnabled;

@end

