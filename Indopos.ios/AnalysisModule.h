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
#import "StepResult.h"

#define CUTOFFPOINT 2
#define GRAVITY 9.8

#define MAX_STANDING_PERIOD 3
#define MIN_ELEVATOR_ACCEL_PERIOD 1
#define MIN_MEASUREMENTS 200

#define MAX_STEP_PERIOD 0.9
#define MIN_STEPS_GAP 0.3
#define MAX_STEPS_GAP 2
#define MIN_STEP_AMP 1

#define MAX_STAIR_NUM 20
#define MIN_STAIR_NUM 5
#define MIN_STAIR_HEIGHT 1.0

@interface AnalysisModule : NSObject

@property (nonatomic, strong) BuildingInfo *buildingInfo;
@property (nonatomic, strong) Measurement *measurement;
@property (nonatomic, strong) NSNumber *initialFloor;
@property (nonatomic, strong) NSNumber *initialDisplacement;
@property (nonatomic, strong) NSNumber *movedFloor;
@property (nonatomic, strong) NSNumber *movedDisplacement;
@property (nonatomic, strong) NSNumber *curFloor;
@property (nonatomic, strong) NSNumber *curDisplacement;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

- (id)initWithData:(Measurement *)data;
- (int)getFrequency:(NSArray *)time;
- (int)find:(NSArray *)array startIndex:(int)start_index endIndex:(int)end_index withMode:(NSString *)mode;
- (double)getAbsolute:(double)value;
- (double)getAbsoluteMax:(NSArray *)array;
- (double)diffAngles:(double)a1 withAngle:(double)a2;
- (double)getAverage:(NSArray *)array from:(int)i1 to:(int)i2;
- (double)getMax:(NSArray *)array from:(int)i1 to:(int)i2;
- (NSArray *)getArray:(NSArray *)array from:(int)i1 to:(int)i2;
- (void)printArray:(NSArray *)array;
- (NSMutableArray *)zerosWithInt:(int)len;
- (NSMutableArray *)zerosWithDouble:(int)len;

- (NSMutableArray *)lowPassFilter:(NSArray *)array withAlpha:(double)alpha;
- (NSMutableArray *)cutOffDecimal:(NSArray *)array withPosition:(int)num;
- (NSMutableArray *)getVelocity:(NSArray *)time withAccel:(NSArray *)accel;
- (NSMutableArray *)getDisplacement:(NSArray *)time withAccel:(NSArray *)accel withVelocity:(NSArray *)velocity;

- (NSMutableArray *)removeGravity:(NSArray *)time withAccel:(NSArray *)accel;
- (NSMutableArray *)getVertAccelFromVS:(NSArray *)time withX:(NSArray *)x withY:(NSArray *)y withZ:(NSArray *)z;
- (NSMutableArray *)getVertAccelFromRM:(NSArray *)time withX:(NSArray *)x withY:(NSArray *)y withZ:(NSArray *)z
                               withM11:(NSArray *)m11 withM12:(NSArray *)m12 withM13:(NSArray *)m13
                               withM21:(NSArray *)m21 withM22:(NSArray *)m22 withM23:(NSArray *)m23
                               withM31:(NSArray *)m31 withM32:(NSArray *)m32 withM33:(NSArray *)m33;
- (NSMutableArray *)adjustAccelFromVS:(NSArray *)time withAccel:(NSArray *)accel;
- (NSMutableArray *)adjustAccelFromRM:(NSArray *)time withAccel:(NSArray *)accel;
- (StepResult *)stepDetection:(NSArray *)time withAccel:(NSArray *)accel;
- (StepResult *)velocityDetection:(NSArray *)time withVelocity:(NSArray *)velocity;

- (NSMutableArray *)getVelocityWithZUPT:(NSArray *)time withAccel:(NSArray *)a_v;
- (NSMutableArray *)getVelocityWithZUPTForWalking:(NSArray *)time withAccel:(NSArray *)a_v withStat:(NSArray *)time_stat;


- (void)run;

@end
