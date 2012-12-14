//
//  FileTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/22/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//
#import "Logger.h"
#import "FileTVC.h"
#import "FileViewVC.h"

@implementation FileTVC

@synthesize dateFormatter;
@synthesize fileHandler;


- (void)viewDidLoad
{
    [super viewDidLoad];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fileHandler getAll] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"File Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *fname = [[self.fileHandler getAll] objectAtIndex:indexPath.row];
    //NSString *text = [NSString stringWithFormat:@"%@, [%d KB]", fname, [self.fileHandler getFileSizeFromFile:fname] / 1000];
    //cell.textLabel.text = text;
    //cell.textLabel.font = [UIFont  systemFontOfSize:14.0];
    cell.textLabel.text = fname;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d KB", [self.fileHandler getFileSizeFromFile:fname] / 1000];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tableView beginUpdates];
        
        NSString *fname = [[self.fileHandler getAll] objectAtIndex:indexPath.row];
        FileHandler *fh = [[FileHandler alloc] initWithName:fname];
        [fh deleteFile];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"File Content Segue"]) {
        NSString *fname = ((UITableViewCell *)sender).textLabel.text;
        DLog(@"filename: %@", fname);
        FileViewVC *fileViewVC = segue.destinationViewController;
        fileViewVC.fileName = fname;
    }
}

@end
