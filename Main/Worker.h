//
//  Worker.h
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbcConnector.h"


@interface Worker : NSOperation<DbcConnectorDelegate> {
  BOOL        executing;
  BOOL        finished;
}


@property (nonatomic, retain) DbcConnector *dbc;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, copy) NSString *textResut;


- (id)initWithImage:(UIImage *)image;
- (void)completeOperation;

@end
