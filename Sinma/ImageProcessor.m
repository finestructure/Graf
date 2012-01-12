//
//  ImageProcessor.m
//  Sinma
//
//  Created by Sven A. Schmidt on 12.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"

#include "deathbycaptcha.h"

#warning TEMPORARY
const char *kUser = "abstracture";
const char *kPass = "i8Kn37rD8v";


@interface ImageProcessor () {
  dbc_client *_client;
}
@end


@implementation ImageProcessor


- (id)init {
  self = [super init];
  if (self) {
    _client = (dbc_client *)malloc(sizeof(dbc_client));
    if (dbc_init(_client, kUser, kPass)) {
      NSLog(@"Failed to initialize DBC client");
    } else {
      _client->is_verbose = 1;
    }
  }
  return self;
}


- (void)dealloc {
  dbc_close(_client);
  free(_client);
}


- (NSString *)processImage:(UIImage *)image
{
  NSLog(@"balance: %f", [self balance]);
  return @"";
}


- (float)balance {
  dbc_get_balance(_client);
  return _client->balance;
}


@end
