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
      _client->is_verbose = 0;
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
  NSString *result = nil;
  NSData *data = UIImagePNGRepresentation(image);
  
  dbc_captcha *captcha = (dbc_captcha *)malloc(sizeof(dbc_captcha));
  if (dbc_init_captcha(captcha)) {
    NSLog(@"Failed initializing a CAPTCHA instance");
  } else {
    
    if (dbc_decode(_client, captcha, [data bytes], [data length], 30)) {
      if (_client->balance <= 0) {
        NSLog(@"Insufficied funds\n");
      } else {
        NSLog(@"Failed uploading/solving image\n");
      }
    } else if (!captcha->is_correct) {
      NSLog(@"CAPTCHA was marked as invalid by an operator, check if it is in fact a CAPTCHA image and not corrupted");
    } else {
      NSLog(@"%d %s\n", captcha->id, captcha->text);
      result = [NSString stringWithCString:captcha->text encoding:NSASCIIStringEncoding];
    }

    dbc_close_captcha(captcha);
  }
  free(captcha);
  
  return result;
}


- (float)balance {
  dbc_get_balance(_client);
  return _client->balance;
}


@end
