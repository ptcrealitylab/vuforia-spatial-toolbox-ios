//
//  VideoRecordingManager.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 5/8/19.
//  Copyright © 2019 Reality Lab. All rights reserved.
//

#import "VideoRecordingManager.h"
#import "FileManager.h"

#define temporaryDirectory NSTemporaryDirectory()

@implementation VideoRecordingManager
//{
//    BOOL isRecording;
//    CFTimeInterval recordingStartTime;
//}

+ (id)sharedManager
{
    static VideoRecordingManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

// Source: https://github.com/anthonya1999/ReplayKit-iOS11-Recorder/blob/master/ReplayKit-iOS11-Recorder/ViewController.m
- (void)startRecording:(NSString *)objectKey ip:(NSString *)objectIP
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

/*
- (void)startRecordingWithoutAR:(NSString *)objectKey ip:(NSString *)objectIP
{
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
    isRecording = true;
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(writeFrame)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)writeFrame
{
    NSLog(@"writeFrame");
    
    UIImage* cameraBackground = [[ARManager sharedManager] getCameraPixelBuffer];
    
    if (!isRecording) {
        return;
    }
    
    // Create a dummy pixel buffer to try the encoding
    // on something simple.
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                          kCVPixelFormatType_32BGRA, NULL, &pixelBuffer);
    NSParameterAssert(status == kCVReturnSuccess && pixelBuffer != NULL);
    
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
    CFTimeInterval frameTime = CACurrentMediaTime() - recordingStartTime;
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
*/

- (void)stopRecording:(NSString *)videoId
{
    [self.screenRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Recording stopped successfully. Cleaning up...");
            [self.assetWriterInput markAsFinished];
            [self.assetWriter finishWritingWithCompletionHandler:^{
                
                NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:8080/object/%@/video/%@", self.objectIP, self.objectID, videoId];
                [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];
                
                self.assetWriterInput = nil;
                self.assetWriter = nil;
                self.screenRecorder = nil;
//                isRecording = false;
                
            }];
        }
    }];
}

@end
