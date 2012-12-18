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
#import <CoreLocation/CoreLocation.h>

#import "Config.h"
#import "BuildingInfo.h"
#import "FileHandler.h"
#import "MainTVC.h"
#import "Measurement.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MainTVCDelegate, UIAccelerometerDelegate, CLLocationManagerDelegate> {
    BOOL isPaused;
    
    NSDateFormatter *dateFormatter;
    NSNumberFormatter *distanceFormatter;
    NSNumberFormatter *floorFormatter;
    
    FileHandler *fileHandler;
    Measurement *measurement;

    NSNumber *currentFloor;
    NSNumber *currentDisplacement;
    
    CMMotionManager *motionManager;
    CLLocationManager *locationManager;
    CLHeading *currentHeading;
    
    MainTVC *mainTVC;
    
    ActivityType currentActivity;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) Config *config;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)resetHistory;
- (void)exportMeasurement;

@end