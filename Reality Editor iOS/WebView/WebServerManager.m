//
//  WebServerManager.m
//  RealityEditor
//
//  Created by Benjamin Reynolds on 4/2/18.
//
// This is a singleton class that manages a GCDWebServer instance which is a local HTTP server
// that hosts the Reality Editor userinterface (used to allows cross-origin access between iframes and source content)

#import "WebServerManager.h"
#import "GCDWebServer.h"
#import "NodeRunner.h"

@implementation WebServerManager

@synthesize webServer;

#pragma mark - Singleton Methods

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
        [GCDWebServer setLogLevel:1]; // don't print DEBUG statements of network activity
        
        NSString *userinterfacePath = [[NSBundle mainBundle] pathForResource:@"userinterface" ofType:nil];
        [webServer addGETHandlerForBasePath:@"/" directoryPath:userinterfacePath indexFilename:@"index.html" cacheAge:0 allowRangeRequests:YES];
        [webServer startWithPort:8888 bonjourName:nil];
        
        if (webServer.serverURL == nil) {
            NSLog(@"Could not spin up local web server. Check to make sure you are connected to wifi.");
        } else {
            NSLog(@"Visit %@ in your web browser", webServer.serverURL);
        }
        
        NSThread* nodejsThread = nil;
        nodejsThread = [[NSThread alloc]
                        initWithTarget:self
                        selector:@selector(startNode)
                        object:nil
                        ];
        // Set 2MB of stack space for the Node.js thread.
        [nodejsThread setStackSize:2*1024*1024];
        [nodejsThread start];
        
    }
    return self;
}

- (void)startNode {
    NSLog(@"startNode");
    NSString* srcPath = [[NSBundle mainBundle] pathForResource:@"RE-server/server.js" ofType:@""];
    NSLog(@"Path: %@", srcPath);
    NSArray* nodeArguments = [NSArray arrayWithObjects:
                              @"node",
                              srcPath,
                              nil
                              ];
    [NodeRunner startEngineWithArguments:nodeArguments];
    NSLog(@"[NodeRunner startEngineWithArguments:%@]", nodeArguments);
}

- (NSURL *)getServerURL {
    //(webServer.serverURL)?webServer.serverURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://0.0.0.0:%d", webServer.port]];
//    if ([webServer serverURL]) {
        return [webServer serverURL];
//    } else {
//        return [NSURL URLWithString:@"http://0.0.0.0:8888/"];
//    }
}

@end
