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
  NSString *response = [self.dbc call:@"user"];
  
  STAssertNotNil(response, @"result is nil");
  
  NSData *data = [response dataUsingEncoding:NSASCIIStringEncoding];
  NSError *error = nil;
  NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  STAssertNil(error, @"error must be nil but is: %@", error);
  
  STAssertEqualObjects([res objectForKey:@"is_banned"], [NSNumber numberWithBool:NO], nil);
  STAssertEqualObjects([res objectForKey:@"status"], [NSNumber numberWithInt:0], nil);
  STAssertEqualObjects([res objectForKey:@"user"], [NSNumber numberWithInt:50402], nil);
}


@end
