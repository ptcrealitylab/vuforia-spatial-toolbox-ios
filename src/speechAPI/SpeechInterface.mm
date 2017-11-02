//
//  SpeechInterface.cpp
//  RealityEditor
//
//  Created by Benjamin Reynolds on 11/1/17.
//

#include "SpeechInterface.h"

void SpeechInterfaceCpp::initializeWithCustomDelegate(SpeechDelegateCpp *delegate) {
    speechInterfaceObjC = [[SpeechInterfaceObjC alloc] init];
    [speechInterfaceObjC setDelegate:delegate];
}

void SpeechInterfaceCpp::startRecording() {
    [speechInterfaceObjC startRecording];
}

void SpeechInterfaceCpp::stopRecording() {
    [speechInterfaceObjC stopRecording];
}

@implementation SpeechInterfaceObjC
{
    SFSpeechRecognizer* speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest* recognitionRequest;
    SFSpeechRecognitionTask* recognitionTask;
    AVAudioEngine* audioEngine;
}

- (id) init {
    self = [super init];
    if (self) {
        [self initSpeech];
    }
    return self;
}

- (void) initSpeech {
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

- (void) startRecording
{
    if (recognitionTask) {
        [self stopRecording];
    }
    
    NSError* error;
    
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode* inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    // TODO: can start this with a delegate instead of handler, maybe make realityEditor the delegate
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result) {
            self.delegate->handleIncomingSpeech([result.bestTranscription.formattedString UTF8String]);
            NSLog(@"RESULT: %@", result.bestTranscription.formattedString);
            isFinal = !result.isFinal;
        }
        if (error) {
            [audioEngine stop];
            [inputNode removeTapOnBus:0];
            recognitionRequest = nil;
            recognitionTask = nil;
        }
    }];
    
    AVAudioFormat* recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"Say something – I'm listening!");
    
}

-(void)stopRecording {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(audioEngine.isRunning){
            [audioEngine.inputNode removeTapOnBus:0];
            [audioEngine.inputNode reset];
            [audioEngine stop];
            [recognitionRequest endAudio];
            [recognitionTask cancel];
            recognitionTask = nil;
            recognitionRequest = nil;
        }
    });
}

#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"Availability: %d", available);
}

@end
