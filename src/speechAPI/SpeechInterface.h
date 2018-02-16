//
//  SpeechInterface.hpp
//  RealityEditor
//
//  Created by Benjamin Reynolds on 11/1/17.
//

#pragma once

#include <stdio.h>
#include <iostream>
#import <Speech/Speech.h>

@class SpeechInterfaceObjC; // forward declaration

// An abstract class - inherit this class where you want to implement this speech handler
class SpeechDelegateCpp {
public:
    virtual void handleIncomingSpeech(std::string bestTranscription) = 0;
private:
    SpeechInterfaceObjC *delegate;
};

// create an instance of this within your handler class to interact with speech recognition via its ObjC member
class SpeechInterfaceCpp {
public:
    void initializeWithCustomDelegate(SpeechDelegateCpp *delegate);
    void startRecording();
    void stopRecording();
private:
    SpeechInterfaceObjC* speechInterfaceObjC;
};

// a member of the speech interface C++ class, this can be accessed to directly interact with speech APIs
@interface SpeechInterfaceObjC : NSObject <SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate>

@property(nonatomic, assign) SpeechDelegateCpp *delegate;
- (void) startRecording;
- (void) stopRecording;

@end
