//
//  WebServerManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 4/2/18.
//

#import <Foundation/Foundation.h>

@interface WebServerManager : NSObject

- (NSURL *)getServerURL;

+ (id)sharedManager;

@end
