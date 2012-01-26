//
//  ImagePoller.m
//  Sinma
//
//  Created by Sven A. Schmidt on 23.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImagePoller.h"
#import "DbcConnector.h"


@implementation ImagePoller

@synthesize startDate = _startDate;
@synthesize interval = _interval;
@synthesize isRunning = _isRunning;
@synthesize completionHandler = _completionHandler;
@synthesize timeoutHandler = _timeoutHandler;


- (id)initWithInterval:(NSTimeInterval)interval 
               timeout:(NSTimeInterval)timeout 
               imageId:(NSString *)imageId 
                   dbc:(DbcConnector *)dbc 
     completionHandler:(void (^)())completionHandler
         timeoutHandler:(void (^)())timeoutHandler
{
  self = [super init];
  if (self) {
    self.isRunning = NO;
    self.interval = interval;
    self.completionHandler = completionHandler;
    self.timeoutHandler = timeoutHandler;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_event_handler(_timer, ^{
      NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.startDate];
      NSLog(@"elapsed: %.1f", elapsed);
      NSString *result = [dbc resultForId:imageId];
      NSLog(@"result: %@", result);
      if (result != nil 
          && ! [result isEqualToString:@""]) { // success
        NSLog(@"done");
        self.completionHandler();
        dispatch_source_cancel(_timer);
      } else if (elapsed > timeout) { // timeout
        NSLog(@"timeout");
        self.timeoutHandler();
        dispatch_source_cancel(_timer);
      } else { // poll again
        NSLog(@"polling...");
        [dbc poll:imageId];
      }
    });
  }
  return self;
}


- (void)dealloc {
  dispatch_source_cancel(_timer);
  dispatch_release(_timer);
}


- (void)start {
  if (self.isRunning) {
    return;
  }
  dispatch_source_set_timer(_timer,
                            dispatch_time(DISPATCH_TIME_NOW, 0),
                            self.interval * NSEC_PER_SEC, 0);
  self.startDate = [NSDate date];
  self.isRunning = YES;
  dispatch_resume(_timer);  
}


- (void)stop {
  self.completionHandler();
  dispatch_source_cancel(_timer);
  self.isRunning = NO;
}


@end
