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


- (void)withTimeout:(NSUInteger)seconds monitorForSuccess:(BOOL (^)())block {
  NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:seconds];
  while (!block() && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout]) {
    // break when the timeout is reached 
    if ([timeout timeIntervalSinceDate:[NSDate date]] < 0) {
      break;
    }
  }
}


- (void)_test_connect {
  STAssertTrue([self.dbc connect], @"connect");
  [self withTimeout:2 monitorForSuccess:^BOOL{
    return self.dbc.connected;
  }];
  STAssertTrue(self.dbc.connected, @"connected");
}


- (void)_test_login {
  [self.dbc connect];
  [self.dbc login];
  [self withTimeout:2 monitorForSuccess:^BOOL{
    return self.dbc.loggedIn;
  }];
  STAssertTrue(self.dbc.loggedIn, @"logged in");
}


- (void)_test_call {
  [self.dbc connect];
  [self.dbc login];
  
  STAssertNotNil(res, @"result is nil");
  STAssertEqualObjects([res objectForKey:@"is_banned"], [NSNumber numberWithBool:NO], nil);
  STAssertEqualObjects([res objectForKey:@"status"], [NSNumber numberWithInt:0], nil);
  STAssertEqualObjects([res objectForKey:@"user"], [NSNumber numberWithInt:50402], nil);
}


- (void)_test_balance {
  [self.dbc connect];
  [self.dbc login];
  NSDictionary *res = nil; //[self.dbc call:@"user"];
  STAssertNotNil([res objectForKey:@"balance"], @"balance key must exist", nil);
  float balance = [[res objectForKey:@"balance"] floatValue];
  STAssertTrue(balance > 0, @"balance should be > 0", nil);
  STAssertEqualsWithAccuracy(balance, [self.dbc balance], 0.01, @"balance value check", nil);
}


- (void)_test_upload {
  [self.dbc connect];
  [self.dbc login];
  UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[DbcConnector class]] pathForResource:@"test222" ofType:@"png"]];

  STAssertNotNil(image, @"image must not be nil", nil);
  NSUInteger captchaId = [self.dbc upload:image];
  NSLog(@"captcha id: %d", captchaId);
  STAssertTrue(captchaId > 0, @"captcha id must be > 0", nil);
}


- (void)_test_decode {
  [self.dbc connect];
  [self.dbc login];
  UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[DbcConnector class]] pathForResource:@"test222" ofType:@"png"]];
  NSString *res = [self.dbc decode:image];
  STAssertEqualObjects(@"037233", res, @"decoding result");
}

@end
