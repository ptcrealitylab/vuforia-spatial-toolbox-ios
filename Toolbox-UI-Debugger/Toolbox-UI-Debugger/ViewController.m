//
//  ViewController.m
//  Toolbox-UI-Debugger
//
//  Created by Benjamin Reynolds on 4/3/20.
//  Copyright © 2020 Reality Lab. All rights reserved.
//

// Instructions: When you change the simulator, change this string to match the targeted device
#define DEVICE_NAME @"iPhone11,2"

#import "ViewController.h"
#import "REWebViewSimplified.h"
#import <sys/utsname.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.webView = [[REWebViewSimplified alloc] initWithDelegate:self];
    
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
    
    if ([functionName isEqualToString:@"getDeviceReady"]) {
        
        // This method doesn't work on the simulator so we manually use the DEVICE_NAME constant instead
        /*
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString* deviceName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        */
        
        NSString* deviceName = DEVICE_NAME;
        
        [self callJavaScriptCallback:callback withArguments:@[[NSString stringWithFormat:@"'%@'", deviceName]]];
    }
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

- (void)callJavaScriptCallback:(NSString *)callback withArguments:(NSArray *)arguments
{
    if (callback) {
        if (arguments && arguments.count > 0) {
            for (int i=0; i < arguments.count; i++) {
                callback = [callback stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"__ARG%i__", (i+1)] withString:arguments[i]];
            }
        }
        NSLog(@"Calling JavaScript callback: %@", callback);
        [self.webView runJavaScriptFromString:callback];
    }
}

@end
