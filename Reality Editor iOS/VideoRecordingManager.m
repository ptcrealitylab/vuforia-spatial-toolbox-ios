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
    
    NSDictionary *compressionProperties = @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
                                            AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
                                            AVVideoAverageBitRateKey       : @(1920 * 1080 * 11.4),
                                            AVVideoMaxKeyFrameIntervalKey  : @60,
                                            AVVideoAllowFrameReorderingKey : @NO};

    NSDictionary *videoSettings = @{AVVideoCompressionPropertiesKey : compressionProperties,
                                    AVVideoCodecKey                 : AVVideoCodecTypeH264,
                                    AVVideoWidthKey                 : @1920,
                                    AVVideoHeightKey                : @1080};

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
                
            }];
        }
    }];
}

@end
