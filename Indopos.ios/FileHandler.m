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

- (id)init {
    self = [super init];
    if (self) {
        self.fileManager = [NSFileManager defaultManager];
        self.fileDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    }
    return self;
}

- (id)initWithName:(NSString *)fileName_ {
    self = [self init];
    if (self) {
        self.fileName = fileName_;
    }
    return self;
}

- (void)setFileName:(NSString *)fileName_ {
    fileName = fileName_;
    self.filePath = [self.fileDir stringByAppendingPathComponent:self.fileName];
    DLog(@"path: %@", filePath);
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

- (void)sendFile {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    if (fileHandle) {

        NSURL * theURL = [NSURL URLWithString:ACC_UPLOAD_URL];
        NSMutableURLRequest *postRequest = [[NSMutableURLRequest alloc] initWithURL:theURL];
        
        //adding header information:
        [postRequest setHTTPMethod:@"POST"];
        
        NSString *stringBoundary = @"0xKhTmLbOuNdArY";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
        [postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        //setting up the body:
        NSMutableData *postBody = [NSMutableData data];
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"uploadFile\"; filename=\"%@\"\r\n", self.fileName] dataUsingEncoding:NSUTF8StringEncoding]];
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
    int num = 0;
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath:self.fileDir error:nil];
    for (NSString *file in files) {
        if ([file hasPrefix:FILE_PREFIX]) {
            NSString *path = [self.fileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", file]];
            [self.fileManager removeItemAtPath:path error:nil];
            num++;
        }
    }
    DLog(@"%d\n", num);
}

- (NSString *)getNumFiles {
    int num = 0;
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath:self.fileDir error:nil];
    for (NSString *file in files) {
        if ([file hasPrefix:FILE_PREFIX]) {
            num++;
        }
    }
    return [NSString stringWithFormat:@"%d", num];
}

- (NSArray *)loadFromFile:(NSString *)fileName_ {
    NSString *filePath_ = [self.fileDir stringByAppendingPathComponent:fileName_];
    NSString *content = [NSString stringWithContentsOfFile:filePath_ encoding:NSASCIIStringEncoding error:nil];
    NSArray *fields = [content CSVComponents];
    return fields;
}

- (void)sendAll {
    int count = 0;
    NSURL * theURL = [NSURL URLWithString:ACC_UPLOAD_URL];
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath:self.fileDir error:nil];
    for (NSString *file in files) {
        if ([file hasPrefix:FILE_PREFIX]) {
            
            NSString *path = [self.fileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", file]];
            
            NSMutableURLRequest *postRequest = [[NSMutableURLRequest alloc] initWithURL:theURL];
            
            //adding header information:
            [postRequest setHTTPMethod:@"POST"];
            
            NSString *stringBoundary = @"0xKhTmLbOuNdArY";
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
            [postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
            
            //setting up the body:
            NSMutableData *postBody = [NSMutableData data];
            [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"uploadFile\"; filename=\"%@\"\r\n", file] dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [postBody appendData:[NSData dataWithContentsOfFile:path]];
            [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postRequest setHTTPBody:postBody];
            
            NSURLResponse *response = nil;
            [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:nil];
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            DLog(@"filename: %@ status: %d", path, httpResponse.statusCode);
            count++;
        }
    }
    NSString *str = [NSString stringWithFormat:@"%d files uploaded.", count];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:str message:nil
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (NSArray *)getAll {
    NSMutableArray *fileNames = [[NSMutableArray alloc] initWithCapacity:10];
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath:self.fileDir error:nil];
    for (NSString *file in files) {
        if ([file hasPrefix:FILE_PREFIX]) {
            [fileNames addObject:file];
        }
    }
    return fileNames;
}

- (int)getFileSizeFromFile:(NSString *)fileName_ {
    NSString *filePath_ = [self.fileDir stringByAppendingPathComponent:fileName_];
    NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath_ error:nil];
    if (fileAttributes) {
        return [[fileAttributes objectForKey:@"NSFileSize"] integerValue];
    } else {
        return 0;
    }
}

@end
