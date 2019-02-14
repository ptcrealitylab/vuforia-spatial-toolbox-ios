//
//  ViewController.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/2/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//

#import "MainViewController.h"
#import "REWebView.h"
#import "ARManager.h"

@implementation MainViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // set up web view
    
    self.webView = [[REWebView alloc] initWithDelegate:self];
    [self.webView loadInterfaceFromLocalServer];
    [self.view addSubview:self.webView];
    
    // set up javascript API handler
    
    self.apiHandler = [[JavaScriptAPIHandler alloc] initWithDelegate:self];
    
    // set this main view controller as the container for the AR view
    
    [[ARManager sharedManager] setContainingViewController:self];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"navigation did fail.... handle error by loading from local server...");
    [self.apiHandler setStorage:@"SETUP:EXTERNAL" message:nil];
    [self.webView loadInterfaceFromLocalServer];
}

- (void)viewDidAppear:(BOOL)animated {
    // listen for when the app is reopened from background to refresh the webView and reset other state
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppReopened)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
}

- (void)onAppReopened {
    // reset web view
    if (!self.webView.isLoading) {
        //        double delayInSeconds = 1.0;
        //        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        //        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //            // do something
        [self.webView reload];
        //        });
    }
    
    // TODO: reset AR manager, etc...
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - JavaScript API Implementation

- (void)handleCustomRequest:(NSDictionary *)messageBody {
    NSLog(@"Handle Request: %@", messageBody);
    
    NSString* functionName = messageBody[@"functionName"]; // required
    NSDictionary* arguments = messageBody[@"arguments"]; // optional
    NSString* callback = messageBody[@"callback"]; // optional
    
    if ([functionName isEqualToString:@"getDeviceReady"]) {
        [self.apiHandler getDeviceReady:callback];
        
    } else if ([functionName isEqualToString:@"getVuforiaReady"]) {
        [self.apiHandler getVuforiaReady:callback];
        
    } else if ([functionName isEqualToString:@"addNewMarker"]) {
        NSString* markerName = (NSString *)arguments[@"markerName"];
        [self.apiHandler addNewMarker:markerName callback:callback];
        
    } else if ([functionName isEqualToString:@"getProjectionMatrix"]) {
        [self.apiHandler getProjectionMatrix:callback];
        
    } else if ([functionName isEqualToString:@"getMatrixStream"]) {
        [self.apiHandler getMatrixStream:callback];
        
    } else if ([functionName isEqualToString:@"getCameraMatrixStream"]) {
        [self.apiHandler getCameraMatrixStream:callback];
        
    } else if ([functionName isEqualToString:@"getScreenshot"]) {
        NSString* size = (NSString *)arguments[@"size"];
        [self.apiHandler getScreenshot:size callback:callback];
        
    } else if ([functionName isEqualToString:@"setPause"]) {
        [self.apiHandler setPause];
        
    } else if ([functionName isEqualToString:@"setResume"]) {
        [self.apiHandler setResume];
        
    } else if ([functionName isEqualToString:@"getUDPMessages"]) {
        [self.apiHandler getUDPMessages:callback];
        
    } else if ([functionName isEqualToString:@"sendUDPMessage"]) {
        NSString* message = (NSString *)arguments[@"message"];
        [self.apiHandler sendUDPMessage:message];
        
    } else if ([functionName isEqualToString:@"getFileExists"]) {
        NSString* fileName = (NSString *)arguments[@"fileName"];
        [self.apiHandler getFileExists:fileName callback:callback];
        
    } else if ([functionName isEqualToString:@"downloadFile"]) {
        NSString* fileName = (NSString *)arguments[@"fileName"];
        [self.apiHandler downloadFile:fileName callback:callback];
        
    } else if ([functionName isEqualToString:@"getFilesExist"]) {
        NSArray* fileNameArray = (NSArray *)arguments[@"fileNameArray"];
        [self.apiHandler getFilesExist:fileNameArray callback:callback];
        
    } else if ([functionName isEqualToString:@"getChecksum"]) {
        NSArray* fileNameArray = (NSArray *)arguments[@"fileNameArray"];
        [self.apiHandler getChecksum:fileNameArray callback:callback];
        
    } else if ([functionName isEqualToString:@"setStorage"]) {
        NSString* storageID = (NSString *)arguments[@"storageID"];
        NSString* message = (NSString *)arguments[@"message"];
        [self.apiHandler setStorage:storageID message:message];
        
    } else if ([functionName isEqualToString:@"getStorage"]) {
        NSString* storageID = (NSString *)arguments[@"storageID"];
        [self.apiHandler getStorage:storageID callback:callback];
        
    } else if ([functionName isEqualToString:@"startSpeechRecording"]) {
        [self.apiHandler startSpeechRecording];
        
    } else if ([functionName isEqualToString:@"stopSpeechRecording"]) {
        [self.apiHandler stopSpeechRecording];
        
    } else if ([functionName isEqualToString:@"addSpeechListener"]) {
        [self.apiHandler addSpeechListener:callback];
        
    } else if ([functionName isEqualToString:@"memorize"]) {
        [self.apiHandler clearCache];
        
    } else if ([functionName isEqualToString:@"remember"]) {
        NSString* dataString = (NSString *)arguments[@"dataStr"];
        [self.apiHandler remember:dataString];
        
    } else if ([functionName isEqualToString:@"tap"]) {
        [self.apiHandler tap];
        
    } else if ([functionName isEqualToString:@"loadNewUI"]) {
        NSString* reloadURL = (NSString *)arguments[@"reloadURL"];
        //        [self.apiHandler loadNewUI:reloadURL];
        [self.webView loadInterfaceFromURL:reloadURL];
        
    } else if ([functionName isEqualToString:@"clearCache"]) {
        //        [self.apiHandler clearCache];
        [self.webView clearCache]; // currently apiHandler doesnt have a reference to webView
    }
}

#pragma mark - WKScriptMessageHandler Protocol Implementation

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    [self handleCustomRequest: message.body];
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
//        NSLog(@"Calling JavaScript callback: %@", callback);
        [self.webView runJavaScriptFromString:callback];
    }
}

@end
