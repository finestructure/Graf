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


#warning TEMPORARY
NSString *kUser = @"abstracture";
NSString *kPass = @"i8Kn37rD8v";
NSString *kHostname = @"api.deathbycaptcha.com";
#warning Make port a range
const int kPort = 8123; // to 8131

const long kLoginTag = 1;
const long kUserTag = 2;
const long kUploadTag = 3;
const long kCaptchaTag = 4;


@implementation DbcConnector

@synthesize socket = _socket;
@synthesize connected = _connected;
@synthesize loggedIn = _loggedIn;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize done = _done;
@synthesize response = _response;
@synthesize user = _user;
@synthesize decoded = _decoded;
@synthesize imageQueue = _imageQueue;


#pragma mark - initializers


+ (DbcConnector *)sharedInstance {
  static DbcConnector *sharedInstance = nil;
  
  if (sharedInstance) {
    return sharedInstance;
  }
  
  @synchronized(self) {
    if (!sharedInstance) {
      sharedInstance = [[DbcConnector alloc] init];
      [sharedInstance connect];
      [sharedInstance login];
    }
    
    return sharedInstance;
  }
}


- (id)init {
  self = [super init];
  if (self) {
    NSLog(@"init");
    requestQueue = dispatch_queue_create("dbc-connector-request-queue", NULL);
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:requestQueue];
    self.connected = NO;
    self.loggedIn = NO;
    self.decoded = [NSMutableDictionary dictionary];
    self.imageQueue = [NSMutableArray array];
  }
  return self;
}


- (void)dealloc {
  dispatch_release(requestQueue);
}


#pragma mark - API methods


- (BOOL)connect {
  NSLog(@"connecting...");
  NSError *err = nil;
  if (![self.socket connectToHost:kHostname onPort:kPort error:&err]) {
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


- (float)balance {
  [self call:@"user" tag:kUserTag];
  [self withTimeout:5 monitorForSuccess:^BOOL{
    return self.user != nil;
  }];
  return [[self.user objectForKey:@"balance"] floatValue];
}


#pragma mark - internal methods


- (void)withTimeout:(NSUInteger)seconds monitorForSuccess:(BOOL (^)())block {
  NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:seconds];
  NSDate *step = [NSDate dateWithTimeIntervalSinceNow:0.1];
  while (!block() && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:step]) {
    // break when the timeout is reached 
    if ([timeout timeIntervalSinceDate:[NSDate date]] < 0) {
      break;
    }
    step = [NSDate dateWithTimeIntervalSinceNow:0.1];
  }
}


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
  NSString *md5 = [imageData MD5];
  NSString *base64Data = [imageData base64EncodedString];
  NSDictionary *data = [NSDictionary dictionaryWithObject:base64Data forKey:@"captcha"];
  [self.decoded setObject:[NSMutableDictionary dictionary] forKey:md5];
  [self.imageQueue enqueue:md5];

  [self call:@"upload" withData:data tag:kUploadTag];
  
  return md5;
}


- (NSString *)decode:(UIImage *)image {
  NSUInteger captchaId = 0; //[self upload:image];
  if (captchaId > 0) {
    NSUInteger maxTries = 6;
    NSUInteger callCount = 0;
    while (callCount < maxTries) {
      if (callCount > 0) {
        NSLog(@"waiting for result");
//        [self waitWithTimeout:5];
      }
      NSLog(@"polling");
      id response = nil; //[self call:@"captcha" withData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:captchaId] forKey:@"captcha"]];
      callCount++;
      if (response != nil && [response objectForKey:@"text"] != nil) {
        return [response objectForKey:@"text"];    
      }
    }
  } else {
    NSLog(@"captcha id returned from upload was <= 0: %d", captchaId);
  }
  return nil;
}


#pragma mark - GCDAsyncSocketDelegate


- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port {
  NSLog(@"connected!");
  self.connected = YES;
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  NSLog(@"wrote data with tag %ld", tag);
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  NSLog(@"tag: %ld", tag);
  NSLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
  if (tag == kLoginTag) {
    self.loggedIn = YES;
  } else if (tag == kUserTag) {
    NSError *error = nil;
    id res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSAssert((error == nil), @"error must be nil but is: %@", error);
    self.user = res;
  } else if (tag == kUploadTag) {
    NSError *error = nil;
    id res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSAssert((error == nil), @"error must be nil but is: %@", error);
    NSLog(@"upload response: %@", res);
    id md5 = [self.imageQueue dequeue];
    NSMutableDictionary *dict = [self.decoded objectForKey:md5];
    [dict addEntriesFromDictionary:res];
  }
}


- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
  NSLog(@"didReadPartialDataOfLength: %d for tag: %ld", partialLength, tag);
}


@end
