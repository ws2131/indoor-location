//
//  HistoryTVCViewController.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/17/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"

@interface HistoryTVC : CoreDataTableViewController<UIAlertViewDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSNumberFormatter *distanceFormatter;

@end
