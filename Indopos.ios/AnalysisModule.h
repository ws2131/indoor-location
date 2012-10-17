//
//  AnalysisModule.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/16/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalysisModule : NSObject

@property (nonatomic, strong) NSArray *measurements;

- (id)initWithData:(NSArray *)data;
- (NSArray *)lowPassFilter:(NSArray*)array withAlpha:(double)alpha;

@end
