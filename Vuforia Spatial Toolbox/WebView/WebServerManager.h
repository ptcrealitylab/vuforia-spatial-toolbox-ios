//
//  WebServerManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 4/2/18.
//

#import <Foundation/Foundation.h>

@class GCDWebServer;

@interface WebServerManager : NSObject {
    GCDWebServer* webServer;
}

@property (nonatomic, retain) GCDWebServer* webServer;

- (NSURL *)getServerURL;

+ (id)sharedManager;

@end
