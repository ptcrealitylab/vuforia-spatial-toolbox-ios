//
//  FileManager.h
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

typedef void (^ CompletionHandlerWithSuccess)(bool);

@interface FileManager : NSObject

+ (id)sharedManager;

- (NSString *)getTempFilePath:(NSString *)originalFilePath;
- (bool)getFileExists:(NSString *)fileName;
- (bool)getFilesExist:(NSArray *)fileNameArray;
- (void)downloadFile:(NSString *)fileName withCompletionHandler:(CompletionHandlerWithSuccess)completionHandler;
- (long)getChecksum:(NSArray *)fileNameArray;
- (NSString *)getStorage:(NSString *)storageID;
- (void)uploadFileFromPath:(NSURL *)localPath toURL:(NSString *)destinationURL;

@end
