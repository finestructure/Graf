//
//  Image.m
//  Graf
//
//  Created by Sven A. Schmidt on 25.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Image.h"

@implementation Image

@synthesize image = _image;
@synthesize imageId = _imageId;
@synthesize state = _state;
@synthesize start = _start;
@synthesize processingTime = _processingTime;
@synthesize textResult = _textResult;
@synthesize isInTransition = _isInTransition;


- (id)init {
  self = [super init];
  if (self) {
    self.state = kIdle;
    self.isInTransition = NO;
  }
  return self;
}


- (void)transitionTo:(ImageState)newState {
  switch (self.state) {
    case kIdle:
      if (newState == kProcessing) {
        self.start = [NSDate date];
      }
      break;
      
    case kProcessing:
      if (newState == kIdle || newState == kTimeout) {
        self.processingTime = [self elapsed];
      }
      break;

    case kTimeout:
      if (newState == kProcessing) {
        self.start = [NSDate date];
      }
      break;
  }
  self.state = newState;
  self.isInTransition = YES;
}


- (NSTimeInterval)elapsed {
  return [[NSDate date] timeIntervalSinceDate:self.start];
}


@end
