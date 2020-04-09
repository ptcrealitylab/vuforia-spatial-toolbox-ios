//
//  VideoRecordingManager.m
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 5/8/19.
//  Copyright © 2019 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "VideoRecordingManager.h"
#import "FileManager.h"

#define temporaryDirectory NSTemporaryDirectory()

@implementation VideoRecordingManager
{
    BOOL isRecording;
    CFTimeInterval recordingStartTime;
    CFTimeInterval firstFrameOffset;
    NSTimer* updateTimer;
}

// note that the videoRecordingDelegate is not set in the constructor, it MUST be manually set before startRecording is used
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

// This is a javascriptAPI-triggered function that starts recording the video feed from the camera background
// The objectKey and IP are used to save the resulting video file at a certain location on a Reality Server
// TODO: some optimization of startRecording and writeFrame should remove the slight lag while recording
- (void)startRecording:(NSString *)objectKey ip:(NSString *)objectIP port:(NSString *)objectPort
{
    CGSize videoOutputSize = CGSizeMake(640, 360); // change this to compress the video to a smaller size. can go up to 1080p.
    float frameRate = 30; // change this to compress the video by recording more/less frames per second
    
    if (isRecording) {
        NSLog(@"Can't record another until first finishes ... already recording");
        return;
    }
    
    NSError *error = nil;

    // generates a random filename and saves to temp file directory before uploading to server
    NSString *videoOutPath = [temporaryDirectory stringByAppendingPathComponent:[[NSString stringWithFormat:@"%u", arc4random() % 10000] stringByAppendingPathExtension:@"mp4"]];
    
    // uses AVAssetWriter to write the camera stream to an mp4 file
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    self.assetWriter.shouldOptimizeForNetworkUse = YES;

    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264BaselineAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @(videoOutputSize.width * videoOutputSize.height * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};
    
    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : [NSNumber numberWithFloat:videoOutputSize.width],
                                    AVVideoHeightKey                : [NSNumber numberWithFloat:videoOutputSize.height]};
    
    // creates the asset writer input to handle adding the video frames with the specified compression properties
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    [self.assetWriterInput setMediaTimeScale:60];
    [self.assetWriter setMovieTimeScale:60];
    [self.assetWriterInput setExpectsMediaDataInRealTime:YES];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    // the pixel buffer input is used to manually write frames into the video using pixel buffers, rather than letting something like ReplayKit add the frames
    self.assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.assetWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [self.assetWriter addInput:self.assetWriterInput];
    
    recordingStartTime = CACurrentMediaTime(); // frame timestamps are relative to when the video starts
    firstFrameOffset = -1; // the first frame might not get written immediately, so this offsets all the frame times by the difference (-1 means unset)
    
    // actually start the writing session
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    isRecording = true;
    
    // notify the delegate class that recording started, which is responsible for providing pixel buffers each frame via getVideoBackgroundPixels
    [self.videoRecordingDelegate recordingStarted];
    
    // start a loop to add frames to the video at the specified frame rate until stopVideoRecording is called
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/frameRate)
                                     target:self
                                   selector:@selector(writeFrame)
                                   userInfo:nil
                                    repeats:YES];
    
    // save the object ID and IP so we can upload to correct server when it finishes
    self.objectID = objectKey;
    self.objectIP = objectIP;
    self.objectPort = objectPort;
}

// this gets called at a fixed interval between startVideoRecording and stopVideoRecording
// it gets a pixel buffer from the videoRecordingDelegate and writes it into the asset writer at the current timestamp
- (void)writeFrame
{
    if (!isRecording) {
        return;
    }
    
    // get the time offset of how long it was between startVideoRecording and the first frame being added
    if (firstFrameOffset < 0) {
        firstFrameOffset = CACurrentMediaTime() - recordingStartTime;
    }
    
    // the first frame will have frameTime = 0, the second will be approximately ~= 0 + (1.0/frameRate), the third ~= 0 + 2 * (1.0/frameRate), ...
    CFTimeInterval frameTime = CACurrentMediaTime() - recordingStartTime - firstFrameOffset;
    
    // need to drop frames if the asset writer isn't ready
    if (!self.assetWriterInput.readyForMoreMediaData) {
        NSLog(@"adaptor not ready %f\n", frameTime);
        return;
    }
    
    // this actually gets an array of pixels in GL_32ARGB format from the AR class responsible for handling the camera
    GLchar* pixels = [self.videoRecordingDelegate getVideoBackgroundPixels];
    
    // this is the size of the raw video feed. this will be compressed to the size specified in AVAssetWriter's outputSettings
    CGSize size = [self.videoRecordingDelegate getCurrentARViewBoundsSize];
    
    // get the pixel buffer pool // TODO: I'm not sure if this is necessary anymore because I changed how I'm writing to the asset writer
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
    
    // add the resulting pixel buffer to the asset writer at the current timestamp
    CMTime presentationTime = CMTimeMakeWithSeconds(frameTime, 240);
    [self.assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
}

// This is a javascriptAPI-triggered function that stops the recording that is currently active
// The resulting video file is uploaded to the Reality Server specified by the objectKey and IP provided when startVideoRecording was called
- (void)stopRecording:(NSString *)videoId
{
    if (!isRecording) {
        return;
    }
    
    isRecording = false;
    [self.videoRecordingDelegate recordingStopped];
    
    // stop the writeFrame function from being called on loop
    [updateTimer invalidate];
    
    [self.assetWriterInput markAsFinished];
    
    // when the video finishes writing to disk (at path self.assetWriter.outputURL), upload it to the Reality Server (POST /object/:objectID/video/:videoID)
    [self.assetWriter finishWritingWithCompletionHandler:^{
        NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:%@/object/%@/video/%@", self.objectIP, self.objectPort, self.objectID, videoId];
        [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];

        self.assetWriterInput = nil;
        self.assetWriter = nil;
        self.screenRecorder = nil;
    }];
}

#pragma mark - Screen recording using ReplayKit
// This set of start/stop recording is currently NOT used, and there is no way to trigger it from the javascriptAPI right now
// It uses Apple's ReplayKit to record the full screen, *including AR elements and other UI*, instead of just the camera feed
// It works correctly, but interferes with trying to use the device's native screen recording feature at the same time.
// Use startRecording and stopRecording instead, which only record the camera background, not the AR elements.

// Source: https://github.com/anthonya1999/ReplayKit-iOS11-Recorder/blob/master/ReplayKit-iOS11-Recorder/ViewController.m
// TODO: fix startRecordingWithoutAR instead of using this
- (void)startRecordingWithAR:(NSString *)objectKey ip:(NSString *)objectIP port:(NSString *)objectPort
{
    CGSize videoOutputSize = CGSizeMake(640, 360); // change this to compress the video to a smaller size. can go up to 1080p.

    NSError *error = nil;
    
    // generates a random filename and saves to temp file directory before uploading to server
    NSString *videoOutPath = [temporaryDirectory stringByAppendingPathComponent:[[NSString stringWithFormat:@"%u", arc4random() % 10000] stringByAppendingPathExtension:@"mp4"]];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264BaselineAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @(videoOutputSize.width * videoOutputSize.height * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};
    
    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : [NSNumber numberWithFloat:videoOutputSize.width],
                                    AVVideoHeightKey                : [NSNumber numberWithFloat:videoOutputSize.height]};
    
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    [self.assetWriter addInput:self.assetWriterInput];
    [self.assetWriterInput setMediaTimeScale:60];
    [self.assetWriter setMovieTimeScale:60];
    [self.assetWriterInput setExpectsMediaDataInRealTime:YES];
    
    self.screenRecorder = [RPScreenRecorder sharedRecorder];
    
    isRecording = true;
    
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
            
            // save the object ID and IP and port so we can upload to correct server when it finishes
            self.objectID = objectKey;
            self.objectIP = objectIP;
            self.objectPort = objectPort;
        }
    }];
}

// Stops the recording started with startRecordingWithAR, and uploads the result to the server specified when startRecordingWithAR was called.
// TODO: fix stopRecordingWithoutAR instead of using this
- (void)stopRecordingWithAR:(NSString *)videoId
{
    [self.screenRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Recording stopped successfully. Cleaning up...");
            [self.assetWriterInput markAsFinished];
            [self.assetWriter finishWritingWithCompletionHandler:^{

                // in addition to IP and ID, port can be 8080 or 49369 depending on the server so we store it in another parameter
                NSString* urlEndpoint = [NSString stringWithFormat:@"http://%@:%@/object/%@/video/%@", self.objectIP, self.objectPort, self.objectID, videoId];
                [[FileManager sharedManager] uploadFileFromPath:self.assetWriter.outputURL toURL:urlEndpoint];

                self.assetWriterInput = nil;
                self.assetWriter = nil;
                self.screenRecorder = nil;
            }];
        }
    }];
}

@end
