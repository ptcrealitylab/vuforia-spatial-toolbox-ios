//
//  VideoRecordingManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 5/8/19.
//  Copyright © 2019 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#import "VideoRecordingDelegate.h"

@interface VideoRecordingManager : NSObject

+ (id)sharedManager;

@property (strong, nonatomic) RPScreenRecorder *screenRecorder;
@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;

@property (strong, nonatomic) NSString* objectIP;
@property (strong, nonatomic) NSString* objectID;

@property (nonatomic, assign) id<VideoRecordingDelegate> videoRecordingDelegate;

- (void)startRecording:(NSString *)objectKey ip:(NSString *)objectIP;
- (void)stopRecording:(NSString *)videoId;

@end
