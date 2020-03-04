//
//  SpeechManager.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 2/8/19.
//  Copyright © 2019 Reality Lab. All rights reserved.
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
