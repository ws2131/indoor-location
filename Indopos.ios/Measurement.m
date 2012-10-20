//
//  Measurement.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Measurement.h"
#import "SensorData.h"


@implementation Measurement

@dynamic start_ti;
@dynamic end_ti;
@dynamic frequency;
@dynamic startDate;
@dynamic endDate;
@dynamic hasSensorData;

- (void)addHasSensorDataObject:(SensorData *)value {
    NSMutableOrderedSet* tempSet = [self mutableOrderedSetValueForKey:@"hasSensorData"];
    [tempSet addObject:value];
}

@end
