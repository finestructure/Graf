//
//  ImageProcessor.m
//  Sinma
//
//  Created by Sven A. Schmidt on 12.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"

#warning TEMPORARY
const char *kUser = "abstracture";
const char *kPass = "i8Kn37rD8v";


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
  return @"test";
}


- (float)balance {
  return 0;
}


@end
