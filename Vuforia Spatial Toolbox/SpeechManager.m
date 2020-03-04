//
//  SpeechManager.m
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 2/8/19.
//  Copyright © 2019 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "SpeechManager.h"

@implementation SpeechManager
{
    SFSpeechRecognizer* speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest* recognitionRequest;
    SFSpeechRecognitionTask* recognitionTask;
    AVAudioEngine* audioEngine;
    CompletionHandlerWithString speechCompletionHandler;
}

+ (id)sharedManager
{
    static SpeechManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        [self initSpeech];
    }
    return self;
}

- (void)initSpeech
{
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    speechRecognizer.delegate = self;
    
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                NSLog(@"Authorized");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"Denied");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"Not Determined");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"Restricted");
                break;
            default:
                break;
        }
    }];
    
    audioEngine = [[AVAudioEngine alloc] init];
}

- (void)startRecording
{
    if (recognitionTask) {
        NSLog(@"Already Recording!");
        return;
    }
    
    NSError* error;
    
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode* inputNode = [audioEngine inputNode];
    
    if (recognitionRequest == nil) {
        NSLog(@"Unable to created a SFSpeechAudioBufferRecognitionRequest object");
    }
    
    if (inputNode == nil) {
        NSLog(@"Unable to created a inputNode object");
    }
    
    recognitionRequest.shouldReportPartialResults = YES;
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest delegate:self];
    
    [inputNode installTapOnBus:0 bufferSize:4096 format:[inputNode outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when){
        [recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"Say something – I'm listening!");
}

- (void)stopRecording
{
    __weak SpeechManager *wSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(audioEngine.isRunning){
            [audioEngine.inputNode removeTapOnBus:0];
            [audioEngine.inputNode reset];
            [audioEngine stop];
        }
        if (recognitionRequest != nil) {
            [recognitionRequest endAudio];
        }
        if (recognitionTask != nil) {
            if (!recognitionTask.isCancelled) {
                [recognitionTask cancel];
            }
        }
        recognitionRequest = nil;
        recognitionTask = nil;
    });
}

- (void)addSpeechListener:(CompletionHandlerWithString)completionHandler
{
    speechCompletionHandler = completionHandler;
}

- (void)handleIncomingSpeech:(NSString *)transcribedString
{
    if (speechCompletionHandler) {
        speechCompletionHandler(transcribedString);
    }
}

#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"Availability: %d", available);
}

#pragma mark - SFSpeechRecognitionTaskDelegate Delegate Methods

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition:(SFSpeechRecognitionResult *)recognitionResult
{
    NSLog(@"speechRecognitionTask:(SFSpeechRecognitionTask *)task didFinishRecognition");
    
    NSLog(@"Best Transcription: %@", recognitionResult.bestTranscription);
    
    if ([recognitionResult isFinal]) {
        [audioEngine stop];
        [audioEngine.inputNode removeTapOnBus:0];
        recognitionTask = nil;
        recognitionResult = nil;
    }
}

- (void)speechRecognitionTask:(SFSpeechRecognitionTask *)task didHypothesizeTranscription:(SFTranscription *)transcription {
    NSString * transcribedString = [transcription formattedString];
    NSLog(@"%@", transcribedString);
    [self handleIncomingSpeech:transcribedString];
}

@end
