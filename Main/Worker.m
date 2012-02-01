//
//  Worker.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Worker.h"


@implementation Worker

@synthesize dbc = _dbc;
@synthesize image = _image;
@synthesize captchaId = _captchaId;
@synthesize imageId = _imageId;
@synthesize textResult = _textResult;
@synthesize command = _command;
@synthesize hasTimedOut = _timedout;


const int kTimeout = 15;


- (id)initWithImage:(UIImage *)image {
  self = [super init];
  if (self) {
    executing = NO;
    finished = NO;
    self.hasTimedOut = NO;
    self.dbc = [[DbcConnector alloc] init];
    self.dbc.delegate = self;
    self.image = image;
    // default command
    self.command = kUpload;
  }
  return self;
}


- (void)start {
  if ([self isCancelled]) {
    // Must move the operation to the finished state if it is canceled
    [self willChangeValueForKey:@"isFinished"];
    finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    return;
  }
  
  // If the operation is not canceled, begin executing the task.
  [self willChangeValueForKey:@"isExecuting"];
  [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
  executing = YES;
  [self didChangeValueForKey:@"isExecuting"];
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
                        [self completeOperation];
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


- (void)completeOperation {
  [self willChangeValueForKey:@"isFinished"];
  [self willChangeValueForKey:@"isExecuting"];
  executing = NO;
  finished = YES;
  [self didChangeValueForKey:@"isExecuting"];
  [self didChangeValueForKey:@"isFinished"];
}


- (BOOL)isConcurrent {
  return YES;
}


- (BOOL)isExecuting {
  return executing;
}


- (BOOL)isFinished {
  return finished;
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
  [self completeOperation];
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
                [self completeOperation];
              }];
}

- (void)didDisconnectWithError:(NSError *)error {
  [self completeOperation];
}

- (void)didUpdateBalance:(float)newBalance {
  
}


@end
