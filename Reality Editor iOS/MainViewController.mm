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
#import "FileManager.h"
#import "VideoRecordingManager.h"

@implementation MainViewController
{
    UILabel* loadingLabel;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)viewDidLoad {
    
    AVCaptureDevice *captureDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    NSArray* availFormat=captureDevice.formats;
    NSLog(@"%@",availFormat);
    
    [super viewDidLoad];
    
    // set up web view
    
    self.webView = [[REWebView alloc] initWithDelegate:self];
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    
    // TODO: check if there's an extenal URL saved
    NSString* savedInterfaceURL = [[FileManager sharedManager] getStorage:@"SETUP:EXTERNAL"];
    NSLog(@"Saved external state: %@", savedInterfaceURL);
    if (savedInterfaceURL != NULL) {
        [self.webView loadInterfaceFromURL:savedInterfaceURL];
        // TODO: show loading countdown
    } else {
        [self.webView loadInterfaceFromLocalServer];
    }
    
    [self performSelector:@selector(checkLoadingForTimeout) withObject:nil afterDelay:10.0f];
    
    [self.view addSubview:self.webView];
    
    [self showLoadingLabel];
    
    // set up javascript API handler
    
    self.apiHandler = [[JavaScriptAPIHandler alloc] initWithDelegate:self];
    
    // set this main view controller as the container for the AR view
    
    [[ARManager sharedManager] setContainingViewController:self];
    
    // preload the video recording manager and assign it the AR manager as a delegate to get the camera information
    [[VideoRecordingManager sharedManager] setVideoRecordingDelegate:[ARManager sharedManager]];
}

- (void)showLoadingLabel
{
    [[self getLoadingLabel] setHidden:NO];
    [self.view bringSubviewToFront:[self getLoadingLabel]];
}

- (void)hideLoadingLabel
{
    [[self getLoadingLabel] setHidden:YES];
}

- (UILabel *)getLoadingLabel
{
    if (loadingLabel == nil) {
        loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 200, 30)];
        [loadingLabel setText:@"Loading..."];
        [loadingLabel setTextColor:[UIColor whiteColor]];
        [self.view addSubview:loadingLabel];
    }
    return loadingLabel;
}

- (void)checkLoadingForTimeout
{
    NSLog(@"Check if loading did timeout...");
    NSLog(@"Is Web View loading? %@", (self.webView.loading ? @"TRUE" : @"FALSE"));
    NSLog(@"Web View URL: %@", self.webView.URL);
    
    if (self.webView.URL == NULL || self.webView.loading) {
        
        // reset the saved state and reload the interface from default server location
        [[FileManager sharedManager] setStorage:@"SETUP:EXTERNAL" message:NULL];
        [self.webView loadInterfaceFromLocalServer];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        bool oldLoading = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
        bool newLoading = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];

        // disable callbacks anytime the webview is loading and re-enable whenever it finishes
        if (newLoading && !oldLoading) {
            self.callbacksEnabled = false;
            
            [self showLoadingLabel];
            
        } else if (!newLoading && oldLoading) {
            self.callbacksEnabled = true;
            
            [self hideLoadingLabel];
            
            NSLog(@"done loading... %@", self.webView.URL);
            if (self.webView.URL) {
                NSLog(@"Successfully loaded userinterface");
            } else {
                NSLog(@"Couldn't load userinterface. Try loading from local server.");
                
                // reset the saved state and reload the interface from default server location
                [[FileManager sharedManager] setStorage:@"SETUP:EXTERNAL" message:NULL];
                [self.webView loadInterfaceFromLocalServer];
            }
        }
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"navigation did fail.... handle error by loading from local server...");
    [self.apiHandler setStorage:@"SETUP:EXTERNAL" message:nil];
    [self.webView loadInterfaceFromLocalServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - JavaScript API Implementation

- (void)handleCustomRequest:(NSDictionary *)messageBody {
//    NSLog(@"Handle Request: %@", messageBody);
    
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
        
    } else if ([functionName isEqualToString:@"getGroundPlaneMatrixStream"]) {
        [self.apiHandler getGroundPlaneMatrixStream:callback];

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
        
    } else if ([functionName isEqualToString:@"startVideoRecording"]) {
        NSString* objectKey = (NSString *)arguments[@"objectKey"];
        NSString* objectIP = (NSString *)arguments[@"objectIP"];
        [self.apiHandler startVideoRecording:objectKey ip:objectIP];
        
    } else if ([functionName isEqualToString:@"stopVideoRecording"]) {
        NSString* videoId = (NSString *)arguments[@"videoId"];
        [self.apiHandler stopVideoRecording:videoId];
        
    } else if ([functionName isEqualToString:@"tap"]) {
        [self.apiHandler tap];
        
    } else if ([functionName isEqualToString:@"tryPlacingGroundAnchor"]) {
        NSString* normalizedScreenX = (NSString *)arguments[@"normalizedScreenX"];
        NSString* normalizedScreenY = (NSString *)arguments[@"normalizedScreenY"];
        [self.apiHandler tryPlacingGroundAnchorAtScreenX:normalizedScreenX screenY:normalizedScreenY withCallback:callback];

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
//    if (!self.callbacksEnabled) return;

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
