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

- (void)printDoubleArray:(NSArray *)array {
    for (int i = 0; i < [array count]; i++) {
        NSLog(@"%d: %f", i + 1, [[array objectAtIndex:i] doubleValue]);
    }
}

- (void)run {
    // will be override by child
}

@end
