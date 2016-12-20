//
//  ofxWKWebViewDelegate.cpp
//  RealityEditor
//
//  Created by Fluid Interfaces Group on 2/22/16.
//
//

#include "ofxWKWebViewDelegate.h"

@implementation ofxWKWebViewDelegateObjC

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlScheme = [navigationAction.request.URL scheme];
    NSLog(@"Decide policy for navigation action: %@", urlScheme);

    if ([urlScheme isEqualToString:@"of"]) {
        [self handleRequest: navigationAction.request];
        return decisionHandler(WKNavigationActionPolicyCancel); // tell WKWebView NOT to load URL (instead we handle message)
    } else {
        return decisionHandler(WKNavigationActionPolicyAllow); // tell WKWebView to load URL
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSDictionary *sentData = (NSDictionary *)message.body;
    NSString *messageString = sentData[@"message"];
    NSLog(@"Message received: %@", messageString);
}

- (void)handleRequest:(NSURLRequest *)request {
    BOOL isDefaultRequest = false;
    
    // TODO: Use pathComponents instead of host to get variables.
    if ([[request.URL host] isEqual:@"printSomething"]) {
        NSLog(@"Test print.\n");
        isDefaultRequest = true;
    }
    
    if (!isDefaultRequest && [self delegate] != 0) [self delegate]->handleCustomRequest([request.URL host], request.URL);
}

@end