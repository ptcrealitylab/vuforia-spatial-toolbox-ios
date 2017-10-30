/**
 * @preserve
 *
 *                                      .,,,;;,'''..
 *                                  .'','...     ..',,,.
 *                                .,,,,,,',,',;;:;,.  .,l,
 *                               .,',.     ...     ,;,   :l.
 *                              ':;.    .'.:do;;.    .c   ol;'.
 *       ';;'                   ;.;    ', .dkl';,    .c   :; .'.',::,,'''.
 *      ',,;;;,.                ; .,'     .'''.    .'.   .d;''.''''.
 *     .oxddl;::,,.             ',  .'''.   .... .'.   ,:;..
 *      .'cOX0OOkdoc.            .,'.   .. .....     'lc.
 *     .:;,,::co0XOko'              ....''..'.'''''''.
 *     .dxk0KKdc:cdOXKl............. .. ..,c....
 *      .',lxOOxl:'':xkl,',......'....    ,'.
 *           .';:oo:...                        .
 *                .cd,      ╔═╗┌┬┐┬┌┬┐┌─┐┬─┐    .
 *                  .l;     ║╣  │││ │ │ │├┬┘    '
 *                    'l.   ╚═╝─┴┘┴ ┴ └─┘┴└─   '.
 *                     .o.                   ...
 *                      .''''','.;:''.........
 *                           .'  .l
 *                          .:.   l'
 *                         .:.    .l.
 *                        .x:      :k;,.
 *                        cxlc;    cdc,,;;.
 *                       'l :..   .c  ,
 *                       o.
 *                      .,
 *
 *      ╦═╗┌─┐┌─┐┬  ┬┌┬┐┬ ┬  ╔═╗┌┬┐┬┌┬┐┌─┐┬─┐  ╔═╗┬─┐┌─┐ ┬┌─┐┌─┐┌┬┐
 *      ╠╦╝├┤ ├─┤│  │ │ └┬┘  ║╣  │││ │ │ │├┬┘  ╠═╝├┬┘│ │ │├┤ │   │
 *      ╩╚═└─┘┴ ┴┴─┘┴ ┴  ┴   ╚═╝─┴┘┴ ┴ └─┘┴└─  ╩  ┴└─└─┘└┘└─┘└─┘ ┴
 *
 *
 * Created by Benjamin Reynolds on 7/14/16.
 *
 * Copyright (c) 2015 Valentin Heun
 *
 * All ascii characters above must be included in any redistribution.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

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

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
//    NSDictionary* dict = message.body;
//    NSLog(@"message body: %@", dict);
//    
//    NSString* functionName = message.body[@"functionName"];
    
    if ([self delegate] != 0) {
        [self delegate]->handleJavaScriptFunction(message.body);
    }
    
//    [self.delegate performSelector:@selector(functionName)];
    
//    NSString *callBackString = message.body;
//    callBackString = [@"(" stringByAppendingString:callBackString];
//    callBackString = [callBackString stringByAppendingFormat:@")('%@');", @"Some RetString"];
//    [message.webView evaluateJavaScript:callBackString completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"name = %@ error = %@",@"", error.localizedDescription);
//        }
//    }];
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
