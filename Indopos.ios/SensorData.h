//
//  SensorData.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/17/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SensorData : NSManagedObject

@property (nonatomic, retain) NSNumber * a_x;
@property (nonatomic, retain) NSNumber * a_y;
@property (nonatomic, retain) NSNumber * a_z;
@property (nonatomic, retain) NSNumber * time;

@end
