//
//  ElevatorModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//
//  This code is ported from Matlab module

#import "Logger.h"
#import "ElevatorModule.h"
#import "SensorData.h"

@implementation ElevatorModule

- (void)run {
    int len = [self.measurement.measurements count];
    DLog(@"len: %d", len);
    
    if (len < MIN_MEASUREMENTS) {
        DLog(@"error: less measurement: %d\n", len);
        return;
    }
    
    NSMutableArray *a_x = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_y = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_z = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *times = [[NSMutableArray alloc] initWithCapacity:len];
    
    for (SensorData *sensorData in self.measurement.measurements) {
        [a_x addObject:sensorData.a_x];
        [a_y addObject:sensorData.a_y];
        [a_z addObject:sensorData.a_z];
        [times addObject:sensorData.time];
    }
    
    NSMutableArray *a_vert_vs = [self getVertAccelFromVS:times withX:a_x withY:a_y withZ:a_z];
    NSMutableArray *a_linear_vs = [self removeGravity:times withAccel:a_vert_vs];
    NSMutableArray *a_adjusted_vs = [self adjustAccelFromVS:times withAccel:a_linear_vs];
    
    NSMutableArray *a_v = a_adjusted_vs;
    NSMutableArray *v_v = [self getVelocityWithZUPT:times withAccel:a_v];
    NSMutableArray *d_v = [self getDisplacement:times withAccel:a_v withVelocity:v_v];
    
    double dist = [[d_v objectAtIndex:len - 1] doubleValue] - [[d_v objectAtIndex:0] doubleValue];
    self.movedDisplacement = [NSNumber numberWithDouble:dist];
    double floors = round([self.movedDisplacement doubleValue] / [self.buildingInfo.floorHeight doubleValue]);
    self.movedFloor = [NSNumber numberWithDouble:floors];
    DLog(@"moved dist: %f, floor: %f", dist, floors);
}

@end
