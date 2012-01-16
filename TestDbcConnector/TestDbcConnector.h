//
//  TestDbcConnector.h
//  TestDbcConnector
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "DbcConnector.h"


@interface TestDbcConnector : SenTestCase

@property (nonatomic, retain) DbcConnector *dbc;

@end
