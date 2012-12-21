//
//  StairwayModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/26/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "StairwayModule.h"
#import "Logger.h"
#import "SensorData.h"
#define GAMMA 80

@implementation StairwayModule

- (void)run {
    int len = [self.measurement.measurements count];
    DLog(@"stairway run: %d", len);
    
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
    
    int freq = [self getFrequency:times];
    double alpha = (1.0 / freq) / (1.0 / freq + (1.0 / (freq / 2.0)));
    NSMutableArray *heading_lpf = [self lowPassFilter:heading withAlpha:alpha];
    
    StepResult *stepResult = [self stepDetection:times withAccel:a_v];
    NSArray *a_amp = stepResult.a_amp;
    
    //DLog(@"ave: %f, num: %d", [stepResult.a_amp_ave doubleValue], [stepResult.a_amp_num intValue]);
    
    int step_num = 0;
    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            step_num++;
        }
    }
    NSMutableArray *steps = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *step_amp = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_heading = [[NSMutableArray alloc] initWithCapacity:step_num];
    //NSMutableArray *step_heading_accuracy = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_d = [[NSMutableArray alloc] initWithCapacity:step_num];
    int step_index = -1;
    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            step_index++;
            [step_amp addObject:[a_amp objectAtIndex:i]];
            [step_heading addObject:[heading_lpf objectAtIndex:i]];
            [step_d addObject:[d_v objectAtIndex:i]];
        }
        [steps addObject:[NSNumber numberWithInt:step_index]];
    }
    
    if (step_index == 0) {
        DLog(@"error: no steps: %d\n", step_index);
        return;
    }

    double step_amp_max = [[step_amp valueForKeyPath:@"@max.doubleValue"] doubleValue];
    double step_amp_min = [[step_amp valueForKeyPath:@"@min.doubleValue"] doubleValue];
    double step_amp_ave = [[step_amp valueForKeyPath:@"@avg.doubleValue"] doubleValue];

    // landing detection
    NSMutableArray *step_stat_by_accel = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_stat_by_magneto = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_stat_by_dist = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_stat_by_all = [[NSMutableArray alloc] initWithCapacity:step_num];

    double amp_diff = 0;
    double amp_diff_max = step_amp_max - step_amp_ave;
    double amp_diff_min = step_amp_min - step_amp_ave;
    for (int i = 0; i < step_num; i++) {
        amp_diff = [[step_amp objectAtIndex:i] doubleValue] - step_amp_ave;
        if (amp_diff >= 0) {
            [step_stat_by_accel addObject:[NSNumber numberWithDouble:(amp_diff / amp_diff_max)]];
        } else {
            [step_stat_by_accel addObject:[NSNumber numberWithDouble:(amp_diff / amp_diff_min) * -1]];
        }
    }

    double heading_diff = 0;
    [step_stat_by_magneto addObject:[NSNumber numberWithDouble:0.0]];
    for (int i = 1; i < step_num; i++) {
        heading_diff = [self diffAngles:[[step_heading objectAtIndex:i] doubleValue] withAngle:[[step_heading objectAtIndex:i - 1] doubleValue]];
        [step_stat_by_magneto addObject:[NSNumber numberWithDouble:(heading_diff / GAMMA * -2) + 1]];
    }

    double dist_diff = 0;
    double dist_diff_max = 0;
    [step_stat_by_dist addObject:[NSNumber numberWithDouble:0.0]];
    for (int i = 1; i < step_num; i++) {
        dist_diff = [self getAbsolute:([[step_d objectAtIndex:i - 1] doubleValue] - [[step_d objectAtIndex:i] doubleValue])];
        if (dist_diff > dist_diff_max) {
            dist_diff_max = dist_diff;
        }
    }
    for (int i = 1; i < step_num; i++) {
        dist_diff = [self getAbsolute:([[step_d objectAtIndex:i - 1] doubleValue] - [[step_d objectAtIndex:i] doubleValue])];
        [step_stat_by_dist addObject:[NSNumber numberWithDouble:(dist_diff / dist_diff_max * 2) - 1]];
    }

    double st_ac = 0;
    double st_ma = 0;
    double st_di = 0;
    for (int i = 0; i < step_num; i++) {
        st_ac = [[step_stat_by_accel objectAtIndex:i] doubleValue];
        st_ma = [[step_stat_by_magneto objectAtIndex:i] doubleValue];
        st_di = [[step_stat_by_dist objectAtIndex:i] doubleValue];
        if (st_ac < -0.5) {
            st_ac = st_ac * 2;
        }
        if (st_ma < -0.5) {
            st_ma = st_ma * 2;
        }
        if (st_di < -0.5) {
            st_di = st_di * 2;
        }
        [step_stat_by_all addObject:[NSNumber numberWithDouble:(3 * st_ac + 2 * st_ma + st_di) / 5]];
    }
    
    // adjust landing detection part 1
    for (int i = 0; i < step_num-2; i++) {
        if ([[step_stat_by_all objectAtIndex:i] doubleValue] * [[step_stat_by_all objectAtIndex:i + 1] doubleValue] <= 0 &&
            [[step_stat_by_all objectAtIndex:i + 1] doubleValue] * [[step_stat_by_all objectAtIndex:i + 2] doubleValue] <= 0) {
            if ([self getAbsolute:[[step_stat_by_all objectAtIndex:i + 1] doubleValue]] < [self getAbsolute:[[step_stat_by_all objectAtIndex:i] doubleValue]] ||
                [self getAbsolute:[[step_stat_by_all objectAtIndex:i + 1] doubleValue]] < [self getAbsolute:[[step_stat_by_all objectAtIndex:i + 2] doubleValue]]) {
                [step_stat_by_all replaceObjectAtIndex:(i + 1) withObject:[NSNumber numberWithDouble:[[step_stat_by_all objectAtIndex:i + 1] doubleValue] * -1]];
            }
        }
    }
    
    NSMutableArray *step_stat = [[NSMutableArray alloc] initWithCapacity:step_num];
    for (int i = 0; i < step_num; i++) {
        if ([[step_stat_by_all objectAtIndex:i] doubleValue] > 0) {
            [step_stat addObject:[NSNumber numberWithInt:1]];
        } else {
            [step_stat addObject:[NSNumber numberWithInt:0]];
        }
    }
    
    int st_index = 0;
    int st_stat = 0;
    NSMutableArray *time_stat = [[NSMutableArray alloc] initWithCapacity:len];
    for (int i = 0; i < len; i++) {
        st_index = [[steps objectAtIndex:i] intValue];
        if (st_index > 0 && st_index < step_num - 1) {
            st_stat = [[step_stat objectAtIndex:st_index] intValue];
        } else {
            st_stat = 0;
        }
        [time_stat addObject:[NSNumber numberWithInt:st_stat]];
    }
    NSMutableArray *v_zupt = [self getVelocityWithZUPTForWalking:times withAccel:a_v withStat:time_stat];
    NSMutableArray *d_zupt = [self getDisplacement:times withAccel:a_v withVelocity:v_zupt];
    

    NSMutableArray *step_v_zupt = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_d_zupt = [[NSMutableArray alloc] initWithCapacity:step_num];

    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            [step_v_zupt addObject:[v_zupt objectAtIndex:i]];
            [step_d_zupt addObject:[d_zupt objectAtIndex:i]];
        }
    }
    
    if ([[step_stat objectAtIndex:step_num - 1] intValue] == 0 && [[step_stat objectAtIndex:step_num - 2] intValue] == 1) {
        [step_stat replaceObjectAtIndex:step_num - 2 withObject:[NSNumber numberWithInt:0]];
    }
    
    int start_index = -1;
    int end_index = -1;
    int ss_index = -1;
    int ee_index = -1;
    double dist_diff_prev = 0;
    double dist_diff_cur = 0;
    int gap = 0;
    double confidence_prev = 0;
    double confidence_cur = 0;
    
    [step_stat replaceObjectAtIndex:step_num - 1 withObject:[NSNumber numberWithInt:1]];
    NSMutableArray *step_stat_out = [[NSMutableArray alloc] initWithArray:step_stat copyItems:YES];
    NSMutableArray *step_direction = [self zerosWithInt:step_num];

    for (int i = 0; i < step_num - 1; i++) {

        if ([[step_stat objectAtIndex:i] intValue] == 1 && [[step_stat objectAtIndex:i + 1] intValue] == 0) {
            start_index = i + 1;
        } else if ([[step_stat objectAtIndex:i] intValue] == 0 && [[step_stat objectAtIndex:i + 1] intValue] == 1) {
            end_index = i;
            if (start_index != -1) {
                for (int j = start_index - 1; j > 0; j--) {
                    if ([[step_stat objectAtIndex:j] intValue] == 0) {
                        ss_index = j;
                        break;
                    }
                }
                ss_index = ss_index + 1;
                ee_index = start_index - 1;
                
                dist_diff_prev = [self getAbsolute:([[step_d_zupt objectAtIndex:ee_index] doubleValue] - [[step_d_zupt objectAtIndex:ss_index] doubleValue])];
                dist_diff_cur = [self getAbsolute:([[step_d_zupt objectAtIndex:end_index] doubleValue] - [[step_d_zupt objectAtIndex:start_index] doubleValue])];
                gap = ee_index - ss_index + 1;
                
                if (ee_index - ss_index + 1 > 3) {
                    confidence_prev = [self getAverage:step_stat_by_all from:ss_index + 1 to:ee_index - 1];
                } else {
                    confidence_prev = 0;
                }
                if (end_index - start_index + 1 > 3) {
                    confidence_cur = [self getAverage:step_stat_by_all from:start_index + 1 to:end_index - 1];
                } else {
                    confidence_cur = 0;
                }
                if (confidence_prev < 0.5 && gap > MIN_STAIR_NUM && dist_diff_prev < MIN_STAIR_HEIGHT) {
                    for (int j = ss_index; j <= ee_index; j++) {
                        [step_stat_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:0]];
                    }
                }
                
                if ((confidence_prev < 0.5 && [[step_stat objectAtIndex:ss_index] intValue] == 1 && dist_diff_prev < MIN_STAIR_HEIGHT * 0.5) ||
                    (dist_diff_cur > MIN_STAIR_HEIGHT)) {
                    for (int j = start_index; j <= end_index; j++) {
                        [step_stat_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:1]];
                    }
                } else {
                    if ([[step_d_zupt objectAtIndex:start_index] doubleValue] > [[step_d_zupt objectAtIndex:ss_index] doubleValue]) {
                        for (int j = start_index; j <= end_index; j++) {
                            [step_direction replaceObjectAtIndex:j withObject:[NSNumber numberWithInt: 1]];
                        }
                    } else {
                        for (int j = start_index; j <= end_index; j++) {
                            [step_direction replaceObjectAtIndex:j withObject:[NSNumber numberWithInt: -1]];
                        }
                    }
                }
            }
            start_index = -1;
        }
    }
    step_stat = step_stat_out;
    [step_stat replaceObjectAtIndex:step_num - 1 withObject:[NSNumber numberWithInt:0]];
    
    // adjust landing detection part 3
    start_index = -1;
    end_index = -1;
    step_stat_out = [[NSMutableArray alloc] initWithArray:step_stat copyItems:YES];
    for (int i = 0; i < step_num - 1; i++) {
        if ([[step_stat objectAtIndex:i] intValue] == 0 && [[step_stat objectAtIndex:i + 1] intValue] == 1) {
            start_index = i + 1;
        } else if ([[step_stat objectAtIndex:i] intValue] == 1 && [[step_stat objectAtIndex:i + 1] intValue] == 0) {
            if (start_index != -1) {
                end_index = i;
                gap = end_index - start_index;
                if (gap < MIN_STAIR_NUM || gap > MAX_STAIR_NUM) {
                    for (int j = start_index; j <= end_index; j++) {
                        [step_stat_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:0]];
                    }
                }
            }
            start_index = -1;
        }
    }
    step_stat = step_stat_out;
    
    double moved_floors = 0;
    for (int i = 0; i < step_num - 1; i++) {
        if ([[step_stat objectAtIndex:i] intValue] == 1 && [[step_stat objectAtIndex:i + 1] intValue] == 0) {
            moved_floors += ([[step_direction objectAtIndex:i + 1] intValue] / [self.buildingInfo.numOfLandings doubleValue]);
        }
    }
    double moved_dists = moved_floors * [self.buildingInfo.floorHeight doubleValue];
    DLog(@"moved dist: %f, floor: %f", moved_dists, moved_floors);
    
    self.movedDisplacement = [NSNumber numberWithDouble:moved_dists];
    self.movedFloor = [NSNumber numberWithDouble:moved_floors];
    self.curDisplacement = [NSNumber numberWithDouble:([self.initialDisplacement doubleValue] + moved_dists)];
    self.curFloor = [NSNumber numberWithDouble:([self.initialFloor doubleValue] + moved_floors)];
}


-(double)run:(NSArray *)times withAccel:(NSArray *)a_vert_rm withAmp:(NSArray *)a_amp withHeading:(NSArray *)heading_lpf withIndex:(int)index {
    int len = [times count];
    DLog(@"stairway run: %d", len);
    
    if (len < MIN_MEASUREMENTS) {
        DLog(@"error: less measurement: %d\n", len);
        return 0;
    }
       
    NSMutableArray *a_linear_rm = [self removeGravity:times withAccel:a_vert_rm];
    NSMutableArray *a_adjusted_rm = [self adjustAccelFromRM:times withAccel:a_linear_rm];
    
    NSMutableArray *a_v = a_adjusted_rm;
    NSMutableArray *v_v = [self getVelocity:times withAccel:a_v];
    NSMutableArray *d_v = [self getDisplacement:times withAccel:a_v withVelocity:v_v];
    
    int step_num = 0;
    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            step_num++;
        }
    }
    NSMutableArray *steps = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *step_amp = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_heading = [[NSMutableArray alloc] initWithCapacity:step_num];
    //NSMutableArray *step_heading_accuracy = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_d = [[NSMutableArray alloc] initWithCapacity:step_num];
    int step_index = -1;
    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            step_index++;
            [step_amp addObject:[a_amp objectAtIndex:i]];
            [step_heading addObject:[heading_lpf objectAtIndex:i]];
            [step_d addObject:[d_v objectAtIndex:i]];
        }
        [steps addObject:[NSNumber numberWithInt:step_index]];
    }
    
    if (step_num == 0) {
        DLog(@"error: no steps: %d\n", step_index);
        return 0;
    }
    DLog(@"step_num: %d step_index: %d", step_num, step_index);
    double step_amp_max = [[step_amp valueForKeyPath:@"@max.doubleValue"] doubleValue];
    double step_amp_min = [[step_amp valueForKeyPath:@"@min.doubleValue"] doubleValue];
    double step_amp_ave = [[step_amp valueForKeyPath:@"@avg.doubleValue"] doubleValue];
    

    // landing detection
    NSMutableArray *step_stat_by_accel = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_stat_by_magneto = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_stat_by_dist = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_stat_by_all = [[NSMutableArray alloc] initWithCapacity:step_num];
    
    double amp_diff = 0;
    double amp_diff_max = step_amp_max - step_amp_ave;
    double amp_diff_min = step_amp_min - step_amp_ave;
    for (int i = 0; i < step_num; i++) {
        amp_diff = [[step_amp objectAtIndex:i] doubleValue] - step_amp_ave;
        if (amp_diff >= 0) {
            [step_stat_by_accel addObject:[NSNumber numberWithDouble:(amp_diff / amp_diff_max)]];
        } else {
            [step_stat_by_accel addObject:[NSNumber numberWithDouble:(amp_diff / amp_diff_min) * -1]];
        }
    }
    
    double heading_diff = 0;
    [step_stat_by_magneto addObject:[NSNumber numberWithDouble:0.0]];
    for (int i = 1; i < step_num; i++) {
        heading_diff = [self diffAngles:[[step_heading objectAtIndex:i] doubleValue] withAngle:[[step_heading objectAtIndex:i - 1] doubleValue]];
        [step_stat_by_magneto addObject:[NSNumber numberWithDouble:(heading_diff / GAMMA * -2) + 1]];
    }
    
    double dist_diff = 0;
    double dist_diff_max = 0;
    [step_stat_by_dist addObject:[NSNumber numberWithDouble:0.0]];
    for (int i = 1; i < step_num; i++) {
        dist_diff = [self getAbsolute:([[step_d objectAtIndex:i - 1] doubleValue] - [[step_d objectAtIndex:i] doubleValue])];
        if (dist_diff > dist_diff_max) {
            dist_diff_max = dist_diff;
        }
    }
    for (int i = 1; i < step_num; i++) {
        dist_diff = [self getAbsolute:([[step_d objectAtIndex:i - 1] doubleValue] - [[step_d objectAtIndex:i] doubleValue])];
        [step_stat_by_dist addObject:[NSNumber numberWithDouble:(dist_diff / dist_diff_max * 2) - 1]];
    }
    
    double st_ac = 0;
    double st_ma = 0;
    double st_di = 0;
    for (int i = 0; i < step_num; i++) {
        st_ac = [[step_stat_by_accel objectAtIndex:i] doubleValue];
        st_ma = [[step_stat_by_magneto objectAtIndex:i] doubleValue];
        st_di = [[step_stat_by_dist objectAtIndex:i] doubleValue];
        if (st_ac < -0.5) {
            st_ac = st_ac * 2;
        }
        if (st_ma < -0.5) {
            st_ma = st_ma * 2;
        }
        if (st_di < -0.5) {
            st_di = st_di * 2;
        }
        [step_stat_by_all addObject:[NSNumber numberWithDouble:(3 * st_ac + 2 * st_ma + st_di) / 5]];
    }
    
    if (index == 4) {
        //[self printArray:step_stat_by_all];
    }
    
    
    // adjust landing detection part 1
    for (int i = 0; i < step_num-2; i++) {
        if ([[step_stat_by_all objectAtIndex:i] doubleValue] * [[step_stat_by_all objectAtIndex:i + 1] doubleValue] <= 0 &&
            [[step_stat_by_all objectAtIndex:i + 1] doubleValue] * [[step_stat_by_all objectAtIndex:i + 2] doubleValue] <= 0) {
            if ([self getAbsolute:[[step_stat_by_all objectAtIndex:i + 1] doubleValue]] < [self getAbsolute:[[step_stat_by_all objectAtIndex:i] doubleValue]] ||
                [self getAbsolute:[[step_stat_by_all objectAtIndex:i + 1] doubleValue]] < [self getAbsolute:[[step_stat_by_all objectAtIndex:i + 2] doubleValue]]) {
                [step_stat_by_all replaceObjectAtIndex:(i + 1) withObject:[NSNumber numberWithDouble:[[step_stat_by_all objectAtIndex:i + 1] doubleValue] * -1]];
            }
        }
    }
    
    NSMutableArray *step_stat = [[NSMutableArray alloc] initWithCapacity:step_num];
    for (int i = 0; i < step_num; i++) {
        if ([[step_stat_by_all objectAtIndex:i] doubleValue] > 0) {
            [step_stat addObject:[NSNumber numberWithInt:1]];
        } else {
            [step_stat addObject:[NSNumber numberWithInt:0]];
        }
    }
    
    int st_index = 0;
    int st_stat = 0;
    NSMutableArray *time_stat = [[NSMutableArray alloc] initWithCapacity:len];
    for (int i = 0; i < len; i++) {
        st_index = [[steps objectAtIndex:i] intValue];
        if (st_index > 0 && st_index < step_num - 1) {
            st_stat = [[step_stat objectAtIndex:st_index] intValue];
        } else {
            st_stat = 0;
        }
        [time_stat addObject:[NSNumber numberWithInt:st_stat]];
    }
    NSMutableArray *v_zupt = [self getVelocityWithZUPTForWalking:times withAccel:a_v withStat:time_stat];
    NSMutableArray *d_zupt = [self getDisplacement:times withAccel:a_v withVelocity:v_zupt];
    
    
    NSMutableArray *step_v_zupt = [[NSMutableArray alloc] initWithCapacity:step_num];
    NSMutableArray *step_d_zupt = [[NSMutableArray alloc] initWithCapacity:step_num];
    
    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            [step_v_zupt addObject:[v_zupt objectAtIndex:i]];
            [step_d_zupt addObject:[d_zupt objectAtIndex:i]];
        }
    }
    
    if ([[step_stat objectAtIndex:step_num - 1] intValue] == 0 && [[step_stat objectAtIndex:step_num - 2] intValue] == 1) {
        [step_stat replaceObjectAtIndex:step_num - 2 withObject:[NSNumber numberWithInt:0]];
    }
    
    int start_index = -1;
    int end_index = -1;
    int ss_index = -1;
    int ee_index = -1;
    double dist_diff_prev = 0;
    double dist_diff_cur = 0;
    int gap = 0;
    double confidence_prev = 0;
    double confidence_cur = 0;
    
    [step_stat replaceObjectAtIndex:step_num - 1 withObject:[NSNumber numberWithInt:1]];
    NSMutableArray *step_stat_out = [[NSMutableArray alloc] initWithArray:step_stat copyItems:YES];
    NSMutableArray *step_direction = [self zerosWithInt:step_num];
    
    for (int i = 0; i < step_num - 1; i++) {
        
        if ([[step_stat objectAtIndex:i] intValue] == 1 && [[step_stat objectAtIndex:i + 1] intValue] == 0) {
            start_index = i + 1;
        } else if ([[step_stat objectAtIndex:i] intValue] == 0 && [[step_stat objectAtIndex:i + 1] intValue] == 1) {
            end_index = i;
            if (start_index != -1) {
                for (int j = start_index - 1; j > 0; j--) {
                    if ([[step_stat objectAtIndex:j] intValue] == 0) {
                        ss_index = j;
                        break;
                    }
                }
                ss_index = ss_index + 1;
                ee_index = start_index - 1;
                
                dist_diff_prev = [self getAbsolute:([[step_d_zupt objectAtIndex:ee_index] doubleValue] - [[step_d_zupt objectAtIndex:ss_index] doubleValue])];
                dist_diff_cur = [self getAbsolute:([[step_d_zupt objectAtIndex:end_index] doubleValue] - [[step_d_zupt objectAtIndex:start_index] doubleValue])];
                gap = ee_index - ss_index + 1;
                
                if (ee_index - ss_index + 1 > 3) {
                    confidence_prev = [self getAverage:step_stat_by_all from:ss_index + 1 to:ee_index - 1];
                } else {
                    confidence_prev = 0;
                }
                if (end_index - start_index + 1 > 3) {
                    confidence_cur = [self getAverage:step_stat_by_all from:start_index + 1 to:end_index - 1];
                } else {
                    confidence_cur = 0;
                }
                if (confidence_prev < 0.5 && gap > MIN_STAIR_NUM && dist_diff_prev < MIN_STAIR_HEIGHT) {
                    for (int j = ss_index; j <= ee_index; j++) {
                        [step_stat_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:0]];
                    }
                }
                
                if ((confidence_prev < 0.5 && [[step_stat objectAtIndex:ss_index] intValue] == 1 && dist_diff_prev < MIN_STAIR_HEIGHT * 0.5) ||
                    (dist_diff_cur > MIN_STAIR_HEIGHT)) {
                    for (int j = start_index; j <= end_index; j++) {
                        [step_stat_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:1]];
                    }
                } else {
                    if ([[step_d_zupt objectAtIndex:start_index] doubleValue] > [[step_d_zupt objectAtIndex:ss_index] doubleValue]) {
                        for (int j = start_index; j <= end_index; j++) {
                            [step_direction replaceObjectAtIndex:j withObject:[NSNumber numberWithInt: 1]];
                        }
                    } else {
                        for (int j = start_index; j <= end_index; j++) {
                            [step_direction replaceObjectAtIndex:j withObject:[NSNumber numberWithInt: -1]];
                        }
                    }
                }
            }
            start_index = -1;
        }
    }
    step_stat = step_stat_out;
    [step_stat replaceObjectAtIndex:step_num - 1 withObject:[NSNumber numberWithInt:0]];
    
    // adjust landing detection part 3
    start_index = -1;
    end_index = -1;
    step_stat_out = [[NSMutableArray alloc] initWithArray:step_stat copyItems:YES];
    for (int i = 0; i < step_num - 1; i++) {
        if ([[step_stat objectAtIndex:i] intValue] == 0 && [[step_stat objectAtIndex:i + 1] intValue] == 1) {
            start_index = i + 1;
        } else if ([[step_stat objectAtIndex:i] intValue] == 1 && [[step_stat objectAtIndex:i + 1] intValue] == 0) {
            if (start_index != -1) {
                end_index = i;
                gap = end_index - start_index;
                if (gap < MIN_STAIR_NUM || gap > MAX_STAIR_NUM) {
                    for (int j = start_index; j <= end_index; j++) {
                        [step_stat_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:0]];
                    }
                }
            }
            start_index = -1;
        }
    }
    step_stat = step_stat_out;
    
    double moved_floors = 0;
    double tmp = 0;
    for (int i = 0; i < step_num - 1; i++) {
        if ([[step_stat objectAtIndex:i] intValue] == 1 && [[step_stat objectAtIndex:i + 1] intValue] == 0) {
            tmp = ([[step_direction objectAtIndex:i + 1] intValue] / [self.buildingInfo.numOfLandings doubleValue]);
            DLog(@"landing: %d, floor: %f", [[step_direction objectAtIndex:i + 1] intValue], tmp);
            moved_floors += tmp;
        }
    }
    DLog(@"moved floor: %f", moved_floors);
    return moved_floors;
}

@end
