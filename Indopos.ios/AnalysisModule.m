//
//  AnalysisModule.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "AnalysisModule.h"

@implementation AnalysisModule

@synthesize measurements;

- (id)initWithData:(NSArray *)data {
    self = [super init];
    if (self) {
        self.measurements = data;
    }
    return self;
}

- (NSArray *)lowPassFilter:(NSArray*)array withAlpha:(double)alpha {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    [result addObject:[array objectAtIndex:0]];
    for (int i = 1; i < [array count]; i++) {
        [result addObject:[NSNumber numberWithDouble:[[array objectAtIndex:i] doubleValue] * alpha + [[array objectAtIndex:(i - 1)] doubleValue] * (1 - alpha)]];
    }
    return result;
}

@end
