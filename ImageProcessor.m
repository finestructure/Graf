//
//  ImageProcessor.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"
#import "NSData+MD5.h"


@implementation ImageProcessor

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
  

  return imageId;
}


- (void)pollForImageId:(NSString *)imageId {
  
}


@end
