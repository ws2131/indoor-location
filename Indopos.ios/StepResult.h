//
//  StepResult.h
//  Indopos.ios
//
//  Created by Wonsang Song on 12/19/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StepResult : NSObject

@property (strong, nonatomic) NSMutableArray *a_amp;
@property (strong, nonatomic) NSMutableArray *a_max;
@property (strong, nonatomic) NSMutableArray *a_min;

@property (strong, nonatomic) NSNumber *a_amp_ave;
@property (strong, nonatomic) NSNumber *a_amp_num;
@property (strong, nonatomic) NSNumber *a_amp_gap;

@end
