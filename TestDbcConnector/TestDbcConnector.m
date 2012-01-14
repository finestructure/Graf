//
//  TestDbcConnector.m
//  TestDbcConnector
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "TestDbcConnector.h"

@implementation TestDbcConnector

@synthesize dbc = _dbc;


- (void)setUp {
  [super setUp];
    
  self.dbc = [[DbcConnector alloc] init];
}

- (void)tearDown {
  // Tear-down code here.
  
  [super tearDown];
}


- (void)test_connect {
  STAssertTrue([self.dbc connect], @"connect");
  STAssertTrue(self.dbc.connected, @"connected");
}


- (void)test_login {
  [self.dbc connect];
  [self.dbc login];
  STAssertTrue(self.dbc.loggedIn, @"logged in");
}


- (void)test_call {
  [self.dbc connect];
  [self.dbc login];
  NSDictionary *res = [self.dbc call:@"user"];
  
  STAssertNotNil(res, @"result is nil");
  STAssertEqualObjects([res objectForKey:@"is_banned"], [NSNumber numberWithBool:NO], nil);
  STAssertEqualObjects([res objectForKey:@"status"], [NSNumber numberWithInt:0], nil);
  STAssertEqualObjects([res objectForKey:@"user"], [NSNumber numberWithInt:50402], nil);
}


- (void)test_balance {
  [self.dbc connect];
  [self.dbc login];
  NSDictionary *res = [self.dbc call:@"user"];
  STAssertNotNil([res objectForKey:@"balance"], @"balance key must exist", nil);
  float balance = [[res objectForKey:@"balance"] floatValue];
  STAssertTrue(balance > 0, @"balance should be > 0", nil);
  STAssertEqualsWithAccuracy(balance, [self.dbc balance], 0.01, @"balance value check", nil);
}


@end
