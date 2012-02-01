//
//  Worker.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Worker.h"


@implementation Worker

@synthesize isFinished = _isFinished;
@synthesize hasTimedOut = _hasTimedOut;
@synthesize dbc = _dbc;
@synthesize image = _image;
@synthesize captchaId = _captchaId;
@synthesize imageId = _imageId;
@synthesize textResult = _textResult;
@synthesize command = _command;


const int kTimeout = 15;


- (id)initWithImage:(UIImage *)image {
  self = [super init];
  if (self) {
    self.isFinished = NO;
    self.hasTimedOut = NO;
    self.dbc = [[DbcConnector alloc] init];
    self.dbc.delegate = self;
    self.image = image;
    // default command
    self.command = kUpload;
  }
  return self;
}


- (void)main {
  @try {
    @autoreleasepool {
      [self.dbc connect];
      [self.dbc login];

      if (self.command == kUpload) {
        NSLog(@"Worker executing upload command");
        [self.dbc upload:self.image];
      } else if (self.command == kPoll) {
        NSLog(@"Worker executing poll command");
        if (self.captchaId != nil) {
          [self.dbc pollWithInterval:5 
                             timeout:kTimeout 
                           captchaId:self.captchaId 
                   completionHandler:^{} 
                      timeoutHandler:^{
                        self.hasTimedOut = YES;
                        self.isFinished = YES;
                      }];
        } else {
          NSLog(@"Error: poll called without captcha id being set");
        }
      } else {
        NSLog(@"Error: Unknown command sent to Worker");
      }
    }
  } @catch(...) {
    // Do not rethrow exceptions.
  }
}


#pragma mark - DbcConnectorDelegate

- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"worker connected to host %@:%d", host, port);
}

- (void)didLogInAs:(NSString *)user {
  NSLog(@"worker logged in as %@", user);
}

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

- (void)didDisconnectWithError:(NSError *)error {
  self.hasTimedOut = YES;
  self.isFinished = YES;
}

- (void)didDisconnect {
  self.isFinished = YES;
}

- (void)didUpdateBalance:(float)newBalance {
  
}


@end
