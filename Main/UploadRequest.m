//
//  Worker.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "UploadRequest.h"


@implementation UploadRequest

@synthesize image = _image;
@synthesize captchaId = _captchaId;
@synthesize imageId = _imageId;
@synthesize textResult = _textResult;


- (id)initWithImage:(UIImage *)image {
  self = [super init];
  if (self) {
    self.image = image;
  }
  return self;
}


- (void)start {
  [self.dbc connect];
  [self.dbc login];  
  NSLog(@"Worker executing upload command");
  [self.dbc upload:self.image];
}


#pragma mark - DbcConnectorDelegate


- (void)didDecodeImageId:(NSString *)imageId captchaId:(NSNumber *)captchaId result:(NSString *)result {
  self.imageId = imageId;
  self.captchaId = captchaId;
  self.textResult = result;
  self.isFinished = YES;
}


- (void)didUploadImageId:(NSString *)imageId captchaId:(NSNumber *)captchaId {
  NSLog(@"uploaded image %@ %@", imageId, captchaId);
  self.imageId = imageId;
  self.captchaId = captchaId;
  [self.dbc pollWithInterval:5 
                     timeout:kTimeout 
                   captchaId:captchaId 
           completionHandler:^{} 
              timeoutHandler:^{
                self.hasTimedOut = YES;
                self.isFinished = YES;
              }];
}


@end
