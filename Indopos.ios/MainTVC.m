//
//  MainTVC.m
//  Indopos.ios
//
//  Created by Wonsang Song on 10/4/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "Logger.h"
#import "MainTVC.h"
#import "HistoryTVC.h"

@implementation MainTVC

@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;

@synthesize distanceFormatter;
@synthesize delegate;

- (void)fetchConfig {
    NSString *entityName = @"Config";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"test"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController performFetch:nil];
    config = [[self.fetchedResultsController fetchedObjects] objectAtIndex:0];
    buildingInfo = config.inBuilding;
    DLog(@"building %@", buildingInfo.address1);
}

# pragma mark -
# pragma mark View

- (void)viewDidLoad
{
    [self fetchConfig];
    DLog(@"building %@", buildingInfo.address1);
    self.curFloorTextField.text = [buildingInfo.floorOfEntry stringValue];
    self.curDispositionTextField.text = @"0";
    startButtonOn = NO;
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchConfig];

    DLog(@"building %@", buildingInfo.address1);
    NSString *addr = [NSString stringWithFormat:@"%@\n%@\n%@", buildingInfo.address1, buildingInfo.address2, buildingInfo.address3];
    self.addressTextView.text = addr;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"History Segue"]) {
        HistoryTVC *historyTVC = segue.destinationViewController;
        historyTVC.managedObjectContext = self.managedObjectContext;
        historyTVC.distanceFormatter = self.distanceFormatter;
    }
}

# pragma mark -
# pragma mark UI Action functions

- (IBAction)startButtonTouched:(id)sender {
    DLog(@"startbutton touched state: %@", startButtonOn ? @"YES" : @"NO");
    UIButton *button = (UIButton *)sender;
    if (startButtonOn == YES) {
        DLog(@"stop pushed");
        startButtonOn = NO;
        [button setTitle:@"Start" forState:UIControlStateNormal];
        //[button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.delegate stopButtonPushed:self];
    } else {
        DLog(@"start pushed");
        startButtonOn = YES;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        //[button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.delegate startButtonPushed:self];
    }
}

- (IBAction)refresh:(id)sender {
    [self.delegate refreshButtonPushed:self];
}

- (void)updateCurrentFloor:(NSNumber *)currentFloor {
    self.curFloorTextField.text = [NSString stringWithFormat:@"%d", [currentFloor intValue]];
}

- (void)updateCurrentDisplacement:(NSNumber *)currentDisplacement {
    self.curDispositionTextField.text = [NSString stringWithFormat:@"%@", [self.distanceFormatter stringFromNumber:currentDisplacement]];
}

@end;