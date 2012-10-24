//
//  HistoryTVCViewController.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/17/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "HistoryTVC.h"
#import "History.h"
#import "Logger.h"
#import "AppDelegate.h"

@implementation HistoryTVC

@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize distanceFormatter;

# pragma mark -
# pragma mark View

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupFetchedResultsController];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"History Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    History *history = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *text = [NSString stringWithFormat:@"%@ [%d],  floor: %@,  (%@ m)",
                      [dateFormatter stringFromDate:history.time],
                      [history.duration intValue],
                      [history.floor stringValue],
                      [distanceFormatter stringFromNumber:history.displacement]];
    cell.textLabel.text = text;
    cell.detailTextLabel.text = history.address;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tableView beginUpdates];
        
        History *history = [self.fetchedResultsController objectAtIndexPath:indexPath];
        DLog(@"deleting (%@)", history.time);
        [self.managedObjectContext deleteObject:history];
        [self.managedObjectContext save:nil];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self performFetch];
        
        [self.tableView endUpdates];
    }
}


# pragma mark -
# pragma mark UI Action functions

- (IBAction)deleteAll:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete All" message:@"Do you want to delete all history?"
                                                    delegate:self cancelButtonTitle:@"No" otherButtonTitles:nil];
    [alert addButtonWithTitle:@"Yes"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self removeAllHistory];
    }
}


# pragma mark -
# pragma mark Private functions

- (void)setupFetchedResultsController {
    NSString *entityName = @"History";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    //request.predicate = [NSPredicate predicateWithFormat:@"Role.name = Blah"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil cacheName:nil];
    [self performFetch];
}

- (void)removeAllHistory {
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetHistory];
    [self setupFetchedResultsController];
    [self.tableView reloadData];
}

@end
