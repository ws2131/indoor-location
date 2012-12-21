//
//  EscalatorModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 12/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "EscalatorModule.h"
#import "SensorData.h"
#import "Logger.h"

@implementation EscalatorModule

- (void)run {
    DLog(@"escalator run");

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
    NSMutableArray *m11 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m12 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m13 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m21 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m22 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m23 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m31 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m32 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *m33 = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *heading = [[NSMutableArray alloc] initWithCapacity:len];
    
    for (SensorData *sensorData in self.measurement.measurements) {
        [a_x addObject:[NSNumber numberWithDouble:([sensorData.a_x doubleValue] * GRAVITY)]];
        [a_y addObject:[NSNumber numberWithDouble:([sensorData.a_y doubleValue] * GRAVITY)]];
        [a_z addObject:[NSNumber numberWithDouble:([sensorData.a_z doubleValue] * GRAVITY)]];
        [m11 addObject:sensorData.m11];
        [m12 addObject:sensorData.m12];
        [m13 addObject:sensorData.m13];
        [m21 addObject:sensorData.m21];
        [m22 addObject:sensorData.m22];
        [m23 addObject:sensorData.m23];
        [m31 addObject:sensorData.m31];
        [m32 addObject:sensorData.m32];
        [m33 addObject:sensorData.m33];
        [heading addObject:sensorData.heading];
        
        [times addObject:sensorData.time];
    }
    
    NSMutableArray *a_vert_rm = [self getVertAccelFromRM:times withX:a_x withY:a_y withZ:a_z withM11:m11 withM12:m12 withM13:m13 withM21:m21 withM22:m22 withM23:m23 withM31:m31 withM32:m32 withM33:m33];
    NSMutableArray *a_linear_rm = [self removeGravity:times withAccel:a_vert_rm];
    NSMutableArray *a_adjusted_rm = [self adjustAccelFromRM:times withAccel:a_linear_rm];
  
    NSMutableArray *a_v = a_adjusted_rm;
    NSMutableArray *v_v = [self getVelocity:times withAccel:a_v];
    NSMutableArray *d_v = [self getDisplacement:times withAccel:a_v withVelocity:v_v];
    
    double moved_dists = [[d_v objectAtIndex:len - 1] doubleValue] - [[d_v objectAtIndex:0] doubleValue];
    double moved_floors = round((double)(moved_dists / [self.buildingInfo.floorHeight doubleValue]));
    DLog(@"moved dist: %f, floor: %f", moved_dists, moved_floors);

    self.movedDisplacement = [NSNumber numberWithDouble:moved_dists];
    self.movedFloor = [NSNumber numberWithDouble:moved_floors];
    self.curDisplacement = [NSNumber numberWithDouble:([self.initialDisplacement doubleValue] + moved_dists)];
    self.curFloor = [NSNumber numberWithDouble:([self.initialFloor doubleValue] + moved_floors)];
}

@end
