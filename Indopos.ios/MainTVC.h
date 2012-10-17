//
//  MainTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuildingInfo.h"

@class MainTVC;
@protocol MainTVCDelegate <NSObject>
- (void)startButtonPushed:(MainTVC *)controller;
- (void)stopButtonPushed:(MainTVC *)controller;
@end

@interface MainTVC : UITableViewController {
    BOOL startButtonOn;
}

@property (strong, nonatomic) BuildingInfo *buildingInfo;
@property (nonatomic, weak) id <MainTVCDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *curFloorTextField;
@property (strong, nonatomic) IBOutlet UITextField *curDispositionTextField;
@property (strong, nonatomic) IBOutlet UITextView *addressTextView;
@property (strong, nonatomic) IBOutlet UIButton *startUIButton;
@end
