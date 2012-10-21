//
//  ConcurrentOperation.h
//  Indopos.ios
//
//  Created by Wonsang Song on 10/21/12.
//  Copyright (c) 2012 Wonsang Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConcurrentOperation : NSOperation {
    BOOL executing;
    BOOL finished;
}

- (void)completeOperation;

@end
