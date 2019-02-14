//
//  ARManager.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageTargetsEAGLView.h"
#import "SampleApplicationSession.h"

typedef void (^ CompletionHandler)(void);
typedef void (^ MarkerCompletionHandler)(NSDictionary *);
typedef void (^ MarkerListCompletionHandler)(NSArray *);

@interface ARManager : NSObject <SampleApplicationControl> {
    UIViewController* containingViewController;
//    SEL startedARSelector;
    CompletionHandler arDoneCompletionHandler;
    MarkerListCompletionHandler visibleMarkersCompletionHandler;
    MarkerCompletionHandler cameraMatrixCompletionHandler;
}

+ (id)sharedManager;

@property (nonatomic) BOOL didStartAR;
@property (nonatomic, strong) ImageTargetsEAGLView* eaglView;
@property (nonatomic, strong) SampleApplicationSession * vapp;
@property (nonatomic, strong) NSMutableArray* markersFound;

- (void)setContainingViewController:(UIViewController *)newContainingViewController;
- (void)startARWithCompletionHandler:(CompletionHandler)completionHandler;
- (bool)addNewMarker:(NSString *)markerPath;
- (NSString *)getProjectionMatrixString;
- (void)setMatrixCompletionHandler:(MarkerListCompletionHandler)completionHandler;
- (void)setCameraMatrixCompletionHandler:(MarkerCompletionHandler)completionHandler;
- (UIImage *)getCameraPixelBuffer;
- (void)pauseCamera;
- (void)resumeCamera;
- (void)focusCamera;

@end
