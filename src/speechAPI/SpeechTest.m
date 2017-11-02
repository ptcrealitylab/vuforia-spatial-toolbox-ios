//
//  SpeechTest.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 11/1/17.
//

#import "SpeechTest.h"

@implementation SpeechTest
{
    SFSpeechRecognizer* speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest* recognitionRequest;
    SFSpeechRecognitionTask* recognitionTask;
    AVAudioEngine* audioEngine;
}

- (id) init
{
    if (self = [super init]) {

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
        
    }
    return self;
}

- (void) startListening
{
    audioEngine = [[AVAudioEngine alloc] init];
    
    if (recognitionTask) {
        [recognitionTask cancel];
        recognitionTask = nil;
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

- (void)microphoneTapped
{
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
    } else {
        [self startListening];
    }
}

#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"Availability:%d",available);
}

@end
