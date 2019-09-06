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

#pragma mark - Camera feed recording using OpenGL

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
                                            AVVideoAverageBitRateKey       : @(640 * 360 * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};
    
    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : @640,
                                    AVVideoHeightKey                : @360};
    
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    [self.assetWriterInput setMediaTimeScale:60];
    [self.assetWriter setMovieTimeScale:60];
    [self.assetWriterInput setExpectsMediaDataInRealTime:YES];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];

    
    self.assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [self.assetWriter addInput:self.assetWriterInput];
    
    recordingStartTime = CACurrentMediaTime();
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    isRecording = true;
    [self.videoRecordingDelegate recordingStarted];
    
    float frameRate = 30;
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/frameRate)
                                     target:self
                                   selector:@selector(writeFrame)
                                   userInfo:nil
                                    repeats:YES];
    
    NSLog(@"Recording started successfully.");
    // save the object ID and IP so we can upload to correct server when it finishes
    self.objectID = objectKey;
    self.objectIP = objectIP;
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
    
    GLchar* pixels = [self.videoRecordingDelegate getVideoBackgroundPixels];
    
    CGSize size = CGSizeMake(1920, 1080); // the size of the raw video feed. this will be compressed to the size specified in AVAssetWriter's outputSettings
    
    // get the pixel buffer pool // TODO: this is not necessary anymore?
    CVPixelBufferPoolRef pixelBufferPool = self.assetWriterPixelBufferInput.pixelBufferPool;
    if (!pixelBufferPool) {
        NSLog(@"Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame");
        return;
    }
    
    // create a pixel buffer from the pixel byte array returned by getVideoBackgroundPixels
    CVPixelBufferRef pixelBuffer = NULL;
    GLboolean status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (void*)pixels, size.width*4, NULL, 0, NULL, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"Could not get pixel buffer from asset writer input; dropping frame...");
        return;
    }
    
    // add the filled-in pixel buffer to the asset writer at the current timestamp
    CMTime presentationTime = CMTimeMakeWithSeconds(frameTime, 240);
    BOOL success = [self.assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer
                                                  withPresentationTime:presentationTime];
//    NSLog(@"wrote at %@ : %@", CMTimeCopyDescription(NULL, presentationTime), success ? @"YES" : @"NO");
}

- (void)stopRecording:(NSString *)videoId
{
    isRecording = false;
    [self.videoRecordingDelegate recordingStopped];
    [updateTimer invalidate];
    
    [self.assetWriterInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:8080/object/%@/video/%@", self.objectIP, self.objectID, videoId];
        [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];

        self.assetWriterInput = nil;
        self.assetWriter = nil;
        self.screenRecorder = nil;
    }];
}

#pragma mark - Screen recording using ReplayKit

// Source: https://github.com/anthonya1999/ReplayKit-iOS11-Recorder/blob/master/ReplayKit-iOS11-Recorder/ViewController.m
- (void)startRecordingWithAR:(NSString *)objectKey ip:(NSString *)objectIP
{
    NSError *error = nil;
    
    // generates a random filename and saves to temp file directory before uploading to server
    NSString *videoOutPath = [temporaryDirectory stringByAppendingPathComponent:[[NSString stringWithFormat:@"%u", arc4random() % 1000] stringByAppendingPathExtension:@"mp4"]];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    
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

- (void)stopRecordingWithAR:(NSString *)videoId
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
            }];
        }
    }];
}

@end
