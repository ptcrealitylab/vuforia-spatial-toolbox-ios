//
//  ofxWebViewDelegate.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 3/9/16.
//
//

#include "ofxWebViewDelegate.h"

@implementation ofxWebViewDelegateObjC

#pragma mark - Common Methods to UIWebView and WKWebView

- (void)handleRequest:(NSURLRequest *)request {
    BOOL isDefaultRequest = false;
    
    // TODO: Use pathComponents instead of host to get variables.
    if ([[request.URL host] isEqual:@"printSomething"]) {
        NSLog(@"Test print.\n");
        isDefaultRequest = true;
    }
    
    if (!isDefaultRequest && [self delegate] != 0) [self delegate]->handleCustomRequest([request.URL host], request.URL);
}

#pragma mark - WKWebView Delegate Methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([[navigationAction.request.URL scheme] isEqualToString:@"of"]) {
        [self handleRequest: navigationAction.request];
        // tell WKWebView NOT to load URL (instead we handle message)
        return decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        // tell WKWebView to load URL
        return decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - UIWebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL scheme] isEqual:@"of"]) {
        [self handleRequest:request];
        // tell UIWebView NOT to load URL (instead we handle message)
        return NO;
    } else {
        // tell UIWebView to load URL
        return YES;
    }
}

@end
