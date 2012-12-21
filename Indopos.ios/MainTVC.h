//
//  MainTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Config.h"
#import "BuildingInfo.h"

@class MainTVC;


typedef enum {
    elevator = 1,
    stairway,
    escalator,
    all,
} ActivityType;

@protocol MainTVCDelegate <NSObject>
- (void)startButtonPushed:(MainTVC *)controller;
- (void)stopButtonPushed:(MainTVC *)controller;
- (void)refreshButtonPushed:(MainTVC *)controller;
- (void)currentFloorChanged:(MainTVC *)controller;
- (void)activityChanged:(MainTVC *)controller selectedActivity:(ActivityType)activity;
@end

@interface MainTVC : UITableViewController<UITextFieldDelegate> {
    BOOL startButtonOn;
}

@property (strong, nonatomic) Config *config;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSNumberFormatter *distanceFormatter;
@property (strong, nonatomic) NSNumberFormatter *floorFormatter;

@property (nonatomic, weak) id <MainTVCDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *curFloorTextField;
@property (strong, nonatomic) IBOutlet UITextField *curDispositionTextField;
@property (strong, nonatomic) IBOutlet UITextView *addressTextView;
@property (strong, nonatomic) IBOutlet UIButton *startUIButton;
@property (strong, nonatomic) IBOutlet UILabel *progressUILabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet UILabel *counterUILabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *activitySegmentedControl;
@property (strong, nonatomic) IBOutlet UISwitch *activityUISwitch;

- (void)updateCurrentFloor:(NSNumber *)currentFloor;
- (void)updateCurrentDisplacement:(NSNumber *)currentDisplacement;
- (void)startActivityIndicator;
- (void)stopActivityIndicator;
- (void)updateCounter:(NSNumber *)curCounter;

@end
