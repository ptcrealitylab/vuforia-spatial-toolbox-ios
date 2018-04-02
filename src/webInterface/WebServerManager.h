//
//  WebServerManager.h
//  RealityEditor
//
//  Created by Benjamin Reynolds on 4/2/18.
//

#import <Foundation/Foundation.h>
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

@interface WebServerManager : NSObject {
    GCDWebServer* webServer;
}

@property (nonatomic, retain) GCDWebServer* webServer;

- (NSURL *)getServerURL;

+ (id)sharedManager;

@end
