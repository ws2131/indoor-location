//
//  SettingTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BuildingInfo.h"
#import "BuildingsTVC.h"

@interface SettingTVC : UITableViewController<BuildingsTVCDelegate>

@property (strong, nonatomic) Config *config;
@property (strong, nonatomic) BuildingInfo *buildingInfo;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutlet UITextField *floorOfEntryTextField;
@property (strong, nonatomic) IBOutlet UITextField *floorHeightTextfield;
@property (strong, nonatomic) IBOutlet UITextField *lobbyHeightTextField;
@property (strong, nonatomic) IBOutlet UITextField *numOfLandingsTextField;
@property (strong, nonatomic) IBOutlet UITextField *address1TextField;
@property (strong, nonatomic) IBOutlet UITextField *address2TextField;
@property (strong, nonatomic) IBOutlet UITextField *address3TextField;

- (IBAction)resetHistory:(id)sender;
- (IBAction)exportMeasurement:(id)sender;

@end