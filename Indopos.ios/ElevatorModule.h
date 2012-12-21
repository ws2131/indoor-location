//
//  ElevatorModule.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "AnalysisModule.h"

@interface ElevatorModule : AnalysisModule

- (double)run:(NSArray *)t withAccel:(NSArray *)a_vert_vs;
@end
