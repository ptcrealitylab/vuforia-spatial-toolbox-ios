//
//  UDPManager.h
//  Vuforia Spatial Toolbox
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 PTC. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
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
