//
//  ViewController.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
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

@end

