//
//  DebugTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "FileHandler.h"

@interface DebugTVC : UITableViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) FileHandler *fileHandler;

@property (strong, nonatomic) IBOutlet UILabel *fileNumLabel;
@property (strong, nonatomic) IBOutlet UILabel *historyNumLabel;
@end
