//
//  REJavaScriptAPIHandler.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//

#import "JavaScriptAPIHandler.h"
#import <UIKit/UIKit.h>
#import "ARManager.h"
#import "UDPManager.h"
#import "FileManager.h"
#import "SpeechManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <sys/utsname.h>

@implementation JavaScriptAPIHandler {
//    NSString* matrixStreamCallback;
    NSString* speechCallback;
    bool vuforiaRunning;
}

- (id)initWithDelegate:(id<JavaScriptCallbackDelegate>)newDelegate
{
    if (self = [super init]) {
        delegate = newDelegate;
    }
    return self;
}

#pragma mark -

// response with a callback that indicates the device name
- (void)getDeviceReady:(NSString *)callback
{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    
    NSString* deviceName = [NSString stringWithCString:systemInfo.machine
                                              encoding:NSUTF8StringEncoding];//[[UIDevice currentDevice] localizedModel];
    [delegate callJavaScriptCallback:callback withArguments:@[[NSString stringWithFormat:@"'%@'", deviceName]]];
}

// check if vuforia is ready and fires a callback once that's the case
- (void)getVuforiaReady:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267

    [[ARManager sharedManager] startARWithCompletionHandler:^{
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:nil]; // notify the javascript that vuforia has finished loading
    }];
}

// adds a new marker and fires a callback with error or success
- (void)addNewMarker:(NSString *)markerName callback:(NSString *)callback
{
    NSString* markerPath = [[FileManager sharedManager] getTempFilePath:markerName];
    bool success = [[ARManager sharedManager] addNewMarker:markerPath];
    NSString* successString = success ? @"true" : @"false";
    [delegate callJavaScriptCallback:callback withArguments:@[successString, [NSString stringWithFormat:@"'%@'", markerName]]];
}

- (void)getProjectionMatrix:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267
    
    [[ARManager sharedManager] getProjectionMatrixStringWithCompletionHandler:^(NSString *projectionMatrixString) {
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[projectionMatrixString]];
    }];
}

- (void)getMatrixStream:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267
    
    [[ARManager sharedManager] setMatrixCompletionHandler:^(NSArray *visibleMarkers) {
        
        NSString* javaScriptObject = @"{";
        
        // add each marker's name:matrix pair to the object
        if (visibleMarkers.count > 0) {
            for (int i = 0; i < visibleMarkers.count; i++) {
                NSDictionary* thisMarker = visibleMarkers[i];
                NSString* markerName = thisMarker[@"name"];
                NSString* markerMatrix = thisMarker[@"modelViewMatrix"];
                javaScriptObject = [javaScriptObject stringByAppendingString:[NSString stringWithFormat:@"'%@': %@,", markerName, markerMatrix]];
            }
            javaScriptObject = [javaScriptObject substringToIndex:javaScriptObject.length-1]; // remove last comma character before closing the object
        }
        javaScriptObject = [javaScriptObject stringByAppendingString:@"}"];
        
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[javaScriptObject]];
        
//        NSLog(@"Found object markers: %@", visibleMarkers);
    }];
}

- (void)getCameraMatrixStream:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267
    
    [[ARManager sharedManager] setCameraMatrixCompletionHandler:^(NSDictionary *cameraMarker) {
        NSString* cameraMatrix = cameraMarker[@"modelViewMatrix"];
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[cameraMatrix]];
    }];
}

- (void)getGroundPlaneMatrixStream:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267

    [[ARManager sharedManager] setGroundPlaneMatrixCompletionHandler:^(NSDictionary *groundPlaneMarker) {
        NSString* groundPlaneMatrix = groundPlaneMarker[@"modelViewMatrix"];
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[groundPlaneMatrix]];
    }];
}

// TODO: actually use size when getting screenshot
- (void)getScreenshot:(NSString *)size callback:(NSString *)callback
{
    UIImage* cameraImage = [[ARManager sharedManager] getCameraPixelBuffer];
    CGFloat imageWidth = cameraImage.size.width;
    CGFloat imageHeight = cameraImage.size.height;
    
    if ([size isEqualToString:@"S"]) {
        // rescale small => 1/4 size
        cameraImage = [self resizeImage:cameraImage newSize:CGSizeMake(imageWidth * 0.25, imageHeight * 0.25)];
    } else if ([size isEqualToString:@"M"]) {
        // rescale medium => 1/2 size
        cameraImage = [self resizeImage:cameraImage newSize:CGSizeMake(imageWidth * 0.50, imageHeight * 0.50)];
    } else { //if ([size isEqualToString:@"L"]) {
        // don't rescale
    }
    
    NSData *imageData = UIImageJPEGRepresentation(cameraImage, 1.0);
    NSString *encodedString = [NSString stringWithFormat:@"'%@'", [imageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn]];
    [delegate callJavaScriptCallback:callback withArguments:@[encodedString]];
}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)setPause
{
    [[ARManager sharedManager] pauseCamera];
}

- (void)setResume
{
    [[ARManager sharedManager] resumeCamera];
}

- (void)getUDPMessages:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267

    [[UDPManager sharedManager] setReceivedMessageCallback:^(NSString *message, NSString *address) {
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[[NSString stringWithFormat:@"'%@'", message]]];
    }];
}

- (void)sendUDPMessage:(NSString *)message
{
    [[UDPManager sharedManager] sendUDPMessage:message];
}

- (void)getFileExists:(NSString *)fileName callback:(NSString *)callback
{
    bool doesFileExist = [[FileManager sharedManager] getFileExists:fileName];
    NSString* successString = doesFileExist ? @"true" : @"false";
    [delegate callJavaScriptCallback:callback withArguments:@[successString]];
}

- (void)downloadFile:(NSString *)fileName callback:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267

    [[FileManager sharedManager] downloadFile:fileName withCompletionHandler:^(bool success) {
        NSString* successString = success ? @"true" : @"false";
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[successString, [NSString stringWithFormat:@"'%@'", fileName]]]; // remember to wrap string in quotes so it doesnt get evaluated
    }];
}

- (void)getFilesExist:(NSArray *)fileNameArray callback:(NSString *)callback
{
    bool allExist = [[FileManager sharedManager] getFilesExist:fileNameArray];
    
    NSString* successString = allExist ? @"true" : @"false"; // TODO: create reusable methods to get a javascript-safe version of each argument
    
    NSString* fileNameArrayString = @"["; // convert the NSArray into a string containing a JS array
    for (NSString* fileName in fileNameArray) {
        fileNameArrayString = [fileNameArrayString stringByAppendingString:[NSString stringWithFormat:@"'%@',", fileName]]; // add each filename in quotes
    }
    fileNameArrayString = [fileNameArrayString substringToIndex:[fileNameArrayString length]-1]; // remove last comma
    fileNameArrayString = [fileNameArrayString stringByAppendingString:@"]"];
    
    [delegate callJavaScriptCallback:callback withArguments:@[successString, fileNameArrayString]];
}

- (void)getChecksum:(NSArray *)fileNameArray callback:(NSString *)callback
{
    long checksum = [[FileManager sharedManager] getChecksum:fileNameArray];
    [delegate callJavaScriptCallback:callback withArguments:@[[NSString stringWithFormat:@"%li", checksum]]];
}

- (void)setStorage:(NSString *)storageID message:(NSString *)message
{
    [[FileManager sharedManager] setStorage:storageID message:message];
}

- (void)getStorage:(NSString *)storageID callback:(NSString *)callback
{
    NSString* message = [[FileManager sharedManager] getStorage:storageID];
    [delegate callJavaScriptCallback:callback withArguments:@[[NSString stringWithFormat:@"'%@'", message]]];
}

- (void)startSpeechRecording
{
    [[SpeechManager sharedManager] startRecording];
}

- (void)stopSpeechRecording
{
    [[SpeechManager sharedManager] stopRecording];
}

- (void)addSpeechListener:(NSString *)callback
{
    __block JavaScriptAPIHandler *blocksafeSelf = self; // https://stackoverflow.com/a/5023583/1190267

    [[SpeechManager sharedManager] addSpeechListener:^(NSString *transcription) {
        [blocksafeSelf->delegate callJavaScriptCallback:callback withArguments:@[[NSString stringWithFormat:@"'%@'", transcription]]];
    }];
}

- (void)tap
{
    if([[UIDevice currentDevice].model isEqualToString:@"iPhone"]) {
        AudioServicesPlaySystemSound (1519); // works ALWAYS as of this post
    } else {
        AudioServicesPlayAlertSound (1105); // Not an iPhone, so doesn't have vibrate, so play small tap noise
    }
}

- (void)focusCamera
{
    [[ARManager sharedManager] focusCamera];
}

- (void)tryPlacingGroundAnchorAtScreenX:(NSString *)normalizedScreenX screenY:(NSString *)normalizedScreenY withCallback:(NSString *)callback
{
    float x = [normalizedScreenX floatValue];
    float y = [normalizedScreenY floatValue];
    bool didSucceed = [(ARManager *)[ARManager sharedManager] tryPlacingGroundAnchorAtScreenX:x andScreenY:y];
    NSString* successString = didSucceed ? @"true" : @"false";
    [delegate callJavaScriptCallback:callback withArguments:@[successString]];
}

- (void)loadNewUI:(NSString *)reloadURL
{
    
}

- (void)clearCache
{
//    [self.webView clearCache];
}

// TODO: add authenticateTouch(?)

@end
