//
//  DbcConnector.m
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "DbcConnector.h"
#import "NSData+Base64.h"
#import "NSData+MD5.h"
#import "NSMutableArray+QueueAdditions.h"

#include <stdlib.h>


#warning TEMPORARY
NSString *kUser = @"abstracture";
NSString *kPass = @"i8Kn37rD8v";
NSString *kHostname = @"api.deathbycaptcha.com";
const int kPortStart = 8123;
const int kPortEnd = 8130;

const long kLoginTag = 1;
const long kUserTag = 2;
const long kUploadTag = 3;
const long kCaptchaTag = 4;


@implementation DbcConnector

@synthesize delegate = _delegate;
@synthesize socket = _socket;
@synthesize connected = _connected;
@synthesize loggedIn = _loggedIn;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize done = _done;
@synthesize response = _response;
@synthesize user = _user;
@synthesize decoded = _decoded;
@synthesize uploadQueue = _uploadQueue;
@synthesize captchaQueue = _captchaQueue;
@synthesize imagePoller = _imagePoller;


#pragma mark - initializers


- (id)init {
  self = [super init];
  if (self) {
    NSLog(@"init");
    requestQueue = dispatch_queue_create("dbc-connector-request-queue", NULL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:requestQueue];
    self.connected = NO;
    self.loggedIn = NO;
    self.decoded = [NSMutableDictionary dictionary];
    self.uploadQueue = [NSMutableArray array];
    self.captchaQueue = [NSMutableArray array];
  }
  return self;
}


- (void)dealloc {
  dispatch_release(requestQueue);
}


#pragma mark - API methods


- (int)randomPort {
  int delta = kPortEnd - kPortStart;
  return kPortStart + (arc4random() % (delta+1));
}


- (BOOL)connect {
  if (self.connected) {
    NSLog(@"already connected");
    return YES;
  }
  
  int port = [self randomPort];
  NSLog(@"connecting at port %d...", port);
  NSError *err = nil;
  if (![self.socket connectToHost:kHostname onPort:port error:&err]) {
    // If there was an error, it's likely something like "already connected" or "no delegate set"
    NSLog(@"Connection error: %@", err);
    self.connected = NO;
    return NO;
  }
  return YES;
}


- (void)login {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        kUser, @"username",
                        kPass, @"password",
                        nil];
  [self call:@"login" withData:dict tag:kLoginTag];
}


- (void)updateBalance {
  [self call:@"user" tag:kUserTag];  
}


- (float)balance {
  return [[self.user objectForKey:@"balance"] floatValue];
}


- (NSString *)resultForId:(NSString *)imageId {
  return [[self.decoded objectForKey:imageId] objectForKey:@"text"];
}


#pragma mark - internal methods


//- (void)withTimeout:(NSUInteger)seconds monitorForSuccess:(BOOL (^)())block {
//  NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:seconds];
//  NSDate *step = [NSDate dateWithTimeIntervalSinceNow:0.1];
//  while (!block() && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:step]) {
//    // break when the timeout is reached 
//    if ([timeout timeIntervalSinceDate:[NSDate date]] < 0) {
//      break;
//    }
//    step = [NSDate dateWithTimeIntervalSinceNow:0.1];
//  }
//}


- (void)call:(NSString *)command tag:(long)tag {
  return [self call:command withData:nil tag:tag];
}


- (void)call:(NSString *)command withData:(NSDictionary *)data tag:(long)tag {
  NSLog(@"call: %@", command);
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:data];
  [dict setObject:command forKey:@"cmd"];
  NSError *error = nil;
  NSData *request = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
  NSAssert((error == nil), @"error must be nil, it is: %@", error);
  NSLog(@"request byte count: %d", [request length]);
  
  [self.socket writeData:request withTimeout:30 tag:tag];
  [self.socket readDataWithTimeout:30 tag:tag];
}


- (NSString *)upload:(UIImage *)image {
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *imageId = [imageData MD5];
  NSString *base64Data = [imageData base64EncodedString];
  NSDictionary *data = [NSDictionary dictionaryWithObject:base64Data forKey:@"captcha"];
  [self.decoded setObject:[NSMutableDictionary dictionary] forKey:imageId];

  // put image id in queue to be picked up by socket:didReadData:withTag:
  [self.uploadQueue enqueue:imageId];
  // and call 'upload'
#warning temporarily disabled
  [self call:@"upload" withData:data tag:kUploadTag];
  
  return imageId;
}


- (void)pollWithInterval:(NSTimeInterval)interval timeout:(NSTimeInterval)timeout forImageId:(NSString *)imageId completionHandler:(void (^)())block
{
  if (self.imagePoller != nil && self.imagePoller.isRunning) {
    NSLog(@"Warning: there's already a poller running. It will be disabled.");
  }
  self.imagePoller = [[ImagePoller alloc] initWithInterval:interval timeout:timeout imageId:imageId dbc:self completionHandler:block];
  [self.imagePoller start];  
}


- (void)poll:(NSString *)imageId {
  NSDictionary *captchaObject = [self.decoded objectForKey:imageId];

  NSLog(@"polling for captchaObject: %@", captchaObject);
  id captchaId = [captchaObject objectForKey:@"captcha"];
  NSLog(@"captchaId: %@", captchaId);
  if (captchaId != nil) { // can be nil if we poll before the upload is done
    // put image id in queue to be picked up by socket:didReadData:withTag:
    [self.captchaQueue enqueue:imageId];
    // and call 'captcha'
    [self call:@"captcha" withData:[NSDictionary dictionaryWithObject:captchaId forKey:@"captcha"] tag:kCaptchaTag];
  }
}


//- (NSString *)_decode:(UIImage *)image {
//  NSString *imageId = [self upload:image];
//  NSDictionary *captchaObject = [self.decoded objectForKey:imageId];
//
//  NSUInteger maxTries = 12;
//  NSUInteger callCount = 0;
//  while (callCount < maxTries) {
//    // check for result key - will be set asynchronously from socket:didReadData:withTag:
//    NSLog(@"waiting for result");
//    [self withTimeout:5 monitorForSuccess:^BOOL{
//      NSString *textResult = [captchaObject objectForKey:@"text"];
//      return (textResult != nil && ! [textResult isEqualToString:@""]);
//    }];
//
//    // check if we have a result value, if so, return
//    NSString *textResult = [captchaObject objectForKey:@"text"];
//    if (textResult != nil && ! [textResult isEqualToString:@""]) {
//      NSLog(@"returning result: >%@<", textResult);
//      return textResult;
//    } else { // otherwise poll
//      NSLog(@"polling");
//      id captchaId = [captchaObject objectForKey:@"captcha"];
//      NSLog(@"captchaId: %@", captchaId);
//      if (captchaId != nil) { // can be nil if we poll before the upload is done
//        // put image id in queue to be picked up by socket:didReadData:withTag:
//        [self.captchaQueue enqueue:imageId];
//        // and call 'captcha'
//        [self call:@"captcha" withData:[NSDictionary dictionaryWithObject:captchaId forKey:@"captcha"] tag:kCaptchaTag];
//      }
//    }
//    callCount++;
//  }
//  return nil;
//}


#pragma mark - GCDAsyncSocketDelegate


- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"connected!");
  self.connected = YES;
  if ([self.delegate respondsToSelector:@selector(didConnectToHost:port:)]) {
    [self.delegate didConnectToHost:host port:port];
  }
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  NSLog(@"wrote data with tag %ld", tag);
}


- (id)jsonResponse:(NSData *)data {
  NSError *error = nil;
  id res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  NSAssert((error == nil), @"error must be nil but is: %@", error);
  return res;
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  NSLog(@"didReadData: (%ld) %@", tag, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
  if (tag == kLoginTag) {
    self.user = [self jsonResponse:data];
    self.loggedIn = YES;
    if ([self.delegate respondsToSelector:@selector(didLogInAs:)]
        && [self.user objectForKey:@"user"] != nil) {
      [self.delegate didLogInAs:[self.user objectForKey:@"user"]];
    }
  } else if (tag == kUserTag) {
    self.user = [self jsonResponse:data];
    if ([self.delegate respondsToSelector:@selector(didUpdateBalance:)]) {
      [self.delegate didUpdateBalance:[self balance]];
    }
  } else if (tag == kUploadTag) {
    id res = [self jsonResponse:data];
    NSLog(@"upload response: %@", res);
    
    id imageId = [self.uploadQueue dequeue];
    NSMutableDictionary *dict = [self.decoded objectForKey:imageId];
    [dict addEntriesFromDictionary:res];
    
    NSString *textResult = [dict objectForKey:@"text"];
    if (textResult != nil && ! [textResult isEqualToString:@""]) {
      if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
        [self.delegate didDecodeImageId:imageId result:textResult];
      }
    }
  } else if (tag == kCaptchaTag) {
    id res = [self jsonResponse:data];
    NSLog(@"captcha response: %@", res);

    id imageId = [self.captchaQueue dequeue];
    NSMutableDictionary *dict = [self.decoded objectForKey:imageId];
    [dict addEntriesFromDictionary:res];
    if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
      NSString *textResult = [dict objectForKey:@"text"];
      if (textResult != nil && ! [textResult isEqualToString:@""]) {
        [self.delegate didDecodeImageId:imageId result:textResult];
      }
    }
  }
}


- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
  NSLog(@"didReadPartialDataOfLength: %d for tag: %ld", partialLength, tag);
}


- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
  NSLog(@"read timeout: (%ld) %ud", tag, length);
  return 0;
}


- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
  NSLog(@"write timeout: (%ld) %ud", tag, length);
  return 0;
}


- (void)socketDidCloseReadStream:(GCDAsyncSocket *)socket {
  NSLog(@"socket closed");
  self.connected = NO;
  self.loggedIn = NO;
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
  NSLog(@"disconnected! %@", [error localizedDescription]);
  self.connected = NO;
  self.loggedIn = NO;
  if ([self.delegate respondsToSelector:@selector(didDisconnectWithError:)]) {
    [self.delegate didDisconnectWithError:error];
  }
}


@end
