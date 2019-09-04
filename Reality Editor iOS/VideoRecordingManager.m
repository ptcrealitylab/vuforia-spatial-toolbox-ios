//
//  VideoRecordingManager.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 5/8/19.
//  Copyright © 2019 Reality Lab. All rights reserved.
//

#import "VideoRecordingManager.h"
#import "FileManager.h"
//#import "ARManager.h"
//#import <CoreVideo/CoreVideo.h>

#define temporaryDirectory NSTemporaryDirectory()

@implementation VideoRecordingManager
{
    BOOL isRecording;
    CFTimeInterval recordingStartTime;
    NSTimer* updateTimer;
}

+ (id)sharedManager
{
    static VideoRecordingManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

//- (id) initWithDelegate:(id<SampleApplicationControl>)delegate
//{
//    self = [super init];
//    if (self)
//    {
//        self.delegate = delegate;
//
//        // we keep a reference of the instance in order to implement the Vuforia callback
//        mInstance = self;
//    }
//    return self;
//}

// Source: https://github.com/anthonya1999/ReplayKit-iOS11-Recorder/blob/master/ReplayKit-iOS11-Recorder/ViewController.m
/*
- (void)startRecordingWithAR:(NSString *)objectKey ip:(NSString *)objectIP
{
    NSError *error = nil;
    
    // generates a random filename and saves to temp file directory before uploading to server
    NSString *videoOutPath = [temporaryDirectory stringByAppendingPathComponent:[[NSString stringWithFormat:@"%u", arc4random() % 1000] stringByAppendingPathExtension:@"mp4"]];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
//    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264BaselineAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
//                                            AVVideoAverageBitRateKey       : @(1920 * 1080 * 11.4),
                                            AVVideoAverageBitRateKey       : @(640 * 360 * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};

    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : @640, //@1920,
                                    AVVideoHeightKey                : @360}; //@1080};

    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    [self.assetWriter addInput:self.assetWriterInput];
    [self.assetWriterInput setMediaTimeScale:60];
    [self.assetWriter setMovieTimeScale:60];
    [self.assetWriterInput setExpectsMediaDataInRealTime:YES];
    
    self.screenRecorder = [RPScreenRecorder sharedRecorder];
    
    [self.screenRecorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
        if (CMSampleBufferDataIsReady(sampleBuffer)) {
            if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            }
            
            if (self.assetWriter.status == AVAssetWriterStatusFailed) {
                NSLog(@"An error occured.");
                return;
            }
            
            if (bufferType == RPSampleBufferTypeVideo) {
                if (self.assetWriterInput.isReadyForMoreMediaData) {
                    [self.assetWriterInput appendSampleBuffer:sampleBuffer];
                }
            }
        }
    } completionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Recording started successfully.");
            
            // save the object ID and IP so we can upload to correct server when it finishes
            self.objectID = objectKey;
            self.objectIP = objectIP;
        }
    }];
}
*/

- (void)startRecording:(NSString *)objectKey ip:(NSString *)objectIP
{
    if (isRecording) {
        NSLog(@"Can't record until first finishes ... already recording");
        return;
    }
    
    NSError *error = nil;

    // generates a random filename and saves to temp file directory before uploading to server
    NSString *videoOutPath = [temporaryDirectory stringByAppendingPathComponent:[[NSString stringWithFormat:@"%u", arc4random() % 1000] stringByAppendingPathExtension:@"mp4"]];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264BaselineAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            //                                            AVVideoAverageBitRateKey       : @(1920 * 1080 * 11.4),
                                            AVVideoAverageBitRateKey       : @(640 * 360 * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};
    
    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : @640, //@1920,
                                    AVVideoHeightKey                : @360}; //@1080};
    
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    [self.assetWriterInput setMediaTimeScale:60];
    [self.assetWriter setMovieTimeScale:60];
    [self.assetWriterInput setExpectsMediaDataInRealTime:YES];
    
//    NSDictionary *pixelBufferAttributes = @{kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA,
//                                    kCVPixelBufferWidthKey                 : @640, //@1920,
//                                    kCVPixelBufferHeightKey                : @360}; //@1080};
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];

    
    self.assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];

//AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                        //                               sourcePixelBufferAttributes: pixelBufferAttributes)
    
    [self.assetWriter addInput:self.assetWriterInput];
    
    recordingStartTime = CACurrentMediaTime();
//    CMTime presentationTime = CMTimeMakeWithSeconds(recordingStartTime, 240);
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero]; //presentationTime]; //CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    
    isRecording = true;
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.0833 // 12 fps
                                     target:self
                                   selector:@selector(writeFrame)
                                   userInfo:nil
                                    repeats:YES];
    
    NSLog(@"Recording started successfully.");
    // save the object ID and IP so we can upload to correct server when it finishes
    self.objectID = objectKey;
    self.objectIP = objectIP;
    
    EAGLContext* writerContext = [self.videoRecordingDelegate getVideoBackgroundContext];
    [EAGLContext setCurrentContext:writerContext]; // not sure if I have to do this
//    [self createDataFBOUsingGPUImagesMethod];

}

- (void)writeFrame
{
    if (!isRecording) {
        return;
    }
    
    CFTimeInterval frameTime = CACurrentMediaTime() - recordingStartTime;
    
    if (!self.assetWriterInput.readyForMoreMediaData) {
        NSLog(@"adaptor not ready %f\n", frameTime);
        return;
    }
    
    //print out status:
    NSLog(@"Processing video frame (%f)", frameTime);
    
//    UIImage* cameraBackground = [[ARManager sharedManager] getCameraPixelBuffer];
    UIImage* cameraBackground = [self.videoRecordingDelegate getCameraPixelBuffer];
    
//    CVPixelBufferRef backgroundPixelBuffer = [self.videoRecordingDelegate getBackgroundPixelBuffer];
//    NSLog(@"backgroundPixelBuffer: %@", backgroundPixelBuffer);
    
    GLchar* pixels;
    pixels = [self.videoRecordingDelegate getVideoBackgroundPixels];
    
    for (int i = 0; i < 10; i++ ) {
        NSLog(@"background pixels: *(pixels + %d) : %d\n", i, *(pixels + i));
    }
    
//    NSLog(@"background pixels: %f", sizeof(pixels));

    // Create a dummy pixel buffer to try the encoding
    // on something simple.
    CVPixelBufferRef pixelBuffer = NULL;
    
    
//    //----------------------------------------------------------
//    // check if texture cache is enabled,
//    // if so, use the pixel buffer from the texture cache.
//    //----------------------------------------------------------
//
//    if(bUseTextureCache == YES) {
//        pixelBuffer = _textureCachePixelBuffer;
//        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    }
    

    /*
    if (kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer,
                                                         kCVPixelBufferLock_ReadOnly))
    {
        CVPixelBufferPoolRef pixelBufferPool = self.assetWriterPixelBufferInput.pixelBufferPool;
        if (!pixelBufferPool) {
            NSLog(@"Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame");
            return;
        }
        
//        CVPixelBufferRef writerPixelBuffer = NULL;
        GLboolean status = CVPixelBufferPoolCreatePixelBuffer(NULL, self.assetWriterPixelBufferInput.pixelBufferPool, &pixelBuffer);
        
        if (status != kCVReturnSuccess) {
            NSLog(@"Could not get pixel buffer from asset writer input; dropping frame...");
            return;
        }
        
        uint8_t *pixelBufferBytes = (uint8_t *) CVPixelBufferGetBaseAddress(pixelBuffer);
        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        uint8_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
//        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        
//        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        CMTime presentationTime = CMTimeMakeWithSeconds(frameTime, 240);

        // process pixels how you like!
        BOOL success = [self.assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer
                                                      withPresentationTime:presentationTime];
        NSLog(@"wrote at %@ : %@", CMTimeCopyDescription(NULL, presentationTime), success ? @"YES" : @"NO");
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
     */
    
    
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
//                                          kCVPixelFormatType_32BGRA, NULL, &pixelBuffer);
//    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
    
    pixelBuffer = [self pixelBufferFromCGImage:[cameraBackground CGImage]];
    
//    CMTime frameTime = CMTimeSubtract(CACurrentMediaTime(), recordingStartTime);

    CMTime presentationTime = CMTimeMakeWithSeconds(frameTime, 240);
    
    BOOL append_ok = NO;
    
    append_ok = [self.assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
    if (!append_ok) {
        NSError *error = self.assetWriter.error;
        if (error != nil) {
            NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
        }
    }
     
    
    
//    [self.assetWriterInput appen]
    
//    while !assetWriterVideoInput.isReadyForMoreMediaData {}
    
//    guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
//        print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
//        return
//    }
    
//    var maybePixelBuffer: CVPixelBuffer? = nil
//    let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
//    if status != kCVReturnSuccess {
//        print("Could not get pixel buffer from asset writer input; dropping frame...")
//        return
//    }
//
//    guard let pixelBuffer = maybePixelBuffer else { return }
//
//    CVPixelBufferLockBaseAddress(pixelBuffer, [])
//    let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!
//
//
//    // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
//    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
//
//    texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
//
//
//    CFTimeInterval frameTime = CACurrentMediaTime() - recordingStartTime;
//    let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 240)
//
//    CVBufferSetAttachment(pixelBuffer, kCVImageBufferAlphaChannelModeKey, kCVImageBufferAlphaChannelMode_PremultipliedAlpha, .shouldPropagate)
//
//
//    assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
//
//
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
}

//////////////////////////
//- (CVPixelBufferRef) pixelBufferFromTexture: (CGImageRef) image {
//
//    CGSize size = CGSizeMake(1536, 828);
//
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
//                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
//                             nil];
//    CVPixelBufferRef pxbuffer = NULL;
//
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                          size.width,
//                                          size.height,
//                                          kCVPixelFormatType_32ARGB,
//                                          (__bridge CFDictionaryRef) options,
//                                          &pxbuffer);
//    if (status != kCVReturnSuccess){
//        NSLog(@"Failed to create pixel buffer");
//    }
//
//    CVPixelBufferLockBaseAddress(pxbuffer, 0);
//    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
//
//    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
//                                                 size.height, 8, 4*size.width, rgbColorSpace,
//                                                 kCGImageAlphaPremultipliedFirst);
//    //kCGImageAlphaNoneSkipFirst);
//    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
//    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
//                                           CGImageGetHeight(image)), image);
//    CGColorSpaceRelease(rgbColorSpace);
//    CGContextRelease(context);
//
//    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
//
//    return pxbuffer;
//}
//////////////////////////

////////////////////////
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image {
    
    CGSize size = CGSizeMake(1536, 828);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status != kCVReturnSuccess){
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    //kCGImageAlphaNoneSkipFirst);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
////////////////////////

- (void)stopRecording:(NSString *)videoId
{
    isRecording = false;
    [updateTimer invalidate];
    
    [self.assetWriterInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:8080/object/%@/video/%@", self.objectIP, self.objectID, videoId];
        [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];

        self.assetWriterInput = nil;
        self.assetWriter = nil;
        self.screenRecorder = nil;
    }];
    
//    [self.screenRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
//        if (!error) {
//            NSLog(@"Recording stopped successfully. Cleaning up...");
//            [self.assetWriterInput markAsFinished];
//            [self.assetWriter finishWritingWithCompletionHandler:^{
//
//                NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:8080/object/%@/video/%@", self.objectIP, self.objectID, videoId];
//                [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];
//
//                self.assetWriterInput = nil;
//                self.assetWriter = nil;
//                self.screenRecorder = nil;
//                //                isRecording = false;
//
//            }];
//        }
//    }];
}

//- (void)stopRecordingWithAR:(NSString *)videoId
//{
//    [self.screenRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
//        if (!error) {
//            NSLog(@"Recording stopped successfully. Cleaning up...");
//            [self.assetWriterInput markAsFinished];
//            [self.assetWriter finishWritingWithCompletionHandler:^{
//
//                NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:8080/object/%@/video/%@", self.objectIP, self.objectID, videoId];
//                [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];
//
//                self.assetWriterInput = nil;
//                self.assetWriter = nil;
//                self.screenRecorder = nil;
////                isRecording = false;
//
//            }];
//        }
//    }];
//}

@end
