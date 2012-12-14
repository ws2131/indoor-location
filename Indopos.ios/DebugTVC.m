//
//  DebugTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "DebugTVC.h"
#import "AppDelegate.h"
#import "Logger.h"
#import "Measurement.h"
#import "SensorData.h"
#import "FileTVC.h"

@implementation DebugTVC

@synthesize managedObjectContext = _managedObjectContext;
@synthesize dateFormatter;
@synthesize fileHandler;

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
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"History"
                                 inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time"
                                                                                     ascending:YES]];
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [NSString stringWithFormat:@"%d", [fetchResults count]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"File Segue"]) {
        FileTVC *fileTVC = segue.destinationViewController;
        fileTVC.fileHandler = self.fileHandler;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DLog(@"touch on %d %d", indexPath.section, indexPath.row);
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self.fileHandler sendLast];
    } else if (indexPath.section == 1 && indexPath.row == 1) {
        [self.fileHandler sendAll];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete All" message:@"Do you really want to delete all files?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:nil];
        [alert addButtonWithTitle:@"Yes"];
        [alert show];
    } else if (indexPath.section == 3 && indexPath.row == 0) {
        [(AppDelegate *)[UIApplication sharedApplication].delegate resetHistory];
        [self update];
    }

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.fileHandler deleteAll];
        [self update];
    }
}

@end
