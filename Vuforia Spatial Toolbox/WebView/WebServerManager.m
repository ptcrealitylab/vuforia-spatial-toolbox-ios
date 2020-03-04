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
        
        NSThread* nodejsThread = nil;
        nodejsThread = [[NSThread alloc]
                        initWithTarget:self
                        selector:@selector(startNode)
                        object:nil
                        ];
        // Set stack space for the Node.js thread, measured in bytes
        [nodejsThread setStackSize:8*1024*1024];
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
   //     return [webServer "172.0"];
//    } else {
     return [NSURL URLWithString:@"http://127.0.0.1:8888/"];
//    }
}

@end
