//
//  SettingTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Logger.h"
#import "SettingTVC.h"
#import "AppDelegate.h"

@implementation SettingTVC

@synthesize buildingInfo;

# pragma mark -
# pragma mark View

- (void)viewDidLoad
{    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.tableView addGestureRecognizer:tgr];
    
    [super viewDidLoad];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    DLog(@"building info: %@, %@, %@", self.buildingInfo.address1, self.buildingInfo.floorOfEntry, self.buildingInfo.floorHeight);

    self.floorOfEntryTextField.text = [self.buildingInfo.floorOfEntry stringValue];
    self.floorHeightTextfield.text = [self.buildingInfo.floorHeight stringValue];
    self.lobbyHeightTextField.text = [self.buildingInfo.lobbyHeight stringValue];
    self.numOfLandingsTextField.text = [self.buildingInfo.numOfLandings stringValue];

    self.address1TextField.text = self.buildingInfo.address1;
    self.address2TextField.text = self.buildingInfo.address2;
    self.address3TextField.text = self.buildingInfo.address3;
}


# pragma mark -
# pragma mark UI Action functions

- (IBAction)save:(id)sender {
    DLog(@"buidlingInfo saved");
    [self dismissKeyboard];

    self.buildingInfo.floorOfEntry = [NSNumber numberWithInteger:[self.floorOfEntryTextField.text integerValue]];
    self.buildingInfo.floorHeight = [NSNumber numberWithFloat:[self.floorHeightTextfield.text floatValue]];
    self.buildingInfo.lobbyHeight = [NSNumber numberWithFloat:[self.lobbyHeightTextField.text floatValue]];
    self.buildingInfo.numOfLandings = [NSNumber numberWithFloat:[self.numOfLandingsTextField.text floatValue]];
    self.buildingInfo.address1 = self.address1TextField.text;
    self.buildingInfo.address2 = self.address2TextField.text;
    self.buildingInfo.address3 = self.address3TextField.text;
    
    [self.buildingInfo.managedObjectContext save:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Setting is saved."
                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)resetHistory:(id)sender {
    DLog(@"reset pushed");
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetHistory];
}

- (IBAction)exportMeasurement:(id)sender {
    DLog(@"export pushed");
    [(AppDelegate *)[UIApplication sharedApplication].delegate exportMeasurement];
}

@end
