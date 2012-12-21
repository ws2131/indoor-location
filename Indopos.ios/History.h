//
//  History.h
//  Indopos.ios
//
//  Created by Wonsang Song on 12/20/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface History : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * displacement;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * endFloor;
@property (nonatomic, retain) NSNumber * startFloor;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSDate * key;

@end
