//
//  ofxUIWebViewDelegate.m
//  ofxiPhoneWebViewController
//
//  Created by Fluid Interfaces Group on 11/8/13.
//
//

#import "ofxUIWebViewDelegate.h"

@implementation ofxUIWebViewDelegateObjC

- (void)webViewDidStartLoad:(UIWebView *)webView {
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    if ([[request.URL scheme] isEqual:@"of"]) {
        [self handleRequest:request];
        return NO; // tell UIWebView NOT to load URL
    } else {
        return YES; // tell UIWebView to load URL
    }
}

- (void)handleRequest:(NSURLRequest *)request {
    BOOL isDefaultRequest = false;

    // TODO: Use pathComponents instead of host to get variables.
    if ([[request.URL host] isEqual:@"printSomething"]) {
        NSLog(@"Test print.\n");
        isDefaultRequest = true;
    }

    if (!isDefaultRequest && [self delegate] != 0) [self delegate]->handleCustomRequest([request.URL host]);
}

@end
