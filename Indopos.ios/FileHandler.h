//
//  FileHandler.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

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

- (id)initWithName:(NSString *)fileName;
- (NSString *)getFileContent;
- (void)writeToFile:(NSString *)data;
- (void)deleteFile;
- (void)deleteAll;
- (NSString *)getFileSize;
- (NSString *)getNumFiles;
- (void)sendFileTo:(NSString *)url;

- (NSArray *)loadFromFile:(NSString *)fileName;

@end
