//
//  FileHandler.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Logger.h"
#import "FileHandler.h"
#import "NSString+CHCSVAdditions.h"

@implementation FileHandler

@synthesize fileDir, fileName, filePath, fileManager;
@synthesize dateFormatter;
@synthesize delegate;

- (id)initWithName:(NSString *)fileName_ {
    self = [super init];
    if (self) {
        self.fileManager = [NSFileManager defaultManager];
        self.fileDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        self.fileName = fileName_;
        self.filePath = [self.fileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", self.fileName]];
        DLog(@"path: %@", filePath);
    }
    return self;
}

- (NSString *)getFileContent {
    NSString *myData = [NSString stringWithContentsOfFile:self.filePath encoding:NSASCIIStringEncoding error:nil];
    return myData;
}

- (void)writeToFile:(NSString *)data {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    if (!fileHandle) {
        [data writeToFile:self.filePath atomically:YES encoding:NSASCIIStringEncoding error:nil];
    } else {
        [fileHandle truncateFileAtOffset:[fileHandle seekToEndOfFile]];
        [fileHandle writeData:[data dataUsingEncoding:NSASCIIStringEncoding]];
    }
}

- (void)deleteFile {
    [self.fileManager removeItemAtPath:self.filePath error:nil];
}

- (NSString *)getFileSize {
    NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:self.filePath error:nil];
    NSString *fileSize = @"0";
    if (fileAttributes) {
        fileSize = [fileAttributes objectForKey:@"NSFileSize"];
    }
    return fileSize;
}

- (void)sendFileTo:(NSString *)targetURL {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    if (fileHandle) {
        
        NSDate *date = [NSDate date];
        NSString *targetFileName = [NSString stringWithFormat:@"%@.%@.txt", self.fileName, [self.dateFormatter stringFromDate:date]];
        NSLog(@"sendFileTo targetFileName: %@", targetFileName);
        NSURL * theURL = [NSURL URLWithString:targetURL];
        
        //copy file as backup
        NSString *copyPath = [self.fileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", targetFileName]];
        NSLog(@"sendFileTo copyPath: %@", copyPath);
        [self.fileManager copyItemAtPath:self.filePath toPath:copyPath error:nil];
        
        
        NSMutableURLRequest *postRequest = [[NSMutableURLRequest alloc] initWithURL:theURL];
        
        //adding header information:
        [postRequest setHTTPMethod:@"POST"];
        
        NSString *stringBoundary = @"0xKhTmLbOuNdArY";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
        [postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        //setting up the body:
        NSMutableData *postBody = [NSMutableData data];
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"uploadFile\"; filename=\"%@\"\r\n", targetFileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[NSData dataWithContentsOfFile:self.filePath]];
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postRequest setHTTPBody:postBody];
        
        NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:postRequest delegate:self];
        if (theConnection == nil) {
            NSLog(@"send error");
        }        
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    
    // receivedData is an instance variable declared elsewhere.
    //[receivedData setLength:0];
    NSLog(@"didReceiveResponse");
    NSHTTPURLResponse *httpResponse;
    httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 200) {
        DLog(@"status 200");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"HTTP OK" message:nil
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        // delete file only upload is successful
        [self deleteFile];
        [self.delegate fileUploadSucceeded:self];
    } else {
        // display alert message
        NSString *errMesg = [NSString stringWithFormat:@"Status Code %zd", (ssize_t) httpResponse.statusCode];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"HTTP Error" message:errMesg
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        DLog(@"%@", errMesg);
        [self.delegate fileUploadFailed:self];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // nothing to do
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    //[receivedData appendData:data];
    NSLog(@"didReceiveData");
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // release the connection, and the data object
    //[connection release];
    
    // display alert message
    NSString *errMesg = [NSString stringWithFormat:@"Connection Failed: %@ %@",
                         [error localizedDescription],
                         [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
    // inform the user
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"HTTP Error" message:errMesg
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    DLog(@"%@", errMesg);
    [self.delegate fileUploadFailed:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // do something with the data 
    // receivedData is declared as a method instance elsewhere
    //NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
    
    // release the connection, and the data object
    //[connection release];
    DLog(@"connectionDidFinishLoading");
}

- (void)deleteAll {
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath:self.fileDir error:nil];
    NSLog(@"%d\n", files.count);
    for (int i = 0; i < files.count; i++) {
        NSString *file = (NSString *)[files objectAtIndex:i];
        if ([file hasPrefix:@"accel"]) {
            NSString *path = [self.fileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", file]];
            [self.fileManager removeItemAtPath:path error:nil];
        }
    }
}

- (NSString *)getNumFiles {
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath:self.fileDir error:nil];
    NSString *num = [NSString stringWithFormat:@"%d", files.count];
    return num;
}


- (NSArray *)loadFromFile:(NSString *)fileName_ {
    NSString *filePath_ = [self.fileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", fileName_]];
    NSString *content = [NSString stringWithContentsOfFile:filePath_ encoding:NSASCIIStringEncoding error:nil];
    NSArray *fields = [content CSVComponents];
    return fields;
}

@end
