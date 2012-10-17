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
#import "SensorData.h"
#import "ElevatorModule.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize buildingInfo;
@synthesize fileHandler;
@synthesize measurements;

# pragma mark -
# pragma mark Application Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupFetchedResultsController];
    if (![[self.fetchedResultsController fetchedObjects] count] > 0) {
        DLog(@"DB is empty, default values will be inserted.");
        [self importCoreDataDefaultBuildingInfo];
    } else {
        DLog(@"DB has values.");
        self.buildingInfo = [[self.fetchedResultsController fetchedObjects] objectAtIndex:0];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
    self.fileHandler = [[FileHandler alloc] initWithName:@"accel"];
    self.fileHandler.dateFormatter = dateFormatter;
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UINavigationController *mainTVCnav = [[tabBarController viewControllers] objectAtIndex:0];
    UINavigationController *settingTVCnav = [[tabBarController viewControllers] objectAtIndex:1];
    
    MainTVC *mainTVC = (MainTVC *)mainTVCnav.topViewController;
    mainTVC.buildingInfo = self.buildingInfo;
    mainTVC.delegate = self;
    
    SettingTVC *settingTVC = (SettingTVC *)settingTVCnav.topViewController;
    settingTVC.buildingInfo = self.buildingInfo;
    
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


#pragma mark - Core Data stack

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
# pragma mark Import default

- (void)setupFetchedResultsController {
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
    self.buildingInfo = [NSEntityDescription insertNewObjectForEntityForName:@"BuildingInfo"
                                                      inManagedObjectContext:self.managedObjectContext];
    self.buildingInfo.address1 = @"CEPSR";
    self.buildingInfo.address2 = @"530 W 120 ST";
    self.buildingInfo.address3 = @"New York, NY 10027";
    self.buildingInfo.floorOfEntry = [NSNumber numberWithInt:1];
    self.buildingInfo.floorHeight = [NSNumber numberWithFloat:4.4];
    self.buildingInfo.lobbyHeight = [NSNumber numberWithFloat:4.4];
    self.buildingInfo.numOfLandings = [NSNumber numberWithFloat:2.0];
    [self.managedObjectContext save:nil];
    
    DLog(@"Importing Core Data Default Values for BuildingInfo Completed!");
}


# pragma mark -
# pragma mark MainTVC Delegate
- (void)startButtonPushed:(MainTVC *)controller {
    
    // simulate measurements from csv file
    NSArray *array = [self.fileHandler loadFromFile];
    self.measurements = [[NSMutableArray alloc] initWithCapacity:[array count]];
    
    for (int i = 2; i < [array count]; i++) {
        NSArray *fields = [array objectAtIndex:i];
        if ([fields count] >= 7) {
            SensorData *sensorData = [NSEntityDescription insertNewObjectForEntityForName:@"SensorData" inManagedObjectContext:self.managedObjectContext];
            sensorData.time = [NSNumber numberWithDouble:[[fields objectAtIndex:1] doubleValue]];
            sensorData.a_x = [NSNumber numberWithDouble:[[fields objectAtIndex:4] doubleValue]];
            sensorData.a_y = [NSNumber numberWithDouble:[[fields objectAtIndex:5] doubleValue]];
            sensorData.a_z = [NSNumber numberWithDouble:[[fields objectAtIndex:6] doubleValue]];
            [self.measurements addObject:sensorData];
        }
    }
}

- (void)stopButtonPushed:(MainTVC *)controller {
    ElevatorModule *elevatorModule = [[ElevatorModule alloc] initWithData:self.measurements];
    [elevatorModule run];
}

@end

