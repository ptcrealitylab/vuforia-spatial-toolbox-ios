//
//  VideoWriterDelegate.m
//  Editor
//
//  Created by Benjamin Reynolds on 8/3/18.
//

#import "REVideoWriterDelegate.h"
//#include "ofxiOSVideoWriter.h"

@implementation REVideoWriterDelegate

- (id)init {
    if (self = [super init]) {
        self.handler = nil;
    }
    return self;
}

- (void)videoWriterComplete:(NSURL *)url {
    if (self.handler != nil) {
        self.handler(url);
        NSLog(@"sent video path to delegate");
    } else {
        NSLog(@"no delegate to send video path to...");
    }
}

- (void)subscribeToVideoWriterComplete:(FileUrlCompletionHandler)completionHandler {
    self.handler = completionHandler;
}

@end
