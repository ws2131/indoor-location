//
//  StairwayModule.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/26/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import "AnalysisModule.h"

@interface StairwayModule : AnalysisModule

-(double)run:(NSArray *)t_set withAccel:(NSArray *)a_set withAmp:(NSArray *)a_amp_set withHeading:(NSArray *)h_set withIndex:(int)index;

@end
