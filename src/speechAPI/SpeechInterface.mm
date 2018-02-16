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

-(void)stopRecording {
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
     NSString * translatedString = [transcription formattedString];
     NSLog(@"%@", translatedString);
     self.delegate->handleIncomingSpeech([translatedString UTF8String]);
 }

@end
