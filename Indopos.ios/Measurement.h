//
//  Measurement.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SensorData;

@interface Measurement : NSManagedObject

@property (nonatomic, retain) NSNumber * start_ti;
@property (nonatomic, retain) NSNumber * end_ti;
@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSOrderedSet *hasSensorData;
@end

@interface Measurement (CoreDataGeneratedAccessors)

- (void)insertObject:(SensorData *)value inHasSensorDataAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasSensorDataAtIndex:(NSUInteger)idx;
- (void)insertHasSensorData:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasSensorDataAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasSensorDataAtIndex:(NSUInteger)idx withObject:(SensorData *)value;
- (void)replaceHasSensorDataAtIndexes:(NSIndexSet *)indexes withHasSensorData:(NSArray *)values;
- (void)addHasSensorDataObject:(SensorData *)value;
- (void)removeHasSensorDataObject:(SensorData *)value;
- (void)addHasSensorData:(NSOrderedSet *)values;
- (void)removeHasSensorData:(NSOrderedSet *)values;
@end
