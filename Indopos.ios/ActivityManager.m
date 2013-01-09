//
//  ActivityManager.m
//  Indopos.ios
//
//  Created by Wonsang Song on 12/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "ActivityManager.h"
#import "SensorData.h"
#import "Logger.h"
#import "ElevatorModule.h"
#import "StairwayModule.h"
#import "History.h"


@implementation ActivityManager

- (void)run {
    int len = [self.measurement.measurements count];
    DLog(@"activity run: %d", len);

    NSMutableArray *dates = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *times = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_x = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_y = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_z = [[NSMutableArray alloc] initWithCapacity:len];
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
    NSMutableArray *heading_accuracy = [[NSMutableArray alloc] initWithCapacity:len];
    
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
        [heading_accuracy addObject:sensorData.headingAccuracy];
        
        [times addObject:sensorData.time];
        [dates addObject:sensorData.date];
    }
    
    NSDate *historyKey = [NSDate date];
    
    NSMutableArray *a_vert_vs = [self getVertAccelFromVS:times withX:a_x withY:a_y withZ:a_z];
    NSMutableArray *a_vert_rm = [self getVertAccelFromRM:times withX:a_x withY:a_y withZ:a_z withM11:m11 withM12:m12 withM13:m13 withM21:m21 withM22:m22 withM23:m23 withM31:m31 withM32:m32 withM33:m33];
    NSMutableArray *a_linear_rm = [self removeGravity:times withAccel:a_vert_rm];
    NSMutableArray *a_adjusted_rm = [self adjustAccelFromRM:times withAccel:a_linear_rm];
    NSMutableArray *a_vert = a_adjusted_rm;
    
    int freq = [self getFrequency:times];
    double alpha = (1.0 / freq) / (1.0 / freq + (1.0 / (freq / 2.0)));
    NSMutableArray *heading_lpf = [self lowPassFilter:heading withAlpha:alpha];
    
    // step detection
    StepResult *stepResult = [self stepDetection:times withAccel:a_vert];
    NSArray *a_amp = stepResult.a_amp;
    NSArray *a_max = stepResult.a_max;
    double a_amp_ave = [stepResult.a_amp_ave doubleValue];
    double a_amp_gap = [stepResult.a_amp_gap doubleValue];
    
    // detect elevator
    NSMutableArray *activity = [self zerosWithInt:len];
    double a_value = 0;
    int gap = 0;
    int start_index = -1;
    int end_index = -1;
    for (int i = 0; i < len; i++) {
        a_value = [[a_vert objectAtIndex:i] doubleValue];
        if (a_value != 0) {
            start_index = i;
            for (int j = i + 1; j < len - 1; j++) {
                if ([[a_vert objectAtIndex:j] doubleValue] * a_value <= 0 && [[a_vert objectAtIndex:j + 1] doubleValue] * a_value <= 0) {
                    end_index = j;
                    break;
                }
            }
            gap = end_index - start_index + 1;
            if (gap > MIN_ELEVATOR_ACCEL_PERIOD * freq) {
                for (int j = start_index; j <= end_index; j++) {
                    [activity replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:2]];
                }
            }
            if (i < end_index) {
                i = end_index;
            }
        }
    }
    
    // detect walking
    int step_margin = round(a_amp_gap * 0.3);
    int i_max = 0;
    int i_start = 0;
    int i_end = 0;
    for (int i = 0; i < len; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            i_max = [self find:a_max startIndex:0 endIndex:i withMode:@"last"];
            for (int j = i_max; j >= 0; j--) {
                if ([[a_vert objectAtIndex:j] doubleValue] <= 0) {
                    i_start = j;
                    break;
                }
                
            }
            for (int j = i; j < len; j++) {
                if ([[a_vert objectAtIndex:j] doubleValue] >= 0) {
                    i_end = j;
                    break;
                }
            }
            if (i_start - step_margin < 1) {
                i_start = 1;
            } else {
                i_start = i_start - step_margin;
            }
            if (i_end + step_margin > len - 1) {
                i_end = len - 1;
            } else {
                i_end = i_end + step_margin;
            }
            
            if ([self getMax:activity from:i_start to:i_end] != 2) {
                for (int k = i_start; k <= i_end; k++) {
                    [activity replaceObjectAtIndex:k withObject:[NSNumber numberWithInt:1]];
                }
            }
        }
    }
    
    // detect standing
    int dur = 0;
    int total_set_num = 2;
    for (int i = 0; i < len; i++) {
        if ([[activity objectAtIndex:i] intValue] == 2) {
            if (dur > 2 * a_amp_gap) {
                for (int j = i - dur; j <= i - 1; j++) {
                    [activity replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:0]];
                    total_set_num++;
                }
            }
            dur = 0;
        } else {
            if ([[a_amp objectAtIndex:i] doubleValue] >= a_amp_ave * 0.5 || i == len - 1) {
                if (dur > 2 * a_amp_gap) {
                    for (int j = i - dur; j <= i - 1; j++) {
                        [activity replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:0]];
                        total_set_num++;
                    }
                }
                dur = 0;
            } else {
                dur++;
            }
        }
    }
    [activity replaceObjectAtIndex:len - 1 withObject:[NSNumber numberWithInt:0]];
    
    // adjust1
    int activity_cur;
    int activity_prev = [[activity objectAtIndex:0] intValue];
    int index_prev;
    for (int i = 1; i < len; i++) {
        activity_cur = [[activity objectAtIndex:i] intValue];
        if ([[activity objectAtIndex:i] intValue] != activity_prev) {
            if (dur < MAX_STEP_PERIOD * freq) {
                for (int j = index_prev; j <= i - 1; j++) {
                    [activity replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:activity_cur]];
                }
            }
            dur = 0;
            index_prev = i;
        } else {
            dur++;
        }
        activity_prev = activity_cur;
    }
    
    // adjust2
    int num = 0;
    NSMutableArray *activity_out = [[NSMutableArray alloc] initWithArray:activity copyItems:YES];
    for (int i = 0; i < len - 1; i++) {
        if ([[activity objectAtIndex:i] intValue] != 2 && [[activity objectAtIndex:i + 1] intValue] == 2) {
            if (num == 0) {
                start_index = i + 1;
            }
        } else if ([[activity objectAtIndex:i] intValue] == 2 && [[activity objectAtIndex:i + 1] intValue] != 2) {
            end_index = i;
            num++;
            if (num == 2) {
                for (int j = start_index; j <= end_index; j++) {
                    [activity_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:2]];
                }
                num = 0;
            }
        }
    }
    activity = activity_out;
    activity_out = [[NSMutableArray alloc] initWithArray:activity copyItems:YES];

    end_index = -1;
    for (int i = 0; i < len - 1; i++) {
        if ([[activity objectAtIndex:i] intValue] != 2 && [[activity objectAtIndex:i + 1] intValue] == 2) {
            start_index = i + 1;
            if (end_index != -1) {
                if (start_index - end_index < freq * 5) {
                    for (int j = end_index; j <= start_index; j++) {
                        [activity_out replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:2]];
                    }
                }
            }
        } else if ([[activity objectAtIndex:i] intValue] == 2 && [[activity objectAtIndex:i + 1] intValue] != 2) {
            end_index = i;
        }
    }
    activity = activity_out;

    // stair adjust
    NSMutableArray *a_walking = [[NSMutableArray alloc] initWithArray:a_adjusted_rm copyItems:YES];
    for (int i = 0; i < len; i++) {
        if ([[activity objectAtIndex:i] intValue] == 2) {
            [a_walking replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0]];
        }
    }
    
    NSMutableArray *v_walking = [self getVelocity:times withAccel:a_walking];
    StepResult *velocityResult = [self velocityDetection:times withVelocity:v_walking];
    NSArray *v_amp = velocityResult.a_amp;
    double v_amp_ave = [velocityResult.a_amp_ave doubleValue];
    DLog(@"v_amp_ave: %f", v_amp_ave);
    
    NSMutableArray *stair_activity = [self zerosWithInt:len];
    index_prev = -1;
    for (int i = 0; i < len; i++) {
        if ([[v_amp objectAtIndex:i] doubleValue] > v_amp_ave * 2) {
            [stair_activity replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:1]];
            if (index_prev != -1) {
                if (i - index_prev + 1 < freq * MAX_STEP_PERIOD * 10) {
                    for (int j = index_prev; j <= i; j++) {
                        [stair_activity replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:1]];
                    }
                }
            }
            index_prev = i;
        }
    }
    
    // make activity walking during stairs
    BOOL contain_elevator = NO;
    for (int i = 0; i < len; i++) {
        if ([[stair_activity objectAtIndex:i] intValue] == 1) {
            start_index = i;
            for (int j = i + 1; j < len; j++) {
                if ([[stair_activity objectAtIndex:j] intValue] == 0) {
                    end_index = j - 1;
                    break;
                }
            }
            if (end_index > start_index) {
                contain_elevator = NO;
                for (int j = start_index; j <= end_index; j++) {
                    if ([[activity objectAtIndex:j] intValue] == 2) {
                        contain_elevator = YES;
                        break;
                    }
                }
                if (contain_elevator == NO) {
                    for (int j = start_index; j <= end_index; j++) {
                        [activity replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:1]];
                    }
                }
                i = end_index;
            }
        }
    }
    
    int el_count = 0;
    start_index = -1;
    double el_dist = 0;

    for (int i = 0; i < len - 1; i++) {
        if ([[activity objectAtIndex:i] intValue] != 2 && [[activity objectAtIndex:i + 1] intValue] == 2) {
            start_index = i + 1;
        } else if ([[activity objectAtIndex:i] intValue] == 2 && [[activity objectAtIndex:i + 1] intValue] != 2) {
            if (start_index != -1) {
                end_index = i;
                start_index = start_index - freq;
                end_index = end_index + freq;
                if (start_index < 0) {
                    start_index = 0;
                }
                if (end_index > len - 1) {
                    end_index = len - 1;
                }

                NSArray *t_set = [self getArray:times from:start_index to:end_index];
                NSArray *a_set = [self getArray:a_vert_vs from:start_index to:end_index];

                ElevatorModule *elevatorModule = [[ElevatorModule alloc] init];
                elevatorModule.buildingInfo = self.buildingInfo;
               
                DLog(@"%d: %d - %d", el_count + 1, start_index + 1, end_index + 1);

                el_dist = [elevatorModule run:t_set withAccel:a_set];
                               
                History *history = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:self.managedObjectContext];
                history.key = historyKey;
                history.time = [dates objectAtIndex:end_index];

                history.address = self.buildingInfo.address1;
                history.duration = [NSNumber numberWithInt:([[dates objectAtIndex:end_index] timeIntervalSince1970] - [[dates objectAtIndex:start_index] timeIntervalSince1970])];
                history.displacement = [NSNumber numberWithDouble:el_dist];
                history.endFloor = [NSNumber numberWithDouble:0];
                [history.managedObjectContext save:nil];
                
                el_count++;
            }
            start_index = -1;
        }
    }
    
    int upper_bound, lower_bound;
    int st_count = 0;
    start_index = -1;
    double st_floor = 0;
    
    for (int i = 0; i < len - 1; i++) {
        if (([[activity objectAtIndex:i] intValue] == 1 && [[activity objectAtIndex:i + 1] intValue] == 0 ) || i == len - 2) {
            int j = 0;
            if (i != len - 2) {
                upper_bound = MIN(len - 1, i + MAX_STANDING_PERIOD * freq);
                for (j = i + 1; j < upper_bound; j++) {
                    if ([[activity objectAtIndex:j] intValue] != 0) {
                        break;
                    }
                }
                end_index = round((double)((i + j) / 2.0));
            } else {
                end_index = i + 1;
            }
            
            if (start_index == -1) {
                continue;
            }
            dur = end_index - start_index + 1;
            if (dur < freq) {
                start_index = -1;
                continue;
            }
            
            NSArray *t_set = [self getArray:times from:start_index to:end_index];
            NSArray *a_set = [self getArray:a_vert_rm from:start_index to:end_index];
            NSArray *a_amp_set = [self getArray:a_amp from:start_index to:end_index];
            NSArray *h_set = [self getArray:heading_lpf from:start_index to:end_index];
            NSArray *ha_set = [self getArray:heading_accuracy from:start_index to:end_index];
            
            StairwayModule *stairwayModule = [[StairwayModule alloc] init];
            stairwayModule.buildingInfo = self.buildingInfo;

            DLog(@"%d: %d - %d", st_count + 1, start_index + 1, end_index + 1);

            st_floor = [stairwayModule run:t_set withAccel:a_set withAmp:a_amp_set withHeading:h_set withHeadingAccuracy:ha_set withIndex:st_count + 1];
            
            History *history = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:self.managedObjectContext];
            history.key = historyKey;
            history.time = [dates objectAtIndex:end_index];
            history.address = self.buildingInfo.address1;
            history.duration = [NSNumber numberWithInt:([[dates objectAtIndex:end_index] timeIntervalSince1970] - [[dates objectAtIndex:start_index] timeIntervalSince1970])];
            history.endFloor = [NSNumber numberWithDouble:st_floor];
            history.displacement = [NSNumber numberWithDouble:0];
            [history.managedObjectContext save:nil];
            
            st_count++;
            start_index = -1;
        } else if ([[activity objectAtIndex:i] intValue] == 0 && [[activity objectAtIndex:i + 1] intValue] == 1) {
            lower_bound = MAX(0, i - MAX_STANDING_PERIOD * freq);
            int j = 0;
            for (j = i - 1; j > lower_bound; j--) {
                if ([[activity objectAtIndex:j] intValue] != 0) {
                    break;
                }
            }
            start_index = round((double)((i + j) / 2.0));
        }
    }
    
    
    
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"History" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key == %@", historyKey];
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    double cur_dists = [self.initialDisplacement doubleValue];
    double cur_floors = [self.initialFloor doubleValue];
    double moved_dists = 0;
    double moved_floors = 0;
    double floor = 0;
    double dist = 0;
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults != nil) {
        for (int i = 0; i < [mutableFetchResults count]; i++) {
            History *history = [mutableFetchResults objectAtIndex:i];
            dist = 0;
            floor = 0;
            history.startFloor = [NSNumber numberWithDouble:cur_floors];
            if ([history.displacement doubleValue] != 0) {
                dist = [history.displacement doubleValue];
                floor = round((double)(dist / [self.buildingInfo.floorHeight doubleValue]));
            }
            if ([history.endFloor doubleValue] != 0) {
                floor = [history.endFloor doubleValue];
                dist = floor * [self.buildingInfo.floorHeight doubleValue];
            }
            moved_dists += dist;
            moved_floors += floor;
            cur_dists += dist;
            cur_floors += floor;
            history.displacement = [NSNumber numberWithDouble:dist];
            history.endFloor = [NSNumber numberWithDouble:cur_floors];
            DLog(@"history: %d, %@ [%@] %@ - %@ (%f, %f m)", i, [self.dateFormatter stringFromDate:history.time], history.duration,
                 history.startFloor, history.endFloor, floor, dist);
        }
        [self.managedObjectContext save:nil];
    }

    DLog(@"moved dist: %f, floor: %f", moved_dists, moved_floors);
    
    self.movedDisplacement = [NSNumber numberWithDouble:moved_dists];
    self.movedFloor = [NSNumber numberWithDouble:moved_floors];
    
    self.curDisplacement = [NSNumber numberWithDouble:cur_dists];
    self.curFloor = [NSNumber numberWithDouble:cur_floors];
}

@end
