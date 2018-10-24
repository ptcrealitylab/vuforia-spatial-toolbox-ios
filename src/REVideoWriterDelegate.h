//
//  VideoWriterDelegate.h
//  Editor
//
//  Created by Benjamin Reynolds on 8/3/18.
//

#import <Foundation/Foundation.h>
#import "VideoWriterDelegate.h"

typedef void (^ FileUrlCompletionHandler)(NSURL *);

@interface REVideoWriterDelegate : NSObject <VideoWriterDelegate>
//{
//    FileUrlCompletionHandler handler;
//}

@property (nonatomic, copy) FileUrlCompletionHandler handler;

- (void)videoWriterComplete:(NSURL *)url;
- (void)subscribeToVideoWriterComplete:(FileUrlCompletionHandler)completionHandler;

@end
