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
@synthesize done = _done;
@synthesize doneCondition = _doneCondition;
@synthesize result = _result;


- (void)setUp {
  [super setUp];
    
  self.dbc = [[DbcConnector alloc] init];
  self.dbc.delegate = self;
  self.done = NO;
  self.doneCondition = [[NSCondition alloc] init];
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
  
  NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:5];
  while ( (! self.done) && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout]);
  
  STAssertEqualObjects(self.result, @"{\"is_banned\": false, \"status\": 0, \"rate\": 0.139, \"balance\": 689.857, \"user\": 50402}", @"server response");
}


#pragma mark - DbcConnectorDelegate


- (void)responseReceived:(NSString *)response {
  self.done = YES;
  self.result = response;
}


@end
