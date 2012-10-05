//
//  MainTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Logger.h"
#import "MainTVC.h"

@implementation MainTVC


- (void)viewDidLoad
{
    self.curFloorTextField.text = @"";
    self.curDispositionTextField.text = @"0";
    startButtonOn = NO;
    
    [super viewDidLoad];
}

- (IBAction)startButtonTouched:(id)sender {
    DLog(@"startbutton touched state: %@", startButtonOn ? @"YES" : @"NO");
    UIButton *button = (UIButton *)sender;
    if (startButtonOn == YES) {
        startButtonOn = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];
        //[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];

    } else {
        startButtonOn = YES;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        //[button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
}

@end;