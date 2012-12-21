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
    DLog(@"elevator run: %d", len);
    
    if (len < MIN_MEASUREMENTS) {
        DLog(@"error: less measurement: %d\n", len);
        return;
    }
    
    NSMutableArray *a_x = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_y = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_z = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *times = [[NSMutableArray alloc] initWithCapacity:len];
    
    for (SensorData *sensorData in self.measurement.measurements) {
        [a_x addObject:[NSNumber numberWithDouble:([sensorData.a_x doubleValue] * GRAVITY)]];
        [a_y addObject:[NSNumber numberWithDouble:([sensorData.a_y doubleValue] * GRAVITY)]];
        [a_z addObject:[NSNumber numberWithDouble:([sensorData.a_z doubleValue] * GRAVITY)]];
        [times addObject:sensorData.time];
    }
    
    NSMutableArray *a_vert_vs = [self getVertAccelFromVS:times withX:a_x withY:a_y withZ:a_z];
    NSMutableArray *a_linear_vs = [self removeGravity:times withAccel:a_vert_vs];
    NSMutableArray *a_adjusted_vs = [self adjustAccelFromVS:times withAccel:a_linear_vs];
       
    NSMutableArray *a_v = a_adjusted_vs;
    NSMutableArray *v_v = [self getVelocityWithZUPT:times withAccel:a_v];
    NSMutableArray *d_v = [self getDisplacement:times withAccel:a_v withVelocity:v_v];
    
    double moved_dists = [[d_v objectAtIndex:len - 1] doubleValue] - [[d_v objectAtIndex:0] doubleValue];
    double moved_floors = round((double)(moved_dists / [self.buildingInfo.floorHeight doubleValue]));
    DLog(@"moved dist: %f, floor: %f", moved_dists, moved_floors);
    
    self.movedDisplacement = [NSNumber numberWithDouble:moved_dists];
    self.movedFloor = [NSNumber numberWithDouble:moved_floors];
    self.curDisplacement = [NSNumber numberWithDouble:([self.initialDisplacement doubleValue] + moved_dists)];
    self.curFloor = [NSNumber numberWithDouble:([self.initialFloor doubleValue] + moved_floors)];
}

- (double)run:(NSArray *)t withAccel:(NSArray *)a_vert_vs {
    int len = [t count];
    DLog(@"elevator run: %d", len);
        
    if (len < MIN_MEASUREMENTS) {
        DLog(@"error: less measurement: %d\n", len);
        return 0;
    }
    
    NSMutableArray *a_linear_vs = [self removeGravity:t withAccel:a_vert_vs];
    NSMutableArray *a_adjusted_vs = [self adjustAccelFromVS:t withAccel:a_linear_vs];
    
    NSMutableArray *a_v = a_adjusted_vs;
    NSMutableArray *v_v = [self getVelocityWithZUPT:t withAccel:a_v];
    NSMutableArray *d_v = [self getDisplacement:t withAccel:a_v withVelocity:v_v];
    
    double dist = [[d_v objectAtIndex:len - 1] doubleValue] - [[d_v objectAtIndex:0] doubleValue];
    DLog(@"moved dist: %f", dist);
    return dist;
}
@end
