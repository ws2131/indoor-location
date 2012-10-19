//
//  DebugTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "DebugTVC.h"
#import "AppDelegate.h"

#define ACC_UPLOAD_URL @"http://ng911dev1.cs.columbia.edu/iLM/acc/upload.php"

@implementation DebugTVC

@synthesize managedObjectContext = _managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self update];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
}

- (void)update {
    self.fileNumLabel.text = [self.fileHandler getNumFiles];
    self.historyNumLabel.text = [self getNumHistory];
}

- (NSString *)getNumHistory {
    NSString *entityName = @"History";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [NSString stringWithFormat:@"%d", [fetchResults count]];
}

- (IBAction)sendAllFiles:(id)sender {
    [self.fileHandler sendFileAllTo:ACC_UPLOAD_URL];
}

- (IBAction)deleteAllFiles:(id)sender {
    [self.fileHandler deleteAll];
    [self update];
}

- (IBAction)deleteAllHistories:(id)sender {
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetHistory];
    [self update];
}
@end
