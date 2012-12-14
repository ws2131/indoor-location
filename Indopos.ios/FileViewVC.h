//
//  FileViewTVC.h
//  Indopos.ios
//
//  Created by Wonsang Song on 12/12/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileViewVC : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *fileTextView;
@property (nonatomic, strong) NSString *fileName;

@end
