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
  NSDate *step = [NSDate dateWithTimeIntervalSinceNow:0.1];
  while (!block() && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:step]) {
    // break when the timeout is reached 
    if ([timeout timeIntervalSinceDate:[NSDate date]] < 0) {
      break;
    }
    step = [NSDate dateWithTimeIntervalSinceNow:0.1];
  }
}


#pragma mark - tests


- (void)test_connect {
  STAssertTrue([self.dbc connect], @"connect");
  [self withTimeout:2 monitorForSuccess:^BOOL{
    return self.dbc.connected;
  }];
  STAssertTrue(self.dbc.connected, @"connected");
}


- (void)test_login {
  [self.dbc connect];
  [self.dbc login];
  [self withTimeout:2 monitorForSuccess:^BOOL{
    return self.dbc.loggedIn;
  }];
  STAssertTrue(self.dbc.loggedIn, @"logged in");
}


- (void)test_call {
  [self.dbc connect];
  [self.dbc login];
  [self.dbc call:@"user" tag:2];

  [self withTimeout:2 monitorForSuccess:^BOOL{
    return self.dbc.user != nil;
  }];

  STAssertNotNil(self.dbc.user, @"user is nil");
  STAssertEqualObjects([self.dbc.user objectForKey:@"is_banned"], [NSNumber numberWithBool:NO], nil);
  STAssertEqualObjects([self.dbc.user objectForKey:@"status"], [NSNumber numberWithInt:0], nil);
  STAssertEqualObjects([self.dbc.user objectForKey:@"user"], [NSNumber numberWithInt:50402], nil);
}


- (void)test_balance {
  STAssertTrue([[DbcConnector sharedInstance] balance] > 0, @"balance must be > 0", nil);
}


- (void)test_upload {
  [self.dbc connect];
  [self.dbc login];
  UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[DbcConnector class]] pathForResource:@"test222" ofType:@"png"]];
  STAssertNotNil(image, @"image must not be nil", nil);
  
  NSString *imageId = [self.dbc upload:image];
  STAssertNotNil(imageId, @"imageId must not be nil", nil);
  
  [self withTimeout:30 monitorForSuccess:^BOOL{
    return [[self.dbc.decoded objectForKey:imageId] objectForKey:@"captcha"] != nil
    && [self.dbc.uploadQueue count] == 0;
  }];
  STAssertTrue([self.dbc.uploadQueue count] == 0, @"upload queue size must be 0", nil);
  NSDictionary *result = [self.dbc.decoded objectForKey:imageId];
  STAssertNotNil(result, @"result must not be nil", nil);
  id captcha = [result objectForKey:@"captcha"];
  STAssertNotNil(captcha, @"captcha must not be nil", nil);
}


- (void)test_decode {
  [self.dbc connect];
  [self.dbc login];
  UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[DbcConnector class]] pathForResource:@"test222" ofType:@"png"]];
  NSString *res = [self.dbc decode:image];
  STAssertEqualObjects(@"037233", res, @"decoding result");
}

@end
