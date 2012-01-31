//
//  WorkerTest.m
//  Graf
//
//  Created by Sven A. Schmidt on 31.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "WorkerTest.h"

@implementation WorkerTest

// All code under test must be linked into the Unit Test bundle
- (void)testMath
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
}

@end
