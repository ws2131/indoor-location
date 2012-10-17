//
//  SensorData.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SensorData : NSManagedObject

@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSNumber * a_x;
@property (nonatomic, retain) NSNumber * a_y;
@property (nonatomic, retain) NSNumber * a_z;

@end
