//
//  UDPManager.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

typedef void (^ UDPMessageJsonHandler)(NSString *, NSString *); // NSDictionary* JSON, NSString* Address

@interface UDPManager : NSObject <GCDAsyncUdpSocketDelegate>

+ (id)sharedManager;

@property (nonatomic) BOOL didStartUDP;

- (void)setReceivedMessageCallback:(UDPMessageJsonHandler)newMessageHandler;
- (void)sendUDPMessage:(NSString *)message;

@end
