//
//  DebugTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "DebugTVC.h"
#import "AppDelegate.h"
#import "Logger.h"
#import "Measurement.h"
#import "SensorData.h"

#define ACC_UPLOAD_URL @"http://ng911dev1.cs.columbia.edu/iLM/acc/upload.php"

@implementation DebugTVC

@synthesize managedObjectContext = _managedObjectContext;
@synthesize dateFormatter;
@synthesize fileHandler;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self update];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
}

- (void)update {
    self.measurementNumLabel.text = [self getNumMeasurement];
    self.sensorDataNumLabel.text = [self getNumSensorData];
    self.historyNumLabel.text = [self getNumHistory];
}

- (NSString *)getNumMeasurement {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Measurement"
                                 inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate"
                                                                                     ascending:YES]];
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [NSString stringWithFormat:@"%d", [fetchResults count]];
}

- (NSString *)getNumHistory {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"History"
                                 inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time"
                                                                                     ascending:YES]];
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [NSString stringWithFormat:@"%d", [fetchResults count]];
}

- (NSString *)getNumSensorData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"SensorData"
                                 inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"time"
                                                                                     ascending:YES]];
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [NSString stringWithFormat:@"%d", [fetchResults count]];
}

- (IBAction)sendAllFiles:(id)sender {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Measurement"
                                 inManagedObjectContext:self.managedObjectContext];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate"
                                                                                     ascending:YES]];
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:nil];
    for (Measurement *measurement in fetchResults) {
        DLog(@"%@", measurement.startDate);
        NSString *targetFileName = [NSString stringWithFormat:@"%@.%@.txt", self.fileHandler.fileName, [self.dateFormatter stringFromDate:measurement.startDate]];
        [self dumpMeasurement:measurement];
        [self.fileHandler backupFileTo:targetFileName];
        [self.fileHandler sendFile:targetFileName withURL:ACC_UPLOAD_URL];
        [self.fileHandler deleteFile];
        [self.fileHandler deleteFileWithName:targetFileName];
        // don't remove after sending
        //[self.managedObjectContext deleteObject:measurement];
    }
    //[self.managedObjectContext save:nil];
    //[self update];
}

- (IBAction)deleteAllHistories:(id)sender {
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetHistory];
    [self update];
}

- (IBAction)deleteAllMeasurements:(id)sender {
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetMeasurement];
    [(AppDelegate *)[UIApplication sharedApplication].delegate resetSensorData];
    [self update];
}

- (void)dumpMeasurement:(Measurement *)measurement {
    if ([measurement.hasSensorData count] == 0) {
        DLog(@"measurement empty");
        return;
    }
    
    // dump measurement to the file
    [self.fileHandler writeToFile:[NSString stringWithFormat:@"start, %@, %@\n",
                              [self.dateFormatter stringFromDate:measurement.startDate], measurement.frequency]];
    [self.fileHandler writeToFile:@"timestamp, sec, floor, state, x, y, z, lpf.x, lpf.y, lpf.z, hpf.x, hpf.y, hpf.z, a1, a2, a3, v1, v2, v3, d1, d2, d3, gx, gy, gz, ax, ay, az, a_adj, v_adj, d_adj, v_gap, v_max, curFloor, temp, pressure, altitude, heading, roll, pitch, yaw, rr.x, rr.y, rr.z, m11, m12, m13, m21, m22, m23, m31, m32, m33, heading_acc\n"];
    for (int i = 0; i < [measurement.hasSensorData count]; i++) {
        SensorData *data = [measurement.hasSensorData objectAtIndex:i];
        NSString *str = [NSString stringWithFormat:@"%@, %lf, %d, %d, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %d, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf, %lf\n",
                         @"0000-00-00 00:00:00.000",
                         [data.time doubleValue],
                         0, 0,
                         [data.a_x doubleValue], [data.a_y doubleValue], [data.a_z doubleValue],
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0.,
                         0., 0., 0,
                         0., 0., 0.,
                         [data.heading doubleValue],
                         0., 0., 0.,
                         0., 0., 0.,
                         [data.m11 doubleValue], [data.m12 doubleValue], [data.m13 doubleValue],
                         [data.m21 doubleValue], [data.m22 doubleValue], [data.m23 doubleValue],
                         [data.m31 doubleValue], [data.m32 doubleValue], [data.m33 doubleValue],
                         [data.headingAccuracy doubleValue]];
        [self.fileHandler writeToFile:str];
    }
}

@end
