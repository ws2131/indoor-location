//
//  SensorData.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/21/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SensorData : NSObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSNumber *time;
@property (nonatomic, retain) NSNumber *a_x;
@property (nonatomic, retain) NSNumber *a_y;
@property (nonatomic, retain) NSNumber *a_z;
@property (nonatomic, retain) NSNumber *m11;
@property (nonatomic, retain) NSNumber *m12;
@property (nonatomic, retain) NSNumber *m13;
@property (nonatomic, retain) NSNumber *m21;
@property (nonatomic, retain) NSNumber *m22;
@property (nonatomic, retain) NSNumber *m23;
@property (nonatomic, retain) NSNumber *m31;
@property (nonatomic, retain) NSNumber *m32;
@property (nonatomic, retain) NSNumber *m33;
@property (nonatomic, retain) NSNumber *heading;
@property (nonatomic, retain) NSNumber *headingAccuracy;

@property (nonatomic, retain) NSNumber *gr_x;
@property (nonatomic, retain) NSNumber *gr_y;
@property (nonatomic, retain) NSNumber *gr_z;
@property (nonatomic, retain) NSNumber *gm_x;
@property (nonatomic, retain) NSNumber *gm_y;
@property (nonatomic, retain) NSNumber *gm_z;
@property (nonatomic, retain) NSNumber *mr_x;
@property (nonatomic, retain) NSNumber *mr_y;
@property (nonatomic, retain) NSNumber *mr_z;
@property (nonatomic, retain) NSNumber *mm_x;
@property (nonatomic, retain) NSNumber *mm_y;
@property (nonatomic, retain) NSNumber *mm_z;


@end
