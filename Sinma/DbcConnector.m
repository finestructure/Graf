//
//  DbcConnector.m
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "DbcConnector.h"
#import "NSData+Base64.h"


#warning TEMPORARY
const NSString *kUser = @"abstracture";
const NSString *kPass = @"i8Kn37rD8v";
const NSString *kHostname = @"api.deathbycaptcha.com";
const int kPort = 8123; // to 8131


@implementation DbcConnector

@synthesize connected = _connected;
@synthesize loggedIn = _loggedIn;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize done = _done;
@synthesize response = _response;


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
    self.connected = NO;
    self.loggedIn = NO;
  }
  return self;
}


- (BOOL)connect {
  CFReadStreamRef readStream;
  CFWriteStreamRef writeStream;
  CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)kHostname, kPort, &readStream, &writeStream);
  self.inputStream = (__bridge_transfer NSInputStream *)readStream;
  self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;

  [self.inputStream setDelegate:self];
  [self.outputStream setDelegate:self];

  [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

  [self.inputStream open];
  [self.outputStream open];

  self.connected = YES;
  return YES;
}


- (void)waitWithTimeout:(NSUInteger)seconds {
  NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:seconds];
  while (!self.done && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout]) {
    // break when the timeout is reached 
    if ([timeout timeIntervalSinceDate:[NSDate date]] < 0) {
      break;
    }
  }
}



- (void)login {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"abstracture", @"username",
                        @"i8Kn37rD8v", @"password",
                        nil];
  [self call:@"login" withData:dict];
  self.loggedIn = YES;
}


- (NSString *)call:(NSString *)command {
  return [self call:command withData:nil];
}


- (NSString *)call:(NSString *)command withData:(NSDictionary *)data {
  NSLog(@"call: %@", command);
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:data];
  [dict setObject:command forKey:@"cmd"];
  NSError *error = nil;
  NSData *request = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
  NSAssert((error == nil), @"error must be nil, it is: %@", error);
  
  self.done = NO;
  self.response = nil;
  NSLog(@"request byte count: %d", [request length]);
  
  NSRange range = NSMakeRange(0, [request length]);
  while (range.length > 0) {
    NSInteger written = [self.outputStream write:[request bytes] maxLength:[request length]];
    range = NSMakeRange(written, range.length - written);
    request = [request subdataWithRange:range];
  }
  
  [self waitWithTimeout:15];
  
  id res = nil;
  {
    NSData *data = [self.response dataUsingEncoding:NSASCIIStringEncoding];
    if (data != nil) {
      NSError *error = nil;
      res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
      NSAssert((error == nil), @"error must be nil, it is: %@", error);
    }
  }
  
  if (res == nil || [res objectForKey:@"error"] != nil) {
    NSLog(@"error in response: %@", [res objectForKey:@"error"]);
  }
  
  return res;
}


- (float)balance {
  return [[[self call:@"user"] objectForKey:@"balance"] floatValue];
}


- (NSUInteger)upload:(UIImage *)image {
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *base64Data = [imageData base64EncodedString];
  NSDictionary *data = [NSDictionary dictionaryWithObject:base64Data forKey:@"captcha"];
  id response = [self call:@"upload" withData:data];
  NSLog(@"upload response: %@", response);
  id captchaId = [response objectForKey:@"captcha"];
  return [captchaId unsignedIntegerValue];
}


- (NSString *)decode:(UIImage *)image {
  NSUInteger captchaId = [self upload:image];
  if (captchaId > 0) {
    NSUInteger maxTries = 6;
    NSUInteger callCount = 0;
    while (callCount < maxTries) {
      if (callCount > 0) {
        NSLog(@"waiting for result");
        [self waitWithTimeout:5];
      }
      NSLog(@"polling");
      id response = [self call:@"captcha" withData:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:captchaId] forKey:@"captcha"]];
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


#pragma mark - NSStreamDelegate


- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	switch (streamEvent) {
      
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
      
		case NSStreamEventHasBytesAvailable:
      if (theStream == self.inputStream) {
        
        NSMutableString *result = nil;
        uint8_t buffer[1024];
        int len;
        
        while ([self.inputStream hasBytesAvailable]) {
          len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
          if (len > 0) {
            NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
            if (result != nil) {
              [result appendString:output];
            } else {
              result = [NSMutableString stringWithString:output];
            }
          }

        }
        
        if (result != nil) {
          NSLog(@"server said: %@", result);
          self.response = result;
        }
        self.done = YES;
      }
      break;
      
    case NSStreamEventHasSpaceAvailable:
      NSLog(@"Has space available");
      break;
      
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
      
		case NSStreamEventEndEncountered:
			NSLog(@"Stream end event");
			break;
      
    default:
			NSLog(@"Unknown event");
	}
}


@end
