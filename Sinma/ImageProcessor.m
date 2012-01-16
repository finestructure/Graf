//
//  ImageProcessor.m
//  Sinma
//
//  Created by Sven A. Schmidt on 12.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"
#import "DbcConnector.h"


@implementation ImageProcessor


- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}


- (void)dealloc {
}


- (NSString *)processImage:(UIImage *)image
{
  return [[DbcConnector sharedInstance] decode:image];
}


- (float)balance {
  return [[DbcConnector sharedInstance] balance];
}


@end
