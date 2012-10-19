//
//  BuildingInfo.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/18/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Config;

@interface BuildingInfo : NSManagedObject

@property (nonatomic, retain) NSString * address1;
@property (nonatomic, retain) NSString * address2;
@property (nonatomic, retain) NSString * address3;
@property (nonatomic, retain) NSNumber * floorHeight;
@property (nonatomic, retain) NSNumber * floorOfEntry;
@property (nonatomic, retain) NSNumber * lobbyHeight;
@property (nonatomic, retain) NSNumber * numOfLandings;
@property (nonatomic, retain) Config *heldBy;

@end
