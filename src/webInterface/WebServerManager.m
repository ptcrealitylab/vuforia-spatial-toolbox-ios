//
//  WebServerManager.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 4/2/18.
//

#import "WebServerManager.h"

@implementation WebServerManager

@synthesize webServer;

#pragma mark Singleton Methods

+ (id)sharedManager {
    static WebServerManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
        // Create server
        webServer = [[GCDWebServer alloc] init];
        
        NSString *userinterfacePath = [[NSBundle mainBundle] pathForResource:@"userinterface" ofType:nil];
        [webServer addGETHandlerForBasePath:@"/" directoryPath:userinterfacePath indexFilename:@"index.html" cacheAge:0 allowRangeRequests:YES];
        [webServer startWithPort:8888 bonjourName:nil];
        NSLog(@"Visit %@ in your web browser", webServer.serverURL);
        
    }
    return self;
}

- (NSURL *)getServerURL {
    return [webServer serverURL];
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    [super dealloc];
}

@end
