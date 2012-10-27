//
//  AnalysisModule.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BuildingInfo.h"
#import "Measurement.h"

#define CUTOFFPOINT 2
#define GRAVITY 9.8
#define STRIDE_PERIOD 0.5
#define ELEVATOR_ACC_PERIOD 1

@interface AnalysisModule : NSObject

@property (nonatomic, strong) BuildingInfo *buildingInfo;
@property (nonatomic, strong) Measurement *measurement;
@property (nonatomic, strong) NSNumber *movedFloor;
@property (nonatomic, strong) NSNumber *movedDisplacement;

- (id)initWithData:(Measurement *)data;
- (NSMutableArray *)lowPassFilter:(NSArray *)array withAlpha:(double)alpha;
- (NSMutableArray *)cutOffDecimal:(NSArray *)array withPosition:(int)num;
- (NSMutableArray *)getVelocity:(NSArray *)time withAccel:(NSArray *)accel;
- (NSMutableArray *)getDisplacement:(NSArray *)time withAccel:(NSArray *)accel withVelocity:(NSArray *)velocity;
- (double)getAbsolute:(double)value;
- (double)getAbsoluteMax:(NSArray *)array;
- (void)printArray:(NSArray *)array;
- (void)run;

- (NSMutableArray *)generateState:(NSArray *)accel withTime:(NSArray *)time withFrequency:(int) freq;
- (int)find:(NSArray *)array startIndex:(int)start_index endIndex:(int)end_index withMode:(NSString *)mode;
- (NSMutableArray *)filterForElevator:(NSMutableArray *)accel withState:(NSArray *)stat;

@end
