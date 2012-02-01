//
//  BaseRequest.h
//  Graf
//
//  Created by Sven A. Schmidt on 01.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbcConnector.h"

extern int const kTimeout;


@interface BaseRequest : NSObject<DbcConnectorDelegate>

@property (nonatomic, assign) BOOL hasTimedOut;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, retain) DbcConnector *dbc;

- (void)start;

@end
