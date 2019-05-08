//
//  FileManager.h
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
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
