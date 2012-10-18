//
//  History.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/17/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface History : NSManagedObject

@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * floor;
@property (nonatomic, retain) NSNumber * displacement;

@end
