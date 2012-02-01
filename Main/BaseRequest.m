//
//  BaseRequest.m
//  Graf
//
//  Created by Sven A. Schmidt on 01.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "BaseRequest.h"

int const kTimeout = 15;


@implementation BaseRequest

@synthesize hasTimedOut = _hasTimedOut;
@synthesize isFinished = _isFinished;
@synthesize dbc = _dbc;


- (id)init {
  self = [super init];
  if (self) {
    self.isFinished = NO;
    self.hasTimedOut = NO;
    self.dbc = [[DbcConnector alloc] init];
    self.dbc.delegate = self;
  }
  return self;
}


- (void)start {
  [NSException raise:NSInternalInconsistencyException format:@"%@ was called in the base class %@!\n", NSStringFromSelector(_cmd), [self class]];
}

@end
