//
//  ViewController.m
//  Toolbox-UI-Debugger
//
//  Created by Benjamin Reynolds on 4/3/20.
//  Copyright © 2020 Reality Lab. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    // Create the configuration with the user content controller
    WKUserContentController *userContentController = [WKUserContentController new];
    [userContentController addScriptMessageHandler:self name:@"realityEditor"];
    
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    configuration.allowsInlineMediaPlayback = YES;
    configuration.requiresUserActionForMediaPlayback = NO;

    self.webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    
//    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    
    // set delegate
    [self.webView setNavigationDelegate:self];
    [self.webView setUIDelegate:self];
    
    // make it transparent
    [self.webView setOpaque:NO];
    [self.webView setBackgroundColor:[UIColor clearColor]];
    [self.webView.window makeKeyAndVisible];
    
    // make it scrollable
    [[self.webView scrollView] setScrollEnabled:NO];
    [[self.webView scrollView] setBounces:NO];
//    [REWebView allowDisplayingKeyboardWithoutUserAction];

    // start the web server singleton as soon as possible to minimize loading times
//    [self initializeWebServer];
    
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:@"userinterface"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.view addSubview:self.webView];
}

#pragma mark - JavaScript API Implementation

- (void)handleCustomRequest:(NSDictionary *)messageBody {
//    NSLog(@"Handle Request: %@", messageBody);
    
    NSString* functionName = messageBody[@"functionName"]; // required
    NSDictionary* arguments = messageBody[@"arguments"]; // optional
    NSString* callback = messageBody[@"callback"]; // optional

    NSLog(@"Received custom request: %@", functionName);
}

#pragma mark - WKScriptMessageHandler Protocol Implementation

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self handleCustomRequest: message.body];
}

#pragma mark - WKNavigaionDelegate Protocol Implementaion

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (navigationAction.request.URL) {
            NSLog(@"%@", navigationAction.request.URL.host);
            if ([navigationAction.request.URL.resourceSpecifier containsString:@"spatialtoolbox.vuforia.com"] ||
                [navigationAction.request.URL.resourceSpecifier containsString:@"github.com"]) {
                if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
                    [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
                    decisionHandler(WKNavigationActionPolicyCancel);
                }
            } else {
                decisionHandler(WKNavigationActionPolicyAllow);
            }
        }
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - JavaScriptCallbackDelegate Protocol Implementation

//- (void)callJavaScriptCallback:(NSString *)callback withArguments:(NSArray *)arguments
//{
////    if (!self.callbacksEnabled) return;
//
//    if (callback) {
//        if (arguments && arguments.count > 0) {
//            for (int i=0; i < arguments.count; i++) {
//                callback = [callback stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"__ARG%i__", (i+1)] withString:arguments[i]];
//            }
//        }
////        NSLog(@"Calling JavaScript callback: %@", callback);
//        [self.webView runJavaScriptFromString:callback];
//    }
//}

@end
