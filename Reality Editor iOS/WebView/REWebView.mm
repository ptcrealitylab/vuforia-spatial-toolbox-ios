//
//  REWebView.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//
// This is a customized WKWebView that initializes with correct configurations for the Reality Editor userinterface,
// loads its interface from a self-hosted local HTTP server, and knows how to handle JS <-> Objective-C messages

#import "REWebView.h"

@implementation REWebView

// creates a customized web view for the Reality Editor with fullscreen size, clear background, no scroll,
// and sets a delegate to handle script messages sent to the iOS code from JavaScript
- (id)initWithDelegate:(id<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>)delegate
{
    // automatically make it fullscreen
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    // Create the configuration with the user content controller
    WKUserContentController *userContentController = [WKUserContentController new];
    [userContentController addScriptMessageHandler:delegate name:@"realityEditor"];
    
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    configuration.allowsInlineMediaPlayback = YES;
    configuration.requiresUserActionForMediaPlayback = NO;
    
    if (self = [super initWithFrame:frame configuration:configuration]) {

        // set delegate
        [self setNavigationDelegate:delegate];
        [self setUIDelegate:delegate];
        
        // make it transparent
        [self setOpaque:NO];
        [self setBackgroundColor:[UIColor clearColor]];
        [self.window makeKeyAndVisible];
        
        // make it scrollable
        [[self scrollView] setScrollEnabled:NO];
        [[self scrollView] setBounces:NO];
        
        // start the web server singleton as soon as possible to minimize loading times
        [self initializeWebServer];
        
        NSLog(@"Initialized REWebView");
    }
    return self;
}

// create a static server with the interface
// this doesn't need to be called separately, because as a singleton it will be intialized when first used,
// but we should call this as early as possible to reduce waiting time when loading the web contents
- (void) initializeWebServer
{
    [WebServerManager sharedManager];
}

// we host the files on a static HTTP server within the iOS app to allow cross-origin access within iframes and local files
- (void)loadInterfaceFromLocalServer
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL* serverURL = [[WebServerManager sharedManager] getServerURL];
    
//    [self loadRequest:[NSURLRequest requestWithURL:serverURL]];
    [self loadRequest:[NSURLRequest requestWithURL:serverURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]];
}

- (void)loadInterfaceFromURL:(NSString *)urlString
{
    if (![urlString containsString:@"http://"]) {
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
//    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]];
}

// calls the javascript string on the window (global context) of the webview contents
- (void)runJavaScriptFromString:(NSString *)script
{
    // strip out newlines to prevent Unexpected EOF error
    script = [script stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    script = [script stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self evaluateJavaScript:script completionHandler:nil];
    });
}

// this can be used to force the webview to reload the source files in case they don't update when developing
- (void)clearCache
{
    NSSet *dataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeDiskCache,WKWebsiteDataTypeMemoryCache,]];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:dataTypes
                                               modifiedSince:[NSDate dateWithTimeIntervalSince1970:0]
                                           completionHandler:^{}];
}

@end
