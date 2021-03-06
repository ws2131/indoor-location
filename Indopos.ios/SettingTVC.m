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
#import "BuildingsTVC.h"

@implementation SettingTVC

@synthesize managedObjectContext = _managedObjectContext;
@synthesize config;

# pragma mark -
# pragma mark View

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Since this conflicts with segues to predefined building, we added tap gesture recognizer in IB
    // and connect it with UILabels instead.
    // UIlabel and it's cell should be 'user interaction enabled'.
    //UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    //[self.tableView addGestureRecognizer:tgr];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BuildingInfo *buildingInfo = self.config.inBuilding;
    DLog(@"building info: %@, %@, %@", buildingInfo.address1, buildingInfo.floorOfEntry, buildingInfo.floorHeight);

    self.floorOfEntryTextField.text = [buildingInfo.floorOfEntry stringValue];
    self.floorHeightTextfield.text = [buildingInfo.floorHeight stringValue];
    self.lobbyHeightTextField.text = [buildingInfo.lobbyHeight stringValue];
    self.numOfLandingsTextField.text = [buildingInfo.numOfLandings stringValue];

    self.address1TextField.text = buildingInfo.address1;
    self.address2TextField.text = buildingInfo.address2;
    self.address3TextField.text = buildingInfo.address3;
    
    self.freqTextField.text = [config.frequency stringValue];
}


# pragma mark -
# pragma mark UI Action functions

- (IBAction)save:(id)sender {
    DLog(@"buidlingInfo saved");
    [self dismissKeyboard];

    BuildingInfo *buildingInfo = self.config.inBuilding;
    // address1 is key
    NSString *msg = nil;
    if ([buildingInfo.address1 isEqualToString:self.address1TextField.text]) {
        // update
        msg = @"Updated.";
    } else {
        // insert
        msg = @"Inserted.";
        buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                          inManagedObjectContext:self.managedObjectContext];
        self.config.inBuilding = buildingInfo;
    }

    buildingInfo.floorOfEntry = [NSNumber numberWithInteger:[self.floorOfEntryTextField.text integerValue]];
    buildingInfo.floorHeight = [NSNumber numberWithFloat:[self.floorHeightTextfield.text floatValue]];
    buildingInfo.lobbyHeight = [NSNumber numberWithFloat:[self.lobbyHeightTextField.text floatValue]];
    buildingInfo.numOfLandings = [NSNumber numberWithFloat:[self.numOfLandingsTextField.text floatValue]];
    buildingInfo.address1 = self.address1TextField.text;
    buildingInfo.address2 = self.address2TextField.text;
    buildingInfo.address3 = self.address3TextField.text;
    
    NSNumber *prevFreq = config.frequency;
    config.frequency = [NSNumber numberWithInteger:[self.freqTextField.text integerValue]];
    if ([prevFreq intValue] != [config.frequency intValue]) {
        DLog("frequence is changed from %d to %d", [prevFreq intValue], [config.frequency intValue]);
        [(AppDelegate *)[UIApplication sharedApplication].delegate updateFrequency];
    }
    
    [self.managedObjectContext save:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:msg
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)resetHistory:(id)sender {
    DLog(@"reset pushed");
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetHistory];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DLog(@"%@", segue.identifier);
    if ([segue.identifier isEqualToString:@"Predefined Buildings Segue1"] || [segue.identifier isEqualToString:@"Predefined Buildings Segue2"]) {
        BuildingsTVC *buildingsTVC = segue.destinationViewController;
        buildingsTVC.managedObjectContext = self.managedObjectContext;
        buildingsTVC.delegate = self;
    }
}

- (void)buildingWasSelectedOnBuildingsTVC:(BuildingsTVC *)controller {
    DLog(@"predefined building selected %@", controller.selectedBuilding.address1);
    self.config.inBuilding = controller.selectedBuilding;
    [self.managedObjectContext save:nil];
    [controller.navigationController popViewControllerAnimated:YES];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)viewTapped:(UIGestureRecognizer *)sender {
    [self dismissKeyboard];
}


# pragma mark -
# pragma mark UI Textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
