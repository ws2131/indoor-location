//
//  ElevatorModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Logger.h"
#import "ElevatorModule.h"
#import "SensorData.h"

@implementation ElevatorModule

- (void)run {
    SensorData *sensorData = [super.measurements objectAtIndex:0];
    DLog(@"%@", sensorData.a_x);
}

@end
