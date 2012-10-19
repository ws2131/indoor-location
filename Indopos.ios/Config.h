//
//  Config.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/18/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BuildingInfo;

@interface Config : NSManagedObject

@property (nonatomic, retain) NSString * test;
@property (nonatomic, retain) BuildingInfo *inBuilding;

@end
