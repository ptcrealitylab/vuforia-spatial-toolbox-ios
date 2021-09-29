//
//  TrackableObservation.h
//  vst-swift
//
//  Created by Ben Reynolds on 9/17/21.
//

#ifndef TrackableObservation_h
#define TrackableObservation_h

typedef struct TrackableObservation
{
    const char* name;
    const char* modelMatrix;
    const char* trackingStatus; // TRACKED, EXTENDED_TRACKED, LIMITED, NO_POSE
    const char* trackingStatusInfo; // NORMAL, RELOCALIZING, NOT_OBSERVED (+ more for model targets, e.g. WRONG_SCALE)
    const char* targetType; // image, model, object, area
} TrackableObservation;

#define MAX_TRACKABLES 32 // Pick something sensible.
typedef struct TrackableObservationList
{
    int numObservations;
    TrackableObservation* observationData[MAX_TRACKABLES];
} TrackableObservationList;

#endif /* TrackableObservation_h */
