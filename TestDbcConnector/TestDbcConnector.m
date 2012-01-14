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


- (void)waitWithTimeout:(NSUInteger)seconds {
  NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:5];
  while ( (! self.done) && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout]);
  STAssertTrue(self.done, @"timeout reached but not done");
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
  
  [self waitWithTimeout:5];
  
  STAssertNotNil(self.result, @"result is nil");
  
  NSData *data = [self.result dataUsingEncoding:NSASCIIStringEncoding];
  NSError *error = nil;
  NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  STAssertNil(error, @"error must be nil but is: %@", error);
  
  STAssertEqualObjects([res objectForKey:@"is_banned"], [NSNumber numberWithBool:NO], nil);
  STAssertEqualObjects([res objectForKey:@"status"], [NSNumber numberWithInt:0], nil);
  STAssertEqualObjects([res objectForKey:@"user"], [NSNumber numberWithInt:50402], nil);
}


#pragma mark - DbcConnectorDelegate


- (void)responseReceived:(NSString *)response {
  self.done = YES;
  self.result = response;
}


@end
