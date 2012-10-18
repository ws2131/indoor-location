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

@implementation HistoryTVC

@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize distanceFormatter;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
    NSString *text = [NSString stringWithFormat:@"%@,  floor: %@,  (%@ m)",
                       [dateFormatter stringFromDate:history.time], [history.floor stringValue], [distanceFormatter stringFromNumber:history.displacement]];
    cell.textLabel.text = text;
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
@end
