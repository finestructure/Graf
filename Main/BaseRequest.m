//
//  BaseRequest.m
//  Graf
//
//  Created by Sven A. Schmidt on 01.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "BaseRequest.h"

int const kTimeout = 40;


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


- (void)close {
  self.dbc.delegate = nil;
  [self.dbc disconnect];
  self.dbc = nil;
}


#pragma mark - DbcConnectorDelegate


- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"connected to host %@:%d", host, port);
}


- (void)didLogInAs:(NSString *)user {
  NSLog(@"logged in as %@", user);
}


- (void)didDisconnectWithError:(NSError *)error {
  self.hasTimedOut = YES;
  self.isFinished = YES;
}


- (void)didDisconnect {
  self.isFinished = YES;
}


@end
