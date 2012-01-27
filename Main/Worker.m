//
//  Worker.m
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Worker.h"
#import "NSData+MD5.h"


@implementation Worker

@synthesize dbc = _dbc;
@synthesize image = _image;
@synthesize imageId = _imageId;
@synthesize textResut = _textResut;
@synthesize command = _command;


- (id)initWithImage:(UIImage *)image {
  self = [super init];
  if (self) {
    executing = NO;
    finished = NO;
    self.dbc = [[DbcConnector alloc] init];
    self.image = image;
    NSData *imageData = UIImagePNGRepresentation(image);
    self.imageId = [imageData MD5];
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
      self.dbc.delegate = self;

      if (self.command == kUpload) {
        [self.dbc upload:self.image];
      } else if (self.command == kPoll) {
        [self.dbc pollWithInterval:5 
                           timeout:60 
                        forImageId:self.imageId 
                 completionHandler:^{} 
                    timeoutHandler:^{
                      [self completeOperation];
                    }];
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
}

- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result {
  self.textResut = result;
  [self completeOperation];
}

- (void)didUploadImageId:(NSString *)imageId {
  NSLog(@"uploaded image %@", imageId);
  [self.dbc pollWithInterval:5 
                     timeout:60 
                  forImageId:imageId 
           completionHandler:^{} 
              timeoutHandler:^{
                [self completeOperation];
              }];
}


- (void)didDisconnectWithError:(NSError *)error {
  [self completeOperation];
}

- (void)didUpdateBalance:(float)newBalance {
  
}


@end
