//
//  SpeechManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 2/8/19.
//  Copyright © 2019 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import <Foundation/Foundation.h>
#import <Speech/Speech.h>

typedef void (^ CompletionHandlerWithString)(NSString *);

@interface SpeechManager : NSObject <SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate>

+ (id)sharedManager;

- (void) startRecording;
- (void) stopRecording;
- (void) addSpeechListener:(CompletionHandlerWithString)completionHandler;

@end
