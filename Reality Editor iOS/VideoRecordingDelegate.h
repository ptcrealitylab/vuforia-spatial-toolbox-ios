//
//  VideoRecordingDelegate.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 9/3/19.
//  Copyright © 2019 Reality Lab. All rights reserved.
//

#ifndef VideoRecordingDelegate_h
#define VideoRecordingDelegate_h

// The Video Recording Delegate needs to return an image of the camera feed at this point in time, to be written to the video file.
@protocol VideoRecordingDelegate
- (GLchar *)getVideoBackgroundPixels;
- (CGSize)getCurrentARViewBoundsSize;
- (void)recordingStarted;
- (void)recordingStopped;
@end

#endif /* VideoRecordingDelegate_h */
