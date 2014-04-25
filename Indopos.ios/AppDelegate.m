    //
//  AppDelegate.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "AppDelegate.h"
#import "Logger.h"
#import "MainTVC.h"
#import "SettingTVC.h"
#import "DebugTVC.h"
#import "SensorData.h"
#import "ElevatorModule.h"
#import "StairwayModule.h"
#import "EscalatorModule.h"
#import "ActivityManager.h"

#import "History.h"
#import "Measurement.h"

#define DEFAULT_FREQUENCY 30

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

# pragma mark -
# pragma mark Application Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // initialize config info
    [self setupFetchedResultsControllerForBuildingInfo];
    if (![[self.fetchedResultsController fetchedObjects] count] > 0) {
        DLog(@"DB is empty, default values will be inserted.");
        [self importCoreDataDefaultBuildingInfo];
    }
    [self setupFetchedResultsControllerForBuildingInfo];
    BuildingInfo *buildingInfo = [[self.fetchedResultsController fetchedObjects] objectAtIndex:0];
    
    [self setupFetchedResultsControllerForConfig];
    if (![[self.fetchedResultsController fetchedObjects] count] > 0) {
        DLog(@"Config is empty, default values will be inserted.");
        self.config = [NSEntityDescription insertNewObjectForEntityForName:@"Config"
                                                    inManagedObjectContext:self.managedObjectContext];
        self.config.inBuilding = buildingInfo;
        self.config.frequency =[NSNumber numberWithInt:DEFAULT_FREQUENCY];
        [self.managedObjectContext save:nil];
    } else {
        self.config = [[self.fetchedResultsController fetchedObjects] objectAtIndex:0];
        buildingInfo = self.config.inBuilding;
        DLog(@"Config has values. Freq: %d", [self.config.frequency intValue]);
    }
    DLog(@"building: %@", buildingInfo.address1);
    
    // intialize sensors
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    motionManager = [[CMMotionManager alloc] init];
    
    // device capability
    UIDevice *device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
        backgroundSupported = device.multitaskingSupported;
    }
    DLog("backgroundSupported: %d accelAvailable: %d gyroAvailable: %d magnetoAvailable: %d headingAvailable: %d",
         backgroundSupported, motionManager.accelerometerAvailable, motionManager.gyroAvailable, motionManager.magnetometerAvailable, [CLLocationManager headingAvailable]);
    
    NSTimeInterval interval = 1.0 / [self.config.frequency intValue];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:interval];
    motionManager.deviceMotionUpdateInterval = interval;
    motionManager.gyroUpdateInterval = interval;
    motionManager.magnetometerUpdateInterval = interval;
    
    // other initialization
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    distanceFormatter = [[NSNumberFormatter alloc] init];
    [distanceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [distanceFormatter setMaximumFractionDigits:1];
    
    floorFormatter = [[NSNumberFormatter alloc] init];
    [floorFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [floorFormatter setMaximumFractionDigits:1];
    
    fileHandler = [[FileHandler alloc] init];
    fileHandler.dateFormatter = dateFormatter;
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UINavigationController *mainTVCnav = [[tabBarController viewControllers] objectAtIndex:0];
    UINavigationController *settingTVCnav = [[tabBarController viewControllers] objectAtIndex:1];
    UINavigationController *debugTVCnav = [[tabBarController viewControllers] objectAtIndex:2];
    
    mainTVC = (MainTVC *)mainTVCnav.topViewController;
    mainTVC.managedObjectContext = self.managedObjectContext;
    mainTVC.distanceFormatter = distanceFormatter;
    mainTVC.floorFormatter = floorFormatter;
    mainTVC.config = self.config;
    mainTVC.delegate = self;
    
    SettingTVC *settingTVC = (SettingTVC *)settingTVCnav.topViewController;
    settingTVC.managedObjectContext = self.managedObjectContext;
    settingTVC.config = self.config;

    DebugTVC *debugTVC = (DebugTVC *)debugTVCnav.topViewController;
    debugTVC.managedObjectContext = self.managedObjectContext;
    debugTVC.fileHandler = fileHandler;
    debugTVC.dateFormatter = dateFormatter;

    currentDisplacement = [NSNumber numberWithDouble:0.0];
    currentFloor = buildingInfo.floorOfEntry;
    
    currentActivity = all;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Indopos.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


# pragma mark -
# pragma mark Private functions

- (void)setupFetchedResultsControllerForBuildingInfo {
    NSString *entityName = @"BuildingInfo";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"address1"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController performFetch:nil];
}

- (void)importCoreDataDefaultBuildingInfo {
    
    DLog(@"Importing Core Data Default Values for BuildingInfo...");
    BuildingInfo *buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                               inManagedObjectContext:self.managedObjectContext];
    buildingInfo.address1 = @"CEPSR";
    buildingInfo.address2 = @"530 W 120 ST";
    buildingInfo.address3 = @"New York, NY 10027";
    buildingInfo.floorOfEntry = [NSNumber numberWithInt:4];
    buildingInfo.floorHeight = [NSNumber numberWithFloat:4.6];
    buildingInfo.lobbyHeight = [NSNumber numberWithFloat:4.6];
    buildingInfo.numOfLandings = [NSNumber numberWithFloat:2.0];
    [self.managedObjectContext save:nil];

    buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                 inManagedObjectContext:self.managedObjectContext];
    buildingInfo.address1 = @"Mudd";
    buildingInfo.address2 = @"500 W 120 ST";
    buildingInfo.address3 = @"New York, NY 10027";
    buildingInfo.floorOfEntry = [NSNumber numberWithInt:4];
    buildingInfo.floorHeight = [NSNumber numberWithFloat:3.7];
    buildingInfo.lobbyHeight = [NSNumber numberWithFloat:3.7];
    buildingInfo.numOfLandings = [NSNumber numberWithFloat:2.0];
    [self.managedObjectContext save:nil];
    
    buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                 inManagedObjectContext:self.managedObjectContext];
    buildingInfo.address1 = @"Pupin";
    buildingInfo.address2 = @"538 W 120 ST";
    buildingInfo.address3 = @"New York, NY 10027";
    buildingInfo.floorOfEntry = [NSNumber numberWithInt:5];
    buildingInfo.floorHeight = [NSNumber numberWithFloat:3.5];
    buildingInfo.lobbyHeight = [NSNumber numberWithFloat:3.5];
    buildingInfo.numOfLandings = [NSNumber numberWithFloat:2.0];
    [self.managedObjectContext save:nil];
    
    buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                 inManagedObjectContext:self.managedObjectContext];
    buildingInfo.address1 = @"NWB";
    buildingInfo.address2 = @"550 W 120 ST";
    buildingInfo.address3 = @"New York, NY 10027";
    buildingInfo.floorOfEntry = [NSNumber numberWithInt:1];
    buildingInfo.floorHeight = [NSNumber numberWithFloat:3.65];
    buildingInfo.lobbyHeight = [NSNumber numberWithFloat:3.65];
    buildingInfo.numOfLandings = [NSNumber numberWithFloat:2.0];
    [self.managedObjectContext save:nil];
    
    buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                 inManagedObjectContext:self.managedObjectContext];
    buildingInfo.address1 = @"Home";
    buildingInfo.address2 = @"530 W 122 ST";
    buildingInfo.address3 = @"New York, NY 10027";
    buildingInfo.floorOfEntry = [NSNumber numberWithInt:1];
    buildingInfo.floorHeight = [NSNumber numberWithFloat:3.0];
    buildingInfo.lobbyHeight = [NSNumber numberWithFloat:3.0];
    buildingInfo.numOfLandings = [NSNumber numberWithFloat:2.0];
    [self.managedObjectContext save:nil];

    DLog(@"Importing Core Data Default Values for BuildingInfo Completed!");
}

- (void)setupFetchedResultsControllerForConfig {
    NSString *entityName = @"Config";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"test"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController performFetch:nil];
}

- (void)startFile {
    NSString *fname = [NSString stringWithFormat:@"%@.%@.txt", FILE_PREFIX, [dateFormatter stringFromDate:measurement.startDate]];
    [fileHandler setFileName:fname];
    [fileHandler writeToFile:[NSString stringWithFormat:@"start, %@, %@\n",
                              [dateFormatter stringFromDate:measurement.startDate], measurement.frequency]];
    [fileHandler writeToFile:@"timestamp, sec, x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33, heading, heading_acc, gr_x, gr_y, gr_z, gm_x, gm_y, gm_z, mr_x, mr_y, mr_z, mm_x, mm_y, mm_z\n"];
}

- (void)endFile:(History *)history {
    [fileHandler writeToFile:[NSString stringWithFormat:@"%@-%@-%@\n", history.address, history.startFloor, history.endFloor]];
}

- (void)writeToFile:(SensorData *)data {
    NSString *str = [NSString stringWithFormat:@"%@, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf\n",
                     [dateFormatter stringFromDate:data.date],
                     [data.time doubleValue],
                     [data.a_x doubleValue], [data.a_y doubleValue], [data.a_z doubleValue],
                     [data.m11 doubleValue], [data.m12 doubleValue], [data.m13 doubleValue],
                     [data.m21 doubleValue], [data.m22 doubleValue], [data.m23 doubleValue],
                     [data.m31 doubleValue], [data.m32 doubleValue], [data.m33 doubleValue],
                     [data.heading doubleValue],
                     [data.headingAccuracy doubleValue],
                     [data.gr_x doubleValue], [data.gr_y doubleValue], [data.gr_z doubleValue],
                     [data.gm_x doubleValue], [data.gm_y doubleValue], [data.gm_z doubleValue],
                     [data.mr_x doubleValue], [data.mr_y doubleValue], [data.mr_z doubleValue],
                     [data.mm_x doubleValue], [data.mm_y doubleValue], [data.mm_z doubleValue]];
    [fileHandler writeToFile:str];
}


# pragma mark -
# pragma mark UIAccelerometer delegate

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	if(!isPaused)
	{
        if ([measurement.start_ti doubleValue] == 0.) {
            measurement.start_ti = [NSNumber numberWithDouble:acceleration.timestamp];
        }
        measurement.end_ti = [NSNumber numberWithDouble:acceleration.timestamp];
        
        CMRotationMatrix rotationMatrix = motionManager.deviceMotion.attitude.rotationMatrix;
        CMRotationRate gyroMotion = motionManager.deviceMotion.rotationRate;
        CMMagneticField magnetoMotion = motionManager.deviceMotion.magneticField.field;
        
        CMRotationRate gyroRaw = motionManager.gyroData.rotationRate;
        CMMagneticField magnetoRaw = motionManager.magnetometerData.magneticField;
        
        SensorData *sensorData = [[SensorData alloc] init];
        sensorData.date = [NSDate date];
        sensorData.time = [NSNumber numberWithDouble:(acceleration.timestamp - [measurement.start_ti doubleValue])];
        sensorData.a_x = [NSNumber numberWithDouble:acceleration.x];
        sensorData.a_y = [NSNumber numberWithDouble:acceleration.y];
        sensorData.a_z = [NSNumber numberWithDouble:acceleration.z];
        sensorData.m11 = [NSNumber numberWithDouble:rotationMatrix.m11];
        sensorData.m12 = [NSNumber numberWithDouble:rotationMatrix.m12];
        sensorData.m13 = [NSNumber numberWithDouble:rotationMatrix.m13];
        sensorData.m21 = [NSNumber numberWithDouble:rotationMatrix.m21];
        sensorData.m22 = [NSNumber numberWithDouble:rotationMatrix.m22];
        sensorData.m23 = [NSNumber numberWithDouble:rotationMatrix.m23];
        sensorData.m31 = [NSNumber numberWithDouble:rotationMatrix.m31];
        sensorData.m32 = [NSNumber numberWithDouble:rotationMatrix.m32];
        sensorData.m33 = [NSNumber numberWithDouble:rotationMatrix.m33];
        sensorData.heading = [NSNumber numberWithDouble:currentHeading.magneticHeading];
        sensorData.headingAccuracy = [NSNumber numberWithDouble:currentHeading.headingAccuracy];
        
        sensorData.gr_x = [NSNumber numberWithDouble:gyroRaw.x];
        sensorData.gr_y = [NSNumber numberWithDouble:gyroRaw.y];
        sensorData.gr_z = [NSNumber numberWithDouble:gyroRaw.z];
        
        sensorData.gm_x = [NSNumber numberWithDouble:gyroMotion.x];
        sensorData.gm_y = [NSNumber numberWithDouble:gyroMotion.y];
        sensorData.gm_z = [NSNumber numberWithDouble:gyroMotion.z];
        
        sensorData.mr_x = [NSNumber numberWithDouble:magnetoRaw.x];
        sensorData.mr_y = [NSNumber numberWithDouble:magnetoRaw.y];
        sensorData.mr_z = [NSNumber numberWithDouble:magnetoRaw.z];
        
        sensorData.mm_x = [NSNumber numberWithDouble:magnetoMotion.x];
        sensorData.mm_y = [NSNumber numberWithDouble:magnetoMotion.y];
        sensorData.mm_z = [NSNumber numberWithDouble:magnetoMotion.z];
        
        [measurement.measurements addObject:sensorData];
        [self writeToFile:sensorData];
        [mainTVC updateCounter:sensorData.time];

        //DLog(@"a_z: %f", acceleration.z);
    }
}


# pragma mark -
# pragma mark CLLocationManager delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    currentHeading = newHeading;

    //DLog(@"heading: %f", newHeading.magneticHeading);
}


# pragma mark -
# pragma mark Common functions for TVCs

- (void)resetHistory {
    DLog(@"resetHistory");
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"History" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * histories = [self.managedObjectContext executeFetchRequest:request error:&error];
    //error handling goes here
    for (NSManagedObject * history in histories) {
        [self.managedObjectContext deleteObject:history];
    }
    [self.managedObjectContext save:nil];    
}

- (void)updateFrequency {
    DLog(@"updateFrequency");
    NSTimeInterval interval = 1.0 / [self.config.frequency intValue];
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:interval];
    motionManager.deviceMotionUpdateInterval = interval;
    motionManager.gyroUpdateInterval = interval;
    motionManager.magnetometerUpdateInterval = interval;
}

# pragma mark -
# pragma mark MainTVC Delegate

- (void)startButtonPushed:(MainTVC *)controller {
    
    DLog(@"buildingInfo of config: %@ %@", self.config.inBuilding.address1, self.config.inBuilding.floorHeight);
    DLog(@"currentFloor: %@", currentFloor);
    isPaused = NO;
    
    measurement = [[Measurement alloc] init];
    measurement.measurements = [[NSMutableArray alloc] initWithCapacity:400];
    measurement.startDate = [NSDate date];
    measurement.start_ti = [NSNumber numberWithDouble:0.];
    measurement.frequency = self.config.frequency;
    
    [self startFile];

#if TARGET_IPHONE_SIMULATOR
    
    NSString *file_name = nil;
    if (currentActivity == elevator) {
        file_name = @"elevator.txt";
    } else if (currentActivity == stairway) {
        file_name = @"stairway.txt";
    } else if (currentActivity == escalator) {
        file_name = @"escalator.txt";
    } else if (currentActivity == all) {
        file_name = @"combo.txt";
    }
    DLog(@"file_name: %@", file_name);
    // simulate measurements from csv file
    NSArray *array = [fileHandler loadFromFile:file_name];
    NSString *ts = [[array objectAtIndex:0] objectAtIndex:1];
    //measurement.startDate = [dateFormatter dateFromString:ts];
    for (int i = [array count] -1; i > 0; i--) {
        NSArray *fields = [array objectAtIndex:i];
        if ([fields count] > 7) {
            ts = [fields objectAtIndex:0];
            break;
        }
    }
    measurement.endDate = [dateFormatter dateFromString:ts];
    DLog(@"endDate: %@", [dateFormatter stringFromDate:measurement.endDate]);
    
    for (int i = 2; i < [array count]; i++) {
        NSArray *fields = [array objectAtIndex:i];
        if ([fields count] >= 16) {
            SensorData *sensorData = [[SensorData alloc] init];
            sensorData.date = [dateFormatter dateFromString:[fields objectAtIndex:0]];
            sensorData.time = [NSNumber numberWithDouble:[[fields objectAtIndex:1] doubleValue]];
            sensorData.a_x = [NSNumber numberWithDouble:[[fields objectAtIndex:2] doubleValue]];
            sensorData.a_y = [NSNumber numberWithDouble:[[fields objectAtIndex:3] doubleValue]];
            sensorData.a_z = [NSNumber numberWithDouble:[[fields objectAtIndex:4] doubleValue]];
            sensorData.m11 = [NSNumber numberWithDouble:[[fields objectAtIndex:5] doubleValue]];
            sensorData.m12 = [NSNumber numberWithDouble:[[fields objectAtIndex:6] doubleValue]];
            sensorData.m13 = [NSNumber numberWithDouble:[[fields objectAtIndex:7] doubleValue]];
            sensorData.m21 = [NSNumber numberWithDouble:[[fields objectAtIndex:8] doubleValue]];
            sensorData.m22 = [NSNumber numberWithDouble:[[fields objectAtIndex:9] doubleValue]];
            sensorData.m23 = [NSNumber numberWithDouble:[[fields objectAtIndex:10] doubleValue]];
            sensorData.m31 = [NSNumber numberWithDouble:[[fields objectAtIndex:11] doubleValue]];
            sensorData.m32 = [NSNumber numberWithDouble:[[fields objectAtIndex:12] doubleValue]];
            sensorData.m33 = [NSNumber numberWithDouble:[[fields objectAtIndex:13] doubleValue]];
            sensorData.heading = [NSNumber numberWithDouble:[[fields objectAtIndex:14] doubleValue]];
            sensorData.headingAccuracy = [NSNumber numberWithDouble:[[fields objectAtIndex:15] doubleValue]];
            [measurement.measurements addObject:sensorData];
            [self writeToFile:sensorData];
        }
    }
    measurement.end_ti = [NSNumber numberWithDouble:30.];
    DLog(@"loaded: %d", [measurement.measurements count]);

#else
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    [motionManager startDeviceMotionUpdates];
    [motionManager startGyroUpdates];
    [motionManager startMagnetometerUpdates];
    [locationManager startUpdatingHeading];
    DLog(@"motionManager attitudeReferenceFrame: %d", motionManager.attitudeReferenceFrame);
#endif
    
    DLog(@"startButtonPushed done");
}

- (void)stopButtonPushed:(MainTVC *)controller {
    
    isPaused = YES;
    measurement.endDate = [NSDate date];

#if TARGET_IPHONE_SIMULATOR
#else
    [motionManager stopDeviceMotionUpdates];
    [motionManager stopGyroUpdates];
    [motionManager stopMagnetometerUpdates];
    [locationManager stopUpdatingHeading];
#endif
    
    DLog(@"number of measurements: %d", [measurement.measurements count]);
    DLog(@"buildingInfo: %@", self.config.inBuilding.address1);
    DLog(@"sampling interval: %f, %f", [UIAccelerometer sharedAccelerometer].updateInterval, motionManager.deviceMotionUpdateInterval);

    if ([measurement.measurements count] > 0) {
        AnalysisModule *analysisModule = nil;
        if (currentActivity == elevator) {
            analysisModule = [[ElevatorModule alloc] initWithData:measurement];
        } else if (currentActivity == stairway) {
            analysisModule = [[StairwayModule alloc] initWithData:measurement];
        } else if (currentActivity == escalator) {
            analysisModule = [[EscalatorModule alloc] initWithData:measurement];
        } else if (currentActivity == all) {
            analysisModule = [[ActivityManager alloc] initWithData:measurement];
            analysisModule.managedObjectContext = self.managedObjectContext;
        }
        NSNumber *startFloor = currentFloor;
        
        analysisModule.buildingInfo = self.config.inBuilding;
        analysisModule.dateFormatter = dateFormatter;
        analysisModule.initialFloor = currentFloor;
        analysisModule.initialDisplacement = currentDisplacement;
        
        [analysisModule run];
        
        currentDisplacement = analysisModule.curDisplacement;
        currentFloor = analysisModule.curFloor;
        
        [controller updateCurrentDisplacement:currentDisplacement];
        [controller updateCurrentFloor:currentFloor];
        
        if (currentActivity != all) {
            History *newHistory = [NSEntityDescription insertNewObjectForEntityForName:@"History" inManagedObjectContext:self.managedObjectContext];
            newHistory.time = [NSDate date];
            newHistory.key = newHistory.time;
            newHistory.startFloor = startFloor;
            newHistory.endFloor = currentFloor;
            newHistory.displacement = analysisModule.movedDisplacement;
            newHistory.duration = [NSNumber numberWithDouble:([measurement.end_ti doubleValue] - [measurement.start_ti doubleValue])];
            newHistory.address = self.config.inBuilding.address1;
            [newHistory.managedObjectContext save:nil];
            [self endFile:newHistory];
        }
    }
    [controller stopActivityIndicator];
    DLog(@"stopButtonPushed done");
}

- (void)refreshButtonPushed:(MainTVC *)controller {
    currentDisplacement = [NSNumber numberWithDouble:0.0];
    currentFloor = self.config.inBuilding.floorOfEntry;
    
    [controller updateCurrentDisplacement:currentDisplacement];
    [controller updateCurrentFloor:currentFloor];
    [controller updateCounter:[NSNumber numberWithInt:0]];
}

- (void)currentFloorChanged:(MainTVC *)controller {
    currentFloor = [NSNumber numberWithInt:[controller.curFloorTextField.text integerValue]];
}

- (void)activityChanged:(MainTVC *)controller selectedActivity:(ActivityType)activity {
    currentActivity = activity;
    DLog(@"currentActivity: %d", currentActivity);
}

@end

