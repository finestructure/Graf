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
const int kPortStart = 8123;
const int kPortEnd = 8130;


@implementation DbcConnector

@synthesize delegate = _delegate;
@synthesize connected = _connected;
@synthesize loggedIn = _loggedIn;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize imagePoller = _imagePoller;
@synthesize textResult = _textResult;
@synthesize imageId = _imageId;


- (id)init {
  self = [super init];
  if (self) {
    self.connected = NO;
    self.loggedIn = NO;
  }
  return self;
}


#pragma mark - API methods


- (int)randomPort {
  int delta = kPortEnd - kPortStart;
  return kPortStart + (arc4random() % (delta+1));
}


- (void)connect {
  CFReadStreamRef readStream;
  CFWriteStreamRef writeStream;
  CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)kHostname, [self randomPort], &readStream, &writeStream);
  self.inputStream = (__bridge_transfer NSInputStream *)readStream;
  self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;

  [self.inputStream setDelegate:self];
  [self.outputStream setDelegate:self];

  [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

  [self.inputStream open];
  [self.outputStream open];

  self.connected = YES;
}


- (void)login {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"abstracture", @"username",
                        @"i8Kn37rD8v", @"password",
                        nil];
  [self call:@"login" withData:dict];
  self.loggedIn = YES;
}


- (void)updateBalance {
  [self call:@"user"];  
}


- (void)upload:(UIImage *)image {
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *base64Data = [imageData base64EncodedString];
  NSDictionary *data = [NSDictionary dictionaryWithObject:base64Data forKey:@"captcha"];
  [self call:@"upload" withData:data];
}


- (void)pollWithCaptchaId:(NSString *)captchaId {
  NSLog(@"polling captchaId: %@", captchaId);
  if (captchaId != nil) { // can be nil if we poll before the upload is done
    // and call 'captcha'
    [self call:@"captcha" withData:[NSDictionary dictionaryWithObject:captchaId forKey:@"captcha"]];
  }
}


#pragma mark - internal methods


- (void)call:(NSString *)command {
  [self call:command withData:nil];
}


- (void)call:(NSString *)command withData:(NSDictionary *)data {
  NSLog(@"call: %@", command);
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:data];
  [dict setObject:command forKey:@"cmd"];
  NSError *error = nil;
  NSData *request = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
  NSAssert((error == nil), @"error must be nil, it is: %@", error);
  
  NSLog(@"request byte count: %d", [request length]);
  
  NSRange range = NSMakeRange(0, [request length]);
  while (range.length > 0) {
    NSInteger written = [self.outputStream write:[request bytes] maxLength:[request length]];
    range = NSMakeRange(written, range.length - written);
    request = [request subdataWithRange:range];
  }
}


- (void)pollWithInterval:(NSTimeInterval)interval 
                 timeout:(NSTimeInterval)timeout 
               captchaId:(NSString *)captchaId 
       completionHandler:(void (^)())completionHandler
          timeoutHandler:(void (^)())timeoutHandler
{  
  self.imagePoller = [[ImagePoller alloc] initWithInterval:interval 
                                                   timeout:timeout 
                                                 captchaId:captchaId
                                                       dbc:self 
                                         completionHandler:completionHandler
                                            timeoutHandler:timeoutHandler];
  [self.imagePoller start];
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
#warning implement result handling
        }
      }
      break;
      
    case NSStreamEventHasSpaceAvailable:
      NSLog(@"Has space available");
      break;
      
		case NSStreamEventErrorOccurred:
			NSLog(@"Error");
			break;
      
		case NSStreamEventEndEncountered:
			NSLog(@"Stream end event");
			break;
      
    default:
			NSLog(@"Unknown event: %@", streamEvent);
	}
}


@end
