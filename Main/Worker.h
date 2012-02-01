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


@interface Worker : NSObject<DbcConnectorDelegate>

@property (nonatomic, assign) BOOL hasTimedOut;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, retain) DbcConnector *dbc;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, retain) NSNumber *captchaId;
@property (nonatomic, copy) NSString *textResult;
@property (nonatomic, assign) WorkerCommands command;


- (id)initWithImage:(UIImage *)image;

- (void)main;
- (BOOL)isFinished;

@end
