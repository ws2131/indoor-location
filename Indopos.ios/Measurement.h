//
//  Measurement.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/21/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Measurement : NSObject

@property (nonatomic, retain) NSNumber * start_ti;
@property (nonatomic, retain) NSNumber * end_ti;
@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSMutableArray *measurements;

@end
