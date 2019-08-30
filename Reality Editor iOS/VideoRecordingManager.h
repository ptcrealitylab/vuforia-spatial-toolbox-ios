//
//  VideoRecordingManager.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 5/8/19.
//  Copyright © 2019 Reality Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

@interface VideoRecordingManager : NSObject

+ (id)sharedManager;

@property (strong, nonatomic) RPScreenRecorder *screenRecorder;
@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterInput;
//@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;

@property (strong, nonatomic) NSString* objectIP;
@property (strong, nonatomic) NSString* objectID;

- (void)startRecording:(NSString *)objectKey ip:(NSString *)objectIP;
- (void)stopRecording:(NSString *)videoId;

@end
