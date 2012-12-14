//
//  FileViewTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 12/12/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//
#import "Logger.h"
#import "FileViewVC.h"
#import "FileHandler.h"

@implementation FileViewVC

@synthesize fileName;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    FileHandler *fh = [[FileHandler alloc] initWithName:self.fileName];
    //UITextView *tv = (UITextView *)self.view;
    //tv.text = [fh getFileContent];
    self.fileTextView.text = [fh getFileContent];
}

@end
