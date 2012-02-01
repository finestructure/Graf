//
//  Worker.h
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DbcConnector.h"


typedef enum WorkerCommands {
  kUpload,
  kPoll
} WorkerCommands;


@interface Worker : NSOperation<DbcConnectorDelegate> {
  BOOL executing;
  BOOL finished;
}


@property (nonatomic, retain) DbcConnector *dbc;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, retain) NSNumber *captchaId;
@property (nonatomic, copy) NSString *textResult;
@property (nonatomic, assign) WorkerCommands command;
@property (nonatomic, assign) BOOL hasTimedOut;


- (id)initWithImage:(UIImage *)image;
- (void)completeOperation;

@end
