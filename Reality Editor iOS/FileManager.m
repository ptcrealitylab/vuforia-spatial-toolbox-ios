//
//  FileManager.m
//  Reality Editor iOS
//
//  Created by Benjamin Reynolds on 7/18/18.
//  Copyright © 2018 Reality Lab. All rights reserved.
//

#import "FileManager.h"

@implementation FileManager

+ (id)sharedManager
{
    static FileManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

// method for converting a URL to a file that was downloaded -> into a valid readable/writeable path in the NSTemporaryDirectory
// creates any intermediate directories if needed to mirror the url /file/path/components/ including the IP address formatted as /0-0-0-0_8080/
- (NSString *)getTempFilePath:(NSString *)originalFilePath
{
    NSMutableArray<NSString*>* pathComponents = [[originalFilePath componentsSeparatedByString: @"/"] mutableCopy];
    NSString* lastPathComponent = [originalFilePath lastPathComponent];
    NSString* containingDirectory = [originalFilePath stringByDeletingLastPathComponent];
    
    // if file path is a url, convert it to a valid nested folder structure
    if ([pathComponents[0] isEqualToString:@"http:"] || [pathComponents[0] isEqualToString:@"https:"]) {
        pathComponents[2] = [[pathComponents[2] stringByReplacingOccurrencesOfString:@"." withString:@"-"] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
        [pathComponents removeObjectsInRange:NSMakeRange(0, 2)];
        [pathComponents removeLastObject];
        containingDirectory = [pathComponents componentsJoinedByString:@"/"];
    }
    
    containingDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:containingDirectory];
    
    NSError* err;
    [[NSFileManager defaultManager] createDirectoryAtPath:containingDirectory withIntermediateDirectories:YES attributes:nil error:&err]; // create containing directory otherwise cannot save
    if (err != nil) {
        NSLog(@"Error creating containing directory %@. Error: %@", containingDirectory, err);
    }

    NSString* filePath = [containingDirectory stringByAppendingPathComponent:lastPathComponent];
    return filePath;
}

- (bool)getFileExists:(NSString *)fileName
{
    NSString* filePath = [self getTempFilePath:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (bool)getFilesExist:(NSArray *)fileNameArray
{
    bool allExist = true;
    
    for (int i = 0; i < fileNameArray.count; i++){
        NSString* fileName = fileNameArray[i];
        NSLog(@"Checking if file exists: %@", fileName);
        NSString* filePath = [self getTempFilePath:fileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            allExist = false;
            break;
        }
    }
    
    return allExist;
}

- (void)downloadFile:(NSString *)fileName withCompletionHandler:(CompletionHandlerWithSuccess)completionHandler
{
    //download the file in a seperate thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Downloading Started");
        NSURL  *url = [NSURL URLWithString:fileName];
        NSData *urlData = [NSData dataWithContentsOfURL:url]; // TODO: get an error message if this times out so we can cb(false)
        // can use timeout by implementing something like... https://stackoverflow.com/a/29894936/1190267
        
        if (urlData) {
            
            NSString* filePath = [self getTempFilePath:fileName];
            
            //saving is done on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSError* err;
                [urlData writeToFile:filePath options:NSDataWritingAtomic error:&err];
                
                if (err != nil) {
                    NSLog(@"File Saved to path: %@", filePath);
                } else {
                    NSLog(@"File write error: %@", err);
                }
                //http://10.0.0.225:8080/obj/stonesScreen/target/target.xml
                
                completionHandler(err == nil);
            });
        } else {
            completionHandler(false);
        }
    });
}

- (long)getChecksum:(NSArray *)fileNameArray
{
    NSLog(@"TODO: implement getChecksum");
    return fileNameArray.count; // TODO: implement by hashing the data of the files
}

- (void)setStorage:(NSString *)storageID message:(NSString *)message
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:message forKey:storageID];
    [defaults synchronize];
    NSLog(@"Saved {%@: %@}", storageID, message);
}

- (NSString *)getStorage:(NSString *)storageID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* message = [defaults objectForKey:storageID];
    NSLog(@"Loaded %@ from %@", message, storageID);
    return message;
}

@end
