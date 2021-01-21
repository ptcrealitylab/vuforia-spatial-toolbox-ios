//
//  REWebView.m
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This is a customized WKWebView that initializes with correct configurations for the Reality Editor userinterface,
// loads its interface from a self-hosted local HTTP server, and knows how to handle JS <-> Objective-C messages

#import "REWebView.h"
#import <objc/runtime.h>

@implementation REWebView

// creates a customized web view for the Reality Editor with fullscreen size, clear background, no scroll,
// and sets a delegate to handle script messages sent to the iOS code from JavaScript
- (id)initWithDelegate:(id<WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>)delegate
{
    // automatically make it fullscreen
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    // initialize the UIWebView instance

//    CGFloat xOffset = 0;
//#ifdef IS_IOS11orHIGHER
//    UILayoutGuide* layoutGuide = [[UIApplication sharedApplication] keyWindow].safeAreaLayoutGuide;
//    xOffset = layoutGuide.layoutFrame.origin.x;
//#endif
//
//    frame = CGRectMake(-1 * xOffset, 0, xOffset + [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);

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
        [self setAllowsLinkPreview:NO];
        [self setAllowsBackForwardNavigationGestures:NO];

        // make it scrollable
        [[self scrollView] setScrollEnabled:NO];
        [[self scrollView] setBounces:NO];
        [REWebView allowDisplayingKeyboardWithoutUserAction];

        // start the web server singleton as soon as possible to minimize loading times
        [self initializeWebServer];
        
        NSLog(@"Initialized REWebView");
    }
    return self;
}

// Allows javascript to programmatically open the keyboard without explicitly tapping on a native text field element (disabled by default)
// Non-intuitive solution, taken from https://stackoverflow.com/a/48623286/1190267 (updated for iOS 12 and 13 as of 3-4-2020)
+ (void)allowDisplayingKeyboardWithoutUserAction {
    Class thisClass = NSClassFromString(@"WKContentView");
    NSOperatingSystemVersion iOS_11_3_0 = (NSOperatingSystemVersion){11, 3, 0};
    NSOperatingSystemVersion iOS_12_2_0 = (NSOperatingSystemVersion){12, 2, 0};
    NSOperatingSystemVersion iOS_13_0_0 = (NSOperatingSystemVersion){13, 0, 0};
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_13_0_0]) {
        SEL selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:");
        Method method = class_getInstanceMethod(thisClass, selector);
        IMP original = method_getImplementation(method);
        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
        ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
        method_setImplementation(method, override);
    }
   else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_12_2_0]) {
        SEL selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
        Method method = class_getInstanceMethod(thisClass, selector);
        IMP original = method_getImplementation(method);
        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
        ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
        method_setImplementation(method, override);
    }
    else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_11_3_0]) {
        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
        Method method = class_getInstanceMethod(thisClass, selector);
        IMP original = method_getImplementation(method);
        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
        method_setImplementation(method, override);
    } else {
        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
        Method method = class_getInstanceMethod(thisClass, selector);
        IMP original = method_getImplementation(method);
        IMP override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, id arg3) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3);
        });
        method_setImplementation(method, override);
    }
}

// override the safe area inserts for iPhoneX fullscreen
// https://stackoverflow.com/questions/47244002/make-wkwebview-real-fullscreen-on-iphone-x-remove-safe-area-from-wkwebview
// https://stackoverflow.com/questions/51547468/override-safeareainsets-for-wkwebview-in-objective-c?noredirect=1&lq=1
- (UIEdgeInsets)safeAreaInsets {
    return UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
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
    if (urlString.length == 0) {
        [self loadInterfaceFromLocalServer];
        return;
    }
    if (![urlString containsString:@"http://"]) {
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
    }
    urlString = [urlString stringByReplacingOccurrencesOfString:@"\"" withString:@""]; // remove any quotes from the string that may have been added during storage encoding
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self clearCache];
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
