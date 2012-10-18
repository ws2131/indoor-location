//
//  AppDelegate.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CoreMotion/CoreMotion.h>

#import "BuildingInfo.h"
#import "FileHandler.h"
#import "MainTVC.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MainTVCDelegate, UIAccelerometerDelegate> {
    BOOL isPaused;
    NSTimeInterval start_ts;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) BuildingInfo *buildingInfo;
@property (strong, nonatomic) FileHandler *fileHandler;
@property (strong, nonatomic) NSMutableArray *measurements;

@property (strong, nonatomic) NSNumber *currentFloor;
@property (strong, nonatomic) NSNumber *currentDisplacement;

@property (strong, nonatomic) CMMotionManager *motionManager;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)resetAll;

@end