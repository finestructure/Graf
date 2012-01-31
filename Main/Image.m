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


- (id)init {
  self = [super init];
  if (self) {
    self.state = kIdle;
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
      if (newState == kIdle) {
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
}


- (NSTimeInterval)elapsed {
  return [[NSDate date] timeIntervalSinceDate:self.start];
}


@end
