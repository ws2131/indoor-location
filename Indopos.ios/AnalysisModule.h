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
- (void)printDoubleArray:(NSArray *)array;
- (void)run;
@end
