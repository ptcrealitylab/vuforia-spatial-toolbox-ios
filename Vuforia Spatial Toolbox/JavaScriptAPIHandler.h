//
//  JavaScriptAPIHandler.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>

@protocol JavaScriptCallbackDelegate

@required
- (void)callJavaScriptCallback:(NSString *)callback withArguments:(NSArray *)arguments;
@property (nonatomic) BOOL callbacksEnabled;

@end

@interface JavaScriptAPIHandler : NSObject {
    id<JavaScriptCallbackDelegate> delegate;
}

- (id)initWithDelegate:(id<JavaScriptCallbackDelegate>)newDelegate;

// JavaScript API Interface
- (void)getDeviceReady:(NSString *)callback;
- (void)getVuforiaReady:(NSString *)callback;
- (void)addNewMarker:(NSString *)markerName callback:(NSString *)callback;
- (void)addNewMarkerJPG:(NSString *)markerName forObject:objectID targetWidthMeters:(float)targetWidthMeters callback:(NSString *)callback;
- (void)getProjectionMatrix:(NSString *)callback;
- (void)getMatrixStream:(NSString *)callback;
- (void)getCameraMatrixStream:(NSString *)callback;
- (void)getGroundPlaneMatrixStream:(NSString *)callback;
- (void)getScreenshot:(NSString *)size callback:(NSString *)callback;
- (void)setPause;
- (void)setResume;
- (void)enableExtendedTracking;
- (void)getUDPMessages:(NSString *)callback;
- (void)sendUDPMessage:(NSString *)message;
- (void)getFileExists:(NSString *)fileName callback:(NSString *)callback;
- (void)downloadFile:(NSString *)fileName callback:(NSString *)callback;
- (void)getFilesExist:(NSArray *)fileNameArray callback:(NSString *)callback;
- (void)getChecksum:(NSArray *)fileNameArray callback:(NSString *)callback;
- (void)setStorage:(NSString *)storageID message:(NSString *)message;
- (void)getStorage:(NSString *)storageID callback:(NSString *)callback;
- (void)startSpeechRecording;
- (void)stopSpeechRecording;
- (void)addSpeechListener:(NSString *)callback;
- (void)startVideoRecording:(NSString *)objectKey ip:(NSString *)objectIP port:(NSString *)objectPort;
- (void)stopVideoRecording:(NSString *)videoId;
- (void)tap;
- (void)focusCamera;
- (void)tryPlacingGroundAnchorAtScreenX:(NSString *)normalizedScreenX screenY:(NSString *)normalizedScreenY withCallback:(NSString *)callback;

- (void)loadNewUI:(NSString *)reloadURL;
- (void)clearCache;
// TODO: add authenticateTouch(?)
- (void)enableOrientationChanges:(NSString *)callback;

@end
