//
//  VisibleTargets.h
//  vst-swift
//
//  Created by Ben Reynolds on 9/17/21.
//

#import <Foundation/Foundation.h>
#import "TrackableObservation.h"

NS_ASSUME_NONNULL_BEGIN

@interface VisibleTargets : NSObject

- (NSInteger)visibleTargetsSize;
- (TrackableObservation *)targetAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
