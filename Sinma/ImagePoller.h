//
//  ImagePoller.h
//  Sinma
//
//  Created by Sven A. Schmidt on 23.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DbcConnector;

@interface ImagePoller : NSObject {

@private

  dispatch_source_t _timer;
  
}

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, copy) void (^completionHandler)();


- (id)initWithInterval:(NSTimeInterval)interval timeout:(NSTimeInterval)timeout imageId:(NSString *)imageId dbc:(DbcConnector *)dbc completionHandler:(void (^)())block;

- (void)start;
- (void)stop;

@end
