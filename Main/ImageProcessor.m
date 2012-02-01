//
//  ImageProcessor.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"
#import "Worker.h"


@implementation ImageProcessor

@synthesize delegate = _delegate;
@synthesize queue = _queue;


- (id)init {
  self = [super init];
  if (self) {
    self.queue = [NSMutableArray array];
  }
  return self;
}


- (void)upload:(UIImage *)image {  
  Worker *worker = [[Worker alloc] initWithImage:image];
  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  [worker main];
  [self.queue addObject:worker];
}


- (void)refreshBalance {
#warning implement me!
//  Worker *worker = [[Worker alloc] init];
//  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
//  [worker refreshBalance];
//  [self.queue addObject:worker];
}


#pragma KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  NSLog(@"KVO: %@ %@ %@", keyPath, object, change);
  if ([keyPath isEqualToString:@"isFinished"]) {
    Worker *worker = (Worker *)object;
    if ([worker isFinished]) {
      if (worker.hasTimedOut) {
        if ([self.delegate respondsToSelector:@selector(didTimeoutDecodingImageId:)]) {
          [self.delegate didTimeoutDecodingImageId:worker.imageId];
        }
      } else {
        NSLog(@"result: %@", worker.textResult);
        if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
          [self.delegate didDecodeImageId:worker.imageId result:worker.textResult];
        }
      }
      [self.queue removeObject:worker];
    }
  }
}


@end
