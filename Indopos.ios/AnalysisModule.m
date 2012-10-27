//
//  AnalysisModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "AnalysisModule.h"

@implementation AnalysisModule

@synthesize buildingInfo;
@synthesize measurement;
@synthesize movedFloor;
@synthesize movedDisplacement;

- (id)initWithData:(Measurement *)data {
    self = [super init];
    if (self) {
        self.measurement = data;
    }
    return self;
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

- (void)printArray:(NSArray *)array {
    for (int i = 0; i < [array count]; i++) {
        NSLog(@"%d: %@", i + 1, [array objectAtIndex:i]);
    }
}

- (void)run {
    // will be override by child
}

- (NSMutableArray *)generateState:(NSArray *)accel withTime:(NSArray *)time withFrequency:(int) freq {
    
    NSMutableArray *a_amp = [[NSMutableArray alloc] initWithCapacity:[accel count]];
    NSMutableArray *a_max = [[NSMutableArray alloc] initWithCapacity:[accel count]];
    NSMutableArray *a_min = [[NSMutableArray alloc] initWithCapacity:[accel count]];
    double local_max = 0;
    double local_min = 0;
    int local_max_t = 0;
    int local_min_t = 0;
    int stride_t = 0;
    
    [a_amp addObject:[NSNumber numberWithDouble:0.0]];
    [a_max addObject:[NSNumber numberWithDouble:0.0]];
    [a_min addObject:[NSNumber numberWithDouble:0.0]];

    for (int i = 1; i < [accel count]-1; i++) {
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
            stride_t = i - local_max_t;
            if (local_max > 0 && stride_t < freq * STRIDE_PERIOD) {
                [a_amp replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:local_max - local_min]];
            }
            local_max = 0.0;
        }
    }
    [a_amp addObject:[NSNumber numberWithDouble:0.0]];
    [a_max addObject:[NSNumber numberWithDouble:0.0]];
    [a_min addObject:[NSNumber numberWithDouble:0.0]];
    
    NSMutableArray *stat = [[NSMutableArray alloc] initWithCapacity:[accel count]];
    for (int i = 0; i < [accel count]; i++) {
        [stat addObject:[NSNumber numberWithInt:0]];
    }
    
    int i_max = 0;
    int i_start = 0;
    int i_end = 0;
    for (int i = 0; i < [accel count]; i++) {
        if ([[a_amp objectAtIndex:i] doubleValue] > 0) {
            i_max = [self find:a_max startIndex:0 endIndex:i withMode:@"last"];
            for (int j = i_max; j >= 0; j--) {
                if ([[accel objectAtIndex:j] doubleValue] <= 0) {
                    i_start = j;
                    break;
                }
                
            }
            for (int j = i; j < [accel count]; j++) {
                if ([[accel objectAtIndex:j] doubleValue] >= 0) {
                    i_end = j;
                    break;
                }
            }
            for (int k = i_start; k <= i_end; k++) {
                [stat replaceObjectAtIndex:k withObject:[NSNumber numberWithInt:1]];
            }
        }
    }
    
    for (int i = 0; i < [accel count]; i++) {
        if ([[accel objectAtIndex:i] doubleValue] != 0 && [[stat objectAtIndex:i] intValue] == 0) {
            double a_value = [[accel objectAtIndex:i] doubleValue];
            int j;
            for (j = i + 1; j < [accel count]; j++) {
                if ([[accel objectAtIndex:j] doubleValue] == 0 || [[stat objectAtIndex:j] intValue] == 1 || [[accel objectAtIndex:j] doubleValue] * a_value < 0) {
                    break;
                }
            }
            int gap = j - i;
            if (gap > freq * ELEVATOR_ACC_PERIOD) {
                for (int k = i; k <= j; k++) {
                    [stat replaceObjectAtIndex:k withObject:[NSNumber numberWithInt:2]];
                }
            } else {
                for (int k = i; k <= j; k++) {
                    [stat replaceObjectAtIndex:k withObject:[NSNumber numberWithInt:1]];
                }
            }
            i = j;
        }
    }
    return stat;
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

- (NSMutableArray *)filterForElevator:(NSMutableArray *)accel withState:(NSArray *)stat {
    for (int i = 0; i < [accel count]; i++) {
        if ([[stat objectAtIndex:i] intValue] != 2) {
            [accel replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0.0]];
        }
    }
    return accel;
}

@end
