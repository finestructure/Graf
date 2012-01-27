//
//  ImageProcessor.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"
#import "NSData+MD5.h"
#import "Worker.h"


@implementation ImageProcessor

@synthesize delegate = _delegate;
@synthesize queue = _queue;


- (id)init {
  self = [super init];
  if (self) {
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue setMaxConcurrentOperationCount:4];
  }
  return self;
}


- (NSString *)upload:(UIImage *)image {
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *imageId = [imageData MD5];
  
  Worker *worker = [[Worker alloc] initWithImageId:image];
  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  [self.queue addOperation:worker];

  return imageId;
}


- (void)pollForImageId:(NSString *)imageId {
  
}

#pragma KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  NSLog(@"KVO: %@ %@ %@", keyPath, object, change);
  if ([keyPath isEqualToString:@"isFinished"]) {
    Worker *worker = (Worker *)object;
    if ([worker isFinished]) {
      NSLog(@"result: %@", worker.textResut);
      if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
        [self.delegate didDecodeImageId:worker.imageId result:worker.textResut];
      }
    } else {
      NSLog(@"not finished");
    }
  }
}


@end
