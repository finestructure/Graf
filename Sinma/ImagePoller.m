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

@synthesize start = _start;


- (id)initWithInterval:(NSTimeInterval)interval timeout:(NSTimeInterval)timeout imageId:(NSString *)imageId dbc:(DbcConnector *)dbc {
  self = [super init];
  if (self) {
    self.start = [NSDate date];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer,
                              dispatch_time(DISPATCH_TIME_NOW, 0),
                              interval * NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(_timer, ^{
      NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.start];
      NSLog(@"elapsed: %.1f", elapsed);
      NSString *result = [dbc resultForId:imageId];
      NSLog(@"result: %@", result);
      if ((elapsed <= timeout) && (result == nil || [result isEqualToString:@""])) {
        NSLog(@"polling...");
        [dbc poll:imageId];
      } else {
        NSLog(@"done");
        dispatch_source_cancel(_timer);
      }
    });
    
    // now that our timer is all set to go, start it
    dispatch_resume(_timer);
  }
  return self;
}

@end
