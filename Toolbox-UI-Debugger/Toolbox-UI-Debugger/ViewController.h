//
//  ViewController.h
//  Toolbox-UI-Debugger
//
//  Created by Benjamin Reynolds on 4/3/20.
//  Copyright © 2020 Reality Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class REWebViewSimplified;

@interface ViewController : UIViewController<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) REWebViewSimplified* webView;

@end

