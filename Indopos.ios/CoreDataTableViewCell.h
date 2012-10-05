//
//  CoreDataTableViewCell.h
//
//  Created by Tim Roadley on 22/02/12.
//  NO rights reserved
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CoreDataTableViewCell : UITableViewCell <NSFetchedResultsControllerDelegate, UIKeyInput, UIPopoverControllerDelegate> {

	UIPopoverController *popoverController;
	UIToolbar *inputAccessoryView;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;
@property (nonatomic, strong) UIPickerView *picker;

@end