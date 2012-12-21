//
//  AnalysisModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "AnalysisModule.h"
#import "Logger.h"

@implementation AnalysisModule

@synthesize buildingInfo;
@synthesize measurement;
@synthesize curFloor;
@synthesize curDisplacement;
@synthesize managedObjectContext = _managedObjectContext;

- (id)initWithData:(Measurement *)data {
    self = [super init];
    if (self) {
        self.measurement = data;
        self.curFloor = 0;
        self.curDisplacement = 0;
        self.movedFloor = 0;
        self.movedDisplacement = 0;
    }
    return self;
}

- (int)getFrequency:(NSArray *)time {
    int len = [time count];
    int index = 0;
    if (len > 100) {
        index = 100;
    } else {
        index = len;
    }
    int freq = round((double)(1.0 / (([[time objectAtIndex:index-1] doubleValue] - [[time objectAtIndex:0] doubleValue]) / index)));
    return freq;
}

- (int)find:(NSArray *)array startIndex:(int)start_index endIndex:(int)end_index withMode:(NSString *)mode {
    int result = 0;
    for (int i = start_index; i <= end_index; i++) {
        if ([[array objectAtIndex:i] doubleValue] != 0) {
            result = i;
            if ([mode isEqualToString:@"first"]) {
                break;
            }
        }
    }
    return result;
}

- (double)getAbsolute:(double)value {
    if (value < 0.0) return value * -1;
    else return value;
}

- (double)getAbsoluteMax:(NSArray *)array {
    double max = DBL_MIN;
    for (int i = 0; i < [array count]; i++) {
        double value = [self getAbsolute:[[array objectAtIndex:i] doubleValue]];
        if (value > max) {
            max = value;
        }
    }
    return max;
}

- (double)diffAngles:(double)a1 withAngle:(double)a2 {
    double diff = [self getAbsolute:(a1 - a2)];
    if (diff > 180) {
        return [self getAbsolute:(diff - 360)];
    } else {
        return diff;
    }
}

- (double)getAverage:(NSArray *)array from:(int)i1 to:(int)i2 {
    double sum = 0;
    for (int i = i1; i <= i2; i++) {
        sum += [[array objectAtIndex:i] doubleValue];
    }
    return sum / (i2 - i1 + 1);
}

- (double)getMax:(NSArray *)array from:(int)i1 to:(int)i2 {
    double max = DBL_MIN;
    double value = 0;
    for (int i = i1; i <= i2; i++) {
        value = [[array objectAtIndex:i] doubleValue];
        if (value > max) {
            max = value;
        }
    }
    return max;
}

- (NSArray *)getArray:(NSArray *)array from:(int)i1 to:(int)i2 {
    int len = i2 - i1 + 1;
    if (len <= 0) {
        return nil;
    }
    int index = i1;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:len];
    for (int i = 0; i < len; i++) {
        [result addObject:[array objectAtIndex:index]];
        index++;
    }
    return result;
}

- (void)printArray:(NSArray *)array {
    for (int i = 0; i < [array count]; i++) {
        NSLog(@"%d: %@", i + 1, [array objectAtIndex:i]);
    }
}

- (NSMutableArray *)zerosWithInt:(int)len {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:len];
    for (int i = 0; i < len; i++) {
        [result addObject:[NSNumber numberWithInt:0]];
    }
    return result;
}

- (NSMutableArray *)zerosWithDouble:(int)len {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:len];
    for (int i = 0; i < len; i++) {
        [result addObject:[NSNumber numberWithDouble:0]];
    }
    return result;
}

- (NSMutableArray *)lowPassFilter:(NSArray *)array withAlpha:(double)alpha {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    [result addObject:[array objectAtIndex:0]];
    for (int i = 1; i < [array count]; i++) {
        [result addObject:[NSNumber numberWithDouble:[[array objectAtIndex:i] doubleValue] * alpha + [[result objectAtIndex:(i - 1)] doubleValue] * (1 - alpha)]];
    }
    return result;
}

- (NSMutableArray *)cutOffDecimal:(NSArray *)array withPosition:(int)num {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    for (int i = 0; i < [array count]; i++) {
        double value = [[array objectAtIndex:i] doubleValue];
        double tmp = 0.0;
        
        if (value < 0.01 && value > -0.01) {
            if (value > 0) {
                tmp = floor(value * pow(10, num)) / pow(10, num);
            } else if (value < 0) {
                tmp = ceil(value * pow(10, num)) / pow(10, num);
            }
        } else {
            tmp = value;
        }
        [result addObject:[NSNumber numberWithDouble:tmp]];
    }
    return result;
}

- (NSMutableArray *)getVelocity:(NSArray *)time withAccel:(NSArray *)accel {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[time count]];
    [result addObject:[NSNumber numberWithDouble:0.0]];
    
    for (int i = 1; i < [time count]; i++) {
        double delta = [[time objectAtIndex:i] doubleValue] - [[time objectAtIndex:(i - 1)] doubleValue];
        double tmp = [[result objectAtIndex:(i - 1)] doubleValue] + [[accel objectAtIndex:(i - 1)] doubleValue] * delta;        
        [result addObject:[NSNumber numberWithDouble:tmp]];
    }
    return result;
}

- (NSMutableArray *)getDisplacement:(NSArray *)time withAccel:(NSArray *)accel withVelocity:(NSArray *)velocity {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[time count]];
    [result addObject:[NSNumber numberWithDouble:0.0]];
    
    for (int i = 1; i < [time count]; i++) {
        double delta = [[time objectAtIndex:i] doubleValue] - [[time objectAtIndex:(i - 1)] doubleValue];
        double tmp = [[result objectAtIndex:(i - 1)] doubleValue] + [[velocity objectAtIndex:(i - 1)] doubleValue] * delta +
                     0.5 * [[accel objectAtIndex:(i - 1)] doubleValue] * pow(delta, 2);
        [result addObject:[NSNumber numberWithDouble:tmp]];
    }
    return result;
}


- (NSMutableArray *)removeGravity:(NSArray *)time withAccel:(NSArray *)accel {
    int len = [time count];
    int freq = [self getFrequency:time];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:len];
    
    double sum = 0;
    for (int i = freq; i < len; i++) {
        sum += [[accel objectAtIndex:i] doubleValue];
    }
    double a_gravity = sum / (len - freq);
    
    DLog("gravity: %f", a_gravity);
    
    for (int i = 0; i < len; i++) {
        double tmp = [[accel objectAtIndex:i] doubleValue] - a_gravity;
        [result addObject:[NSNumber numberWithDouble:tmp]];
    }
    return result;
}

- (NSMutableArray *)getVertAccelFromRM:(NSArray *)time withX:(NSArray *)x withY:(NSArray *)y withZ:(NSArray *)z
                               withM11:(NSArray *)m11 withM12:(NSArray *)m12 withM13:(NSArray *)m13
                               withM21:(NSArray *)m21 withM22:(NSArray *)m22 withM23:(NSArray *)m23
                               withM31:(NSArray *)m31 withM32:(NSArray *)m32 withM33:(NSArray *)m33 {
    int len = [time count];
    int freq = [self getFrequency:time];
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:len];
    
    double alpha = (1.0 / freq) / (1.0 / freq + (1.0 / (freq / 2.0)));
    
    NSArray *a_x_lpf = [self lowPassFilter:x withAlpha:alpha];
    NSArray *a_y_lpf = [self lowPassFilter:y withAlpha:alpha];
    NSArray *a_z_lpf = [self lowPassFilter:z withAlpha:alpha];
    
    for (int i = 0; i < len; i++) {
        double tmp = [[m13 objectAtIndex:i] doubleValue] * [[a_x_lpf objectAtIndex:i] doubleValue] +
        [[m23 objectAtIndex:i] doubleValue] * [[a_y_lpf objectAtIndex:i] doubleValue] +
        [[m33 objectAtIndex:i] doubleValue] * [[a_z_lpf objectAtIndex:i] doubleValue];
        [result addObject:[NSNumber numberWithDouble:(tmp * -1)]];
    }
    return result;
}

- (NSMutableArray *)getVertAccelFromVS:(NSArray *)time withX:(NSArray *)x withY:(NSArray *)y withZ:(NSArray *)z {
    int len = [time count];
    int freq = [self getFrequency:time];
    double alpha = (1.0 / freq) / (1.0 / freq + (1.0 / (freq / 2.0)));
    
    NSArray *a_x_lpf = [self lowPassFilter:x withAlpha:alpha];
    NSArray *a_y_lpf = [self lowPassFilter:y withAlpha:alpha];
    NSArray *a_z_lpf = [self lowPassFilter:z withAlpha:alpha];
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:len];
    for (int i = 0; i < len; i++) {
        double tmp = sqrt((pow([[a_x_lpf objectAtIndex:i] doubleValue], 2) +
                           pow([[a_y_lpf objectAtIndex:i] doubleValue], 2) +
                           pow([[a_z_lpf objectAtIndex:i] doubleValue], 2)));
        [result addObject:[NSNumber numberWithDouble:tmp]];
    }
    return result;
}

- (NSMutableArray *)adjustAccelFromVS:(NSArray *)time withAccel:(NSMutableArray *)accel {
    int len = [time count];
    int freq = [self getFrequency:time];
    
    NSMutableArray *a_adjusted = [[NSMutableArray alloc] initWithArray:accel copyItems:YES];
    
    if ([[time objectAtIndex:freq] doubleValue] < 2.0) {
        for (int i = 0; i < freq; i++) {
            [a_adjusted replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0.0]];
        }
        for (int i = len - freq - 1; i < len; i++) {
            [a_adjusted replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0.0]];
        }
    }
    
    int offset = 0.5 * freq;
    int last_index = 0;
    for (int i = 0; i < len; i++) {
        if ([[a_adjusted objectAtIndex:i] doubleValue] == 0.0) {
            if (i - last_index < offset) {
                for (int j = last_index; j <= i; j++) {
                    [a_adjusted replaceObjectAtIndex:j withObject:[NSNumber numberWithDouble:0.0]];
                }
            }
            last_index = i;
        }
    }
    return a_adjusted;
}

- (NSMutableArray *)adjustAccelFromRM:(NSArray *)time withAccel:(NSMutableArray *)accel {
    int freq = [self getFrequency:time];
    
    NSMutableArray *a_adjusted = [[NSMutableArray alloc] initWithArray:accel copyItems:YES];
    if ([[time objectAtIndex:freq] doubleValue] < 2.0) {
        for (int i = 0; i < freq; i++) {
            [a_adjusted replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0.0]];
        }
    }
    return a_adjusted;
}

- (StepResult *)stepDetection:(NSArray *)time withAccel:(NSArray *)accel {
    
    int len = [time count];
    int freq = [self getFrequency:time];
    
    NSMutableArray *a_amp = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_max = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_min = [[NSMutableArray alloc] initWithCapacity:len];
    double local_max = 0;
    double local_min = 0;
    int local_max_t = 0;
    int local_min_t = 0;
    
    [a_amp addObject:[NSNumber numberWithDouble:0.0]];
    [a_max addObject:[NSNumber numberWithDouble:0.0]];
    [a_min addObject:[NSNumber numberWithDouble:0.0]];
    
    for (int i = 1; i < len - 1; i++) {
        
        [a_amp addObject:[NSNumber numberWithDouble:0.0]];
        [a_max addObject:[NSNumber numberWithDouble:0.0]];
        [a_min addObject:[NSNumber numberWithDouble:0.0]];
        
        double diff_p = ([[accel objectAtIndex:i] doubleValue] - [[accel objectAtIndex:i-1] doubleValue]) /
        ([[time objectAtIndex:i] doubleValue] - [[time objectAtIndex:i-1] doubleValue]);
        double diff_n = ([[accel objectAtIndex:i+1] doubleValue] - [[accel objectAtIndex:i] doubleValue]) /
        ([[time objectAtIndex:i+1] doubleValue] - [[time objectAtIndex:i] doubleValue]);
        if (diff_p > 0 && diff_n <= 0 && [[accel objectAtIndex:i] doubleValue] > 0 && [[accel objectAtIndex:i] doubleValue] >= local_max) {
            if (local_max != 0) {
                [a_max replaceObjectAtIndex:local_max_t withObject:[NSNumber numberWithDouble:0.0]];
            }
            [a_max replaceObjectAtIndex:i withObject:[accel objectAtIndex:i]];
            local_max = [[a_max objectAtIndex:i] doubleValue];
            local_max_t = i;
            local_min = 0.0;
        } else if (diff_p < 0 && diff_n >= 0 && [[accel objectAtIndex:i] doubleValue] < 0 && [[accel objectAtIndex:i] doubleValue] <= local_min) {
            if (local_min != 0) {
                [a_min replaceObjectAtIndex:local_min_t withObject:[NSNumber numberWithDouble:0.0]];
                [a_amp replaceObjectAtIndex:local_min_t withObject:[NSNumber numberWithDouble:0.0]];
                if (local_max_t != 0) {
                    local_max = [[a_max objectAtIndex:local_max_t] doubleValue];
                }
            }
            [a_min replaceObjectAtIndex:i withObject:[accel objectAtIndex:i]];
            local_min = [[a_min objectAtIndex:i] doubleValue];
            local_min_t = i;

            if (local_max > 0 && i - local_max_t < freq * MAX_STEP_PERIOD) {
                [a_amp replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:[self getAbsolute:(local_max - local_min)]]];
            }
            local_max = 0.0;
        }
    }
    [a_amp addObject:[NSNumber numberWithDouble:0.0]];
    [a_max addObject:[NSNumber numberWithDouble:0.0]];
    [a_min addObject:[NSNumber numberWithDouble:0.0]];
    
    double a_amp_ave = 0;
    int a_amp_num = 0;
    double a_amp_gap = 0;
    
    int index_prev = 0;
    int index_next = 0;
    int index_cur = 0;
    for (int i = 0; i < len; i++) {
        index_prev = -1;
        index_next = -1;

        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            index_cur = i;
            for (int j = i - 1; j > 0; j--) {
                if ([[a_amp objectAtIndex:j] doubleValue] != 0) {
                    index_prev = j;
                    break;
                }
            }
            for (int j = i + 1; j < len; j++) {
                if ([[a_amp objectAtIndex:j] doubleValue] != 0) {
                    index_next = j;
                    break;
                }
            }
            if (index_prev == -1 || index_next == -1) {
                continue;
            }
            if (index_cur - index_prev <= index_next - index_cur) {
                if ((index_cur - index_prev < freq * MIN_STEPS_GAP &&
                    [[a_amp objectAtIndex:index_prev] doubleValue] > [[a_amp objectAtIndex:index_cur] doubleValue] * 3) ||
                    index_cur - index_prev > freq * MAX_STEPS_GAP) {
                    [a_amp replaceObjectAtIndex:index_cur withObject:[NSNumber numberWithDouble:0.0]];
                }
            } else {
                if ((index_next - index_cur < freq * MIN_STEPS_GAP &&
                     [[a_amp objectAtIndex:index_next] doubleValue] > [[a_amp objectAtIndex:index_cur] doubleValue] * 3) ||
                    index_next - index_cur > freq * MAX_STEPS_GAP) {
                    [a_amp replaceObjectAtIndex:index_cur withObject:[NSNumber numberWithDouble:0.0]];
                }
            }
            
            if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
                a_amp_ave += [[a_amp objectAtIndex:i] doubleValue];
                a_amp_num++;
                a_amp_gap += (i - index_prev);
            }
        }
    }
    
    if (a_amp_num != 0) {
        a_amp_ave /= a_amp_num;
        a_amp_gap /= a_amp_num;
    } else {
        a_amp_ave = 0;
        a_amp_gap = 0;
    }
    
    if (a_amp_gap > MAX_STEPS_GAP * freq) {
        a_amp_gap = MAX_STEPS_GAP;
    }
    if (a_amp_ave < MIN_STEP_AMP) {
        a_amp_ave = MIN_STEP_AMP;
    }
    
    StepResult *result = [[StepResult alloc] init];
    result.a_amp_ave = [NSNumber numberWithDouble:a_amp_ave];
    result.a_amp_num = [NSNumber numberWithInt:a_amp_num];
    result.a_amp_gap = [NSNumber numberWithDouble:a_amp_gap];
    result.a_amp = a_amp;
    result.a_max = a_max;
    result.a_min = a_min;

    return result;
}

- (StepResult *)velocityDetection:(NSArray *)time withVelocity:(NSArray *)velocity {
    
    int len = [time count];
    int freq = [self getFrequency:time];
    
    NSMutableArray *a_amp = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_max = [[NSMutableArray alloc] initWithCapacity:len];
    NSMutableArray *a_min = [[NSMutableArray alloc] initWithCapacity:len];
    double local_max = -100;
    double local_min = 100;
    int local_max_t = 0;
    int local_min_t = 0;
    
    [a_amp addObject:[NSNumber numberWithDouble:0.0]];
    [a_max addObject:[NSNumber numberWithDouble:0.0]];
    [a_min addObject:[NSNumber numberWithDouble:0.0]];
    
    for (int i = 1; i < len - 1; i++) {
        
        [a_amp addObject:[NSNumber numberWithDouble:0.0]];
        [a_max addObject:[NSNumber numberWithDouble:0.0]];
        [a_min addObject:[NSNumber numberWithDouble:0.0]];
        
        double diff_p = ([[velocity objectAtIndex:i] doubleValue] - [[velocity objectAtIndex:i-1] doubleValue]) /
        ([[time objectAtIndex:i] doubleValue] - [[time objectAtIndex:i-1] doubleValue]);
        double diff_n = ([[velocity objectAtIndex:i+1] doubleValue] - [[velocity objectAtIndex:i] doubleValue]) /
        ([[time objectAtIndex:i+1] doubleValue] - [[time objectAtIndex:i] doubleValue]);
        if (diff_p > 0 && diff_n <= 0 && [[velocity objectAtIndex:i] doubleValue] >= local_max) {
            if (local_max != -100) {
                [a_max replaceObjectAtIndex:local_max_t withObject:[NSNumber numberWithDouble:0.0]];
            }
            [a_max replaceObjectAtIndex:i withObject:[velocity objectAtIndex:i]];
            local_max = [[a_max objectAtIndex:i] doubleValue];
            local_max_t = i;
            local_min = 100;
        } else if (diff_p < 0 && diff_n >= 0 && [[velocity objectAtIndex:i] doubleValue] <= local_min) {
            if (local_min != 100) {
                [a_min replaceObjectAtIndex:local_min_t withObject:[NSNumber numberWithDouble:0.0]];
                [a_amp replaceObjectAtIndex:local_min_t withObject:[NSNumber numberWithDouble:0.0]];
                if (local_max_t != 0) {
                    local_max = [[a_max objectAtIndex:local_max_t] doubleValue];
                }
            }
            if (local_max == -100) {
                continue;
            }
            [a_min replaceObjectAtIndex:i withObject:[velocity objectAtIndex:i]];
            local_min = [[a_min objectAtIndex:i] doubleValue];
            local_min_t = i;
            
            [a_amp replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:[self getAbsolute:(local_max - local_min)]]];
            local_max = -100;
        }
    }
    [a_amp addObject:[NSNumber numberWithDouble:0.0]];
    [a_max addObject:[NSNumber numberWithDouble:0.0]];
    [a_min addObject:[NSNumber numberWithDouble:0.0]];
    
    double a_amp_ave = 0;
    int a_amp_num = 0;
    double a_amp_gap = 0;
    
    int index_prev = 0;
    int index_next = 0;
    int index_cur = 0;
    for (int i = 0; i < len; i++) {
        index_prev = -1;
        index_next = -1;
        
        if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
            index_cur = i;
            for (int j = i - 1; j > 0; j--) {
                if ([[a_amp objectAtIndex:j] doubleValue] != 0) {
                    index_prev = j;
                    break;
                }
            }
            for (int j = i + 1; j < len; j++) {
                if ([[a_amp objectAtIndex:j] doubleValue] != 0) {
                    index_next = j;
                    break;
                }
            }
            if (index_prev == -1 || index_next == -1) {
                continue;
            }
            if (index_cur - index_prev <= index_next - index_cur) {
                if ((index_cur - index_prev < freq * MIN_STEPS_GAP &&
                     [[a_amp objectAtIndex:index_prev] doubleValue] > [[a_amp objectAtIndex:index_cur] doubleValue] * 3) ||
                    index_cur - index_prev > freq * MAX_STEPS_GAP) {
                    [a_amp replaceObjectAtIndex:index_cur withObject:[NSNumber numberWithDouble:0.0]];
                }
            } else {
                if ((index_next - index_cur < freq * MIN_STEPS_GAP &&
                     [[a_amp objectAtIndex:index_next] doubleValue] > [[a_amp objectAtIndex:index_cur] doubleValue] * 3) ||
                    index_next - index_cur > freq * MAX_STEPS_GAP) {
                    [a_amp replaceObjectAtIndex:index_cur withObject:[NSNumber numberWithDouble:0.0]];
                }
            }
            
            if ([[a_amp objectAtIndex:i] doubleValue] != 0) {
                a_amp_ave += [[a_amp objectAtIndex:i] doubleValue];
                a_amp_num++;
                a_amp_gap += (i - index_prev);
            }
        }
    }
    
    if (a_amp_num != 0) {
        a_amp_ave /= a_amp_num;
        a_amp_gap /= a_amp_num;
    } else {
        a_amp_ave = 0;
        a_amp_gap = 0;
    }
 
    StepResult *result = [[StepResult alloc] init];
    result.a_amp_ave = [NSNumber numberWithDouble:a_amp_ave];
    result.a_amp_num = [NSNumber numberWithInt:a_amp_num];
    result.a_amp_gap = [NSNumber numberWithDouble:a_amp_gap];
    result.a_amp = a_amp;
    result.a_max = a_max;
    result.a_min = a_min;
    
    return result;
}

- (NSMutableArray *)getVelocityWithZUPT:(NSArray *)time withAccel:(NSArray *)a_v {
    int len = [time count];
    NSMutableArray *v_adjusted = [self getVelocity:time withAccel:a_v];
    double v_max = [self getAbsoluteMax:v_adjusted];
    double v_gap = 0.0;
    
    for (int i = 1; i < len; i++) {
        double v = [[v_adjusted objectAtIndex:i] doubleValue];
        double a1 = [[a_v objectAtIndex:i] doubleValue];
        double a2 = [[a_v objectAtIndex:(i - 1)] doubleValue];
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
    return v_adjusted;
}

- (NSMutableArray *)getVelocityWithZUPTForWalking:(NSArray *)time withAccel:(NSArray *)a_v withStat:(NSMutableArray *)time_stat {

    int len = [time_stat count];
    int freq = [self getFrequency:time];
    NSMutableArray *v_v = [self getVelocity:time withAccel:a_v];
    NSMutableArray *v_v_zupt = [[NSMutableArray alloc] initWithArray:v_v copyItems:YES];
    
    int start_index = -1;
    int end_index = -1;
    int ss_index = -1;
    int ee_index = -1;
    int gap = 0;
    double v_landing = 0;
    [time_stat replaceObjectAtIndex:len - 1 withObject:[NSNumber numberWithInt:1]];
    for (int i = 0; i < len - 1; i++) {
        if ([[time_stat objectAtIndex:i] intValue] == 1 && [[time_stat objectAtIndex:i + 1] intValue] == 0) {
            start_index = i + 1;
        } else if ([[time_stat objectAtIndex:i] intValue] == 0 && [[time_stat objectAtIndex:i + 1] intValue] == 1) {
            end_index = i;
            if (start_index != -1) {
                for (int j = start_index - 1; j > 0; j--) {
                    if ([[time_stat objectAtIndex:j] intValue] == 0) {
                        ss_index = j;
                        break;
                    }
                }
                ss_index = ss_index + 1;
                ee_index = start_index - 1;
                gap = ee_index - ss_index + 1;
                if (gap < MAX_STEP_PERIOD * freq * MAX_STAIR_NUM) {
                    v_landing = [self getAverage:v_v from:start_index to:end_index];
                    for (int j = ss_index; j <= ee_index; j++) {
                        [v_v_zupt replaceObjectAtIndex:j withObject:[NSNumber numberWithDouble:([[v_v objectAtIndex:j] doubleValue] - v_landing)]];
                    }
                    for (int j = start_index; j <= end_index; j++) {
                        [v_v_zupt replaceObjectAtIndex:j withObject:[NSNumber numberWithDouble:([[v_v objectAtIndex:j] doubleValue] - v_landing)]];
                    }
                }
                
            }
            start_index = -1;
        }
    }
    [time_stat replaceObjectAtIndex:len - 1 withObject:[NSNumber numberWithInt:0]];
    return v_v_zupt;
}

- (void)run {
    // will be override by child
}

@end
