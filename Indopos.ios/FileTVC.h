//
//  FileTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/22/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileHandler.h"
@interface FileTVC : UITableViewController

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) FileHandler *fileHandler;

@end
