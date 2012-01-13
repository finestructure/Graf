//
//  TestDbcConnector.m
//  TestDbcConnector
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "TestDbcConnector.h"
#import "DbcConnector.h"

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
  [self.dbc call:@"user"];
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
}


@end
