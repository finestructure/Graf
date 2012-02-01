//
//  BalanceRequest.m
//  Graf
//
//  Created by Sven A. Schmidt on 01.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "BalanceRequest.h"

@implementation BalanceRequest


@synthesize rate = _rate;
@synthesize balance = _balance;


- (void)start {
  [self.dbc connect];
  [self.dbc login];  
  NSLog(@"Worker executing balance command");
  [self.dbc refreshBalance];
}


#pragma mark - DbcConnectorDelegate


- (void)didRefreshBalance:(NSNumber *)balance rate:(NSNumber *)rate {
  self.balance = balance;
  self.rate = rate;
  self.isFinished = YES;
}


@end
