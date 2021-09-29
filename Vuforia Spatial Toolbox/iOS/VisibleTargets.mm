//
//  VisibleTargets.m
//  vst-swift
//
//  Created by Ben Reynolds on 9/17/21.
//

#import "VisibleTargets.h"
#import <vector>

@interface VisibleTargets() {
    std::vector<TrackableObservation> targets;
}

@end

@implementation VisibleTargets

- (TrackableObservation *)targetAtIndex:(NSInteger)index
{
    return NULL;
}

- (NSInteger)visibleTargetsSize
{
    return 0;
}

@end
