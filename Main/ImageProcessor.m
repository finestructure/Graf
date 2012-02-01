//
//  ImageProcessor.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"
#import "UploadRequest.h"
#import "BalanceRequest.h"


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
  UploadRequest *worker = [[UploadRequest alloc] initWithImage:image];
  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  [worker start];
  [self.queue addObject:worker];
}


- (void)refreshBalance {
  BalanceRequest *request = [[BalanceRequest alloc] init];
  [request addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  [request start];
  [self.queue addObject:request];
}


#pragma mark - Helpers


- (void)uploadRequestFinished:(UploadRequest *)request {
  if (request.hasTimedOut) {
    if ([self.delegate respondsToSelector:@selector(didTimeoutDecodingImageId:)]) {
      [self.delegate didTimeoutDecodingImageId:request.imageId];
    }
  } else {
    NSLog(@"result: %@", request.textResult);
    if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
      [self.delegate didDecodeImageId:request.imageId result:request.textResult];
    }
  }
}


- (void)balanceRequestFinished:(BalanceRequest *)request {
  if (request.hasTimedOut) {
    return;
  }
  if ([self.delegate respondsToSelector:@selector(didRefreshBalance:rate:)]) {
    [self.delegate didRefreshBalance:request.balance rate:request.rate];
  }
}


#pragma mark - KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  NSLog(@"KVO: %@ %@ %@", keyPath, object, change);
  if (! [keyPath isEqualToString:@"isFinished"]) {
    return;
  }
  
  NSAssert([object isKindOfClass:[BaseRequest class]],
           @"object value is not of type BaseRequest as expected.");
  BaseRequest *request = (BaseRequest *)object;
  if (! request.isFinished) {
    return;
  }
  
  if ([object isKindOfClass:[UploadRequest class]]) {
    [self uploadRequestFinished:(UploadRequest *)request];
  } else if ([object isKindOfClass:[BalanceRequest class]]) {
    [self balanceRequestFinished:(BalanceRequest *)request];
  }
  
  [request removeObserver:self forKeyPath:@"isFinished"];
  [self.queue removeObject:request];
}


@end
