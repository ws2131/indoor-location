//
//  MainTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Audiotoolbox/AudioToolbox.h>
#import "Logger.h"
#import "MainTVC.h"
#import "HistoryTVC.h"

@implementation MainTVC

@synthesize config;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize distanceFormatter;
@synthesize floorFormatter;
@synthesize delegate;


# pragma mark -
# pragma mark View

- (void)viewDidLoad
{
    [super viewDidLoad];

    BuildingInfo *buildingInfo = self.config.inBuilding;
    self.curFloorTextField.text = [buildingInfo.floorOfEntry stringValue];
    self.curDispositionTextField.text = @"0";
    startButtonOn = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BuildingInfo *buildingInfo = self.config.inBuilding;
    DLog(@"building %@ %@", buildingInfo.address1, buildingInfo.floorHeight);
    NSString *addr = [NSString stringWithFormat:@"%@\n%@\n%@", buildingInfo.address1, buildingInfo.address2, buildingInfo.address3];
    self.addressTextView.text = addr;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DLog(@"%@", segue.identifier);
    if ([segue.identifier isEqualToString:@"History Segue1"] || [segue.identifier isEqualToString:@"History Segue2"]) {
        HistoryTVC *historyTVC = segue.destinationViewController;
        historyTVC.managedObjectContext = self.managedObjectContext;
        historyTVC.distanceFormatter = self.distanceFormatter;
    }
}


# pragma mark -
# pragma mark UI Action functions

- (IBAction)startButtonTouched:(id)sender {

    DLog(@"startbutton touched state: %@", startButtonOn ? @"YES" : @"NO");
    [self playClickSound];
    
    UIButton *button = (UIButton *)sender;
    if (startButtonOn == YES) {
        DLog(@"stop pushed");
        startButtonOn = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];
        //[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.delegate stopButtonPushed:self];
    } else {
        DLog(@"start pushed");
        startButtonOn = YES;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        //[button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.delegate startButtonPushed:self];
    }
    DLog(@"startButtonTouched done");

}

- (IBAction)refresh:(id)sender {
    [self.delegate refreshButtonPushed:self];
}

- (IBAction)selectedActivity:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    if (segmentedControl.selectedSegmentIndex == 0) {
        // elevator
        [self.delegate activityChanged:self selectedActivity:elevator];
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        // stairway
        [self.delegate activityChanged:self selectedActivity:stairway];
    } else if (segmentedControl.selectedSegmentIndex == 2) {
        // stairway
        [self.delegate activityChanged:self selectedActivity:escalator];
    }
}

- (void)updateCurrentFloor:(NSNumber *)currentFloor {
    self.curFloorTextField.text = [NSString stringWithFormat:@"%@", [self.floorFormatter stringFromNumber:currentFloor]];
}

- (void)updateCurrentDisplacement:(NSNumber *)currentDisplacement {
    self.curDispositionTextField.text = [NSString stringWithFormat:@"%@", [self.distanceFormatter stringFromNumber:currentDisplacement]];
}

- (void)updateCounter:(NSNumber *)curCounter {
    self.counterUILabel.text = [NSString stringWithFormat:@"%d", [curCounter intValue]];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (IBAction)currentFloorChanged:(id)sender {
    DLog(@"changed to %@", self.curFloorTextField.text);
    [self.delegate currentFloorChanged:self];
}

- (void)playClickSound {
    SystemSoundID soundID;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"click" ofType:@"wav"];
    NSURL *url = [NSURL fileURLWithPath:path];
    AudioServicesCreateSystemSoundID ((__bridge CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound(soundID);
}

- (void)startActivityIndicator {
    [self.activityIndicatorView startAnimating];
}

- (void)stopActivityIndicator {
    [self.activityIndicatorView stopAnimating];
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

@end;