//
//  BuildingsTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/18/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Logger.h"
#import "BuildingsTVC.h"

@implementation BuildingsTVC

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize delegate;
@synthesize selectedBuilding;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupFetchedResultsController];

}


#pragma mark - CoreData related

- (void)setupFetchedResultsController {
    NSString *entityName = @"BuildingInfo";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"address1"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil cacheName:nil];
    [self performFetch];
}


#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Building Info Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    BuildingInfo *buildingInfo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = buildingInfo.address1;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedBuilding = [self.fetchedResultsController objectAtIndexPath:indexPath];
    DLog(@"selected %@", self.selectedBuilding.address1);
    [self.delegate buildingWasSelectedOnBuildingsTVC:self];
}

@end
