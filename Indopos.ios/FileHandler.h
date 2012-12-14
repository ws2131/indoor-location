//
//  FileHandler.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ACC_UPLOAD_URL @"http://ng911dev1.cs.columbia.edu/iLM/acc/upload.php"
#define FILE_PREFIX @"accel"

@class FileHandler;
@protocol FileHandlerDelegate <NSObject>
- (void)fileUploadSucceeded:(FileHandler *)handler;
- (void)fileUploadFailed:(FileHandler *)handler;
@end

@interface FileHandler : NSObject

@property (nonatomic, strong) NSString *fileDir;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, weak) id <FileHandlerDelegate> delegate;

- (id)init;
- (id)initWithName:(NSString *)fileName;
- (void)setFileName:(NSString *)fileName;

- (NSString *)getFileContent;
- (void)writeToFile:(NSString *)data;
- (void)deleteFile;
- (NSString *)getFileSize;
- (NSString *)getNumFiles;
- (void)sendFile;

- (void)deleteAll;
- (NSArray *)loadFromFile:(NSString *)fileName;
- (void)sendAll;
- (void)sendLast;
- (NSArray *)getAll;
- (int)getFileSizeFromFile:(NSString *)fileName;
@end
