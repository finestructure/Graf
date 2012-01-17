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

@synthesize dbc = _dbc;

- (id)init {
  self = [super init];
  if (self) {
    self.dbc = [[DbcConnector alloc] init];
    [self.dbc connect];
    [self.dbc login];
  }
  return self;
}


- (void)dealloc {
}


- (NSString *)processImage:(UIImage *)image
{
  return [self.dbc decode:image];
}


- (float)balance {
  return [self.dbc balance];
}


@end
