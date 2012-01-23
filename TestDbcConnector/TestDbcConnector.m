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


#pragma mark - tests


- (void)test_decode {
  [self.dbc connect];
  [self.dbc login];
  UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[DbcConnector class]] pathForResource:@"test222" ofType:@"png"]];
  NSString *res = [self.dbc decode:image];
  STAssertEqualObjects(@"037233", res, @"decoding result");
}

@end
