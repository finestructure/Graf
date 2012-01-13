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

- (void)setUp {
  [super setUp];
    
  // Set-up code here.
}

- (void)tearDown {
  // Tear-down code here.
  
  [super tearDown];
}

- (void)test_init {
  DbcConnector *dbc = [[DbcConnector alloc] init];
  STAssertNotNil(dbc, @"dbc not nil");
}

@end
