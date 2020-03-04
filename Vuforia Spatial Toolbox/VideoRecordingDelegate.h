//
//  VideoRecordingDelegate.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 9/3/19.
//  Copyright © 2019 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
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
