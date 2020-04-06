//
//  WebServerManager.m
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 4/2/18.
//
// This is a singleton class that manages a NodeRunner instance which runs a local instance of the Spatial Edge Server

#import "WebServerManager.h"
#import "NodeRunner.h"

@implementation WebServerManager

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
    NSString* srcPath = [[NSBundle mainBundle] pathForResource:@"vuforia-spatial-edge-server/server.js" ofType:@""];
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
     return [NSURL URLWithString:@"http://127.0.0.1:49368/"];
}

@end
