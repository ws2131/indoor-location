//
//  Measurement.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/18/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Measurement : NSObject {
    NSTimeInterval start_ti;
    NSTimeInterval end_ti;
    NSInteger frequency;
    
    NSDate *startDate;
    NSDate *endDate;
    
    NSMutableArray *sensorDataArray;
}

@property NSTimeInterval start_ti, end_ti;
@property NSInteger frequency;
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@property (strong, nonatomic) NSMutableArray *sensorDataArray;

@end
