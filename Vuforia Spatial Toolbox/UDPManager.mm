//
//  UDPManager.m
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

#import "UDPManager.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation UDPManager
{
    GCDAsyncUdpSocket* udpSocket;
    UDPMessageJsonHandler messageHandler;
}

@synthesize didStartUDP;

#define UDP_BROADCAST_HOST  @"255.255.255.255"
#define UDP_PORT 52316

+ (id)sharedManager
{
    static UDPManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        
        udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSError* err = nil;
        
        if (![udpSocket enableReusePort:true error:&err]) {
            NSLog(@"Cannot enable reuse UDP port %i: %@", UDP_PORT, err);
        }
        
        if (![udpSocket bindToPort:UDP_PORT error:&err]) {
            NSLog(@"Cannot bind UDP to port %i: %@", UDP_PORT, err);
        }
        
        if (![udpSocket enableBroadcast:YES error:&err]) {
            NSLog(@"Cannot enable UDP broadcast: %@", err);
        }
        
        if (![udpSocket beginReceiving:&err]) {
            NSLog(@"Cannot begin receiving UDP: %@", err);
        }
        
    }
    return self;
}

- (void)setReceivedMessageCallback:(UDPMessageJsonHandler)newMessageHandler
{
    messageHandler = newMessageHandler;
}

- (void)sendUDPMessage:(NSString *)message
{
    [udpSocket sendData:[message dataUsingEncoding:NSUTF8StringEncoding] toHost:UDP_BROADCAST_HOST port:UDP_PORT withTimeout:-1 tag:1];
}

#pragma mark - GCDAsyncUdpSocket Protocol Implementation
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSLog(@"Successfully connected UDP socket to address: %@", address);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error
{
    NSLog(@"Could not connect UDP socket: %@", error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString* dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    struct sockaddr_in *fromAddressV4 = (struct sockaddr_in *)address.bytes;
    char *fromIPAddress = inet_ntoa(fromAddressV4 -> sin_addr);
    NSString* addressString = [[NSString alloc] initWithUTF8String:fromIPAddress];
    
//    NSLog(@"Did receive data: %@, from address: %@, with filter context: %@", dataString, addressString, filterContext);
    
    messageHandler(dataString, addressString);
}

@end
