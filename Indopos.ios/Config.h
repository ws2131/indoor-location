//
//  Config.h
//  Indopos.ios
//
//  Created by Wonsang Song on 8/5/13.
//  Copyright (c) 2013 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BuildingInfo;

@interface Config : NSManagedObject

@property (nonatomic, retain) NSString * test;
@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, retain) BuildingInfo *inBuilding;

@end
