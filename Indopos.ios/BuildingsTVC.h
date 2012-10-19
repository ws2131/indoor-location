//
//  BuildingsTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/18/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import "BuildingInfo.h"

@class BuildingsTVC;
@protocol BuildingsTVCDelegate
- (void)buildingWasSelectedOnBuildingsTVC:(BuildingsTVC *)controller;
@end

@interface BuildingsTVC : CoreDataTableViewController

@property (weak, nonatomic) id delegate;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) BuildingInfo *selectedBuilding;

@end
