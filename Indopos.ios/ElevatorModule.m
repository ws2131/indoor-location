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

#define CUTOFFPOINT 2
#define GRAVITY 9.8

@implementation ElevatorModule

- (void)run {
    int len = [self.measurements count];
    
    NSMutableArray *a_x = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_y = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_z = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *times = [[NSMutableArray alloc] initWithCapacity:len];
    for (SensorData *sensorData in self.measurements) {
        [a_x addObject:sensorData.a_x];
        [a_y addObject:sensorData.a_y];
        [a_z addObject:sensorData.a_z];
        [times addObject:sensorData.time];
    }
    
    int freq = round(1 / ([[times objectAtIndex:99] doubleValue] / 100));
    double alpha = (1.0 / freq) / (1.0 / freq + (1.0 / (freq / 2.0)));
    DLog(@"freq: %d, alpha: %f", freq, alpha);

    NSArray *a_x_lpf = [self lowPassFilter:a_x withAlpha:alpha];
    NSArray *a_y_lpf = [self lowPassFilter:a_y withAlpha:alpha];
    NSArray *a_z_lpf = [self lowPassFilter:a_z withAlpha:alpha];
    
    NSMutableArray *vec_sum_lpf = [[NSMutableArray alloc] initWithCapacity:len];
    for (int i = 0; i < len; i++) {
        double tmp = sqrt((pow([[a_x_lpf objectAtIndex:i] doubleValue], 2) +
                           pow([[a_y_lpf objectAtIndex:i] doubleValue], 2) +
                           pow([[a_z_lpf objectAtIndex:i] doubleValue], 2)));
        [vec_sum_lpf addObject:[NSNumber numberWithDouble:tmp]];
    }
    DLog(@"vec_sum_lpf(end): %f", [[vec_sum_lpf objectAtIndex:len-1] doubleValue]);
        
    double sum = 0;
    for (int i = 31; i < len; i++) {
        sum += [[vec_sum_lpf objectAtIndex:i] doubleValue];
    }
    double a_gravity = sum / (len - 1 - 31 + 1);
    DLog(@"a_gravity: %f", a_gravity);

    NSMutableArray *a_user = [[NSMutableArray alloc] initWithCapacity:len];
    for (int i = 0; i < len; i++) {
        double tmp = [[vec_sum_lpf objectAtIndex:i] doubleValue] - a_gravity;
        [a_user addObject:[NSNumber numberWithDouble:tmp]];
    }
    DLog(@"a_user(end): %f", [[a_user objectAtIndex:len-1] doubleValue]);

    NSArray *a_user2 = [self cutOffDecimal:a_user withPosition:CUTOFFPOINT];
    NSMutableArray *a_linear = [[NSMutableArray alloc] initWithCapacity:len];
    for (int i = 0; i < len; i++) {
        double tmp = [[a_user2 objectAtIndex:i] doubleValue] * GRAVITY;
        [a_linear addObject:[NSNumber numberWithDouble:tmp]];
    }
    DLog(@"a_linear(end): %f", [[a_linear objectAtIndex:484] doubleValue]);
    
    int offset = 0.5 * freq;
    int last_index = 0;
    DLog(@"offset: %d", offset);
    NSMutableArray *a_adjusted = [[NSMutableArray alloc] initWithArray:a_linear copyItems:YES];
    for (int i = 0; i < len; i++) {
        if ([[a_adjusted objectAtIndex:i] doubleValue] == 0.0) {
            if (i - last_index < offset) {
                for (int j = last_index; j < i; j++) {
                    [a_adjusted replaceObjectAtIndex:j withObject:[NSNumber numberWithDouble:0.0]];
                }
            }
            last_index = i;
        }
    }
    //[self printDoubleArray:a_adjusted];

    NSMutableArray *v_adjusted = [self getVelocity:times withAccel:a_adjusted];
    //[self printDoubleArray:v_adjusted];
    double v_max = [self getAbsoluteMax:v_adjusted];
    double v_gap = 0.0;
    DLog(@"v_max: %f", v_max);

    for (int i = 1; i < len; i++) {
        double v = [[v_adjusted objectAtIndex:i] doubleValue];
        double a1 = [[a_adjusted objectAtIndex:i] doubleValue];
        double a2 = [[a_adjusted objectAtIndex:(i - 1)] doubleValue];
        if (a1 == 0.0 && a2 == 0.0) {
            if ([self getAbsolute:(v - v_gap)] < v_max * 0.3) {
                v_gap = v;
                [v_adjusted replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0.0]];
            }
        }
        if (v != 0.0) {
            double tmp = v - v_gap;
            [v_adjusted replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:tmp]];
        }
    }
    NSArray *d_adjusted = [super getDisplacement:times withAccel:a_adjusted withVelocity:v_adjusted];
    //[self printDoubleArray:d_adjusted];
    
    self.movedDisplacement = [d_adjusted objectAtIndex:(len - 1)];
    int tmp = round([self.movedDisplacement doubleValue] / [self.buildingInfo.floorHeight doubleValue]);
    self.movedFloor = [NSNumber numberWithInt:tmp];
}

@end
