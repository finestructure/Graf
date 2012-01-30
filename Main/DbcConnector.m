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


const NSString *kUser = @"abstracture";
const NSString *kPass = @"i8Kn37rD8v";
const NSString *kHostname = @"api.deathbycaptcha.com";
const int kPortStart = 8123;
const int kPortEnd = 8130;

// valid commands
NSString *kLoginCommand = @"login";
NSString *kUploadCommand = @"upload";
NSString *kUserCommand = @"user";
NSString *kCaptchaCommand = @"captcha";


@implementation DbcConnector

@synthesize delegate = _delegate;
@synthesize connected = _connected;
@synthesize loggedIn = _loggedIn;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize imagePoller = _imagePoller;
@synthesize textResult = _textResult;
@synthesize imageId = _imageId;
@synthesize commandQueue = _commandQueue;


- (id)init {
  self = [super init];
  if (self) {
    self.connected = NO;
    self.loggedIn = NO;
    self.commandQueue = [NSMutableArray array];
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
  int port = [self randomPort];
  CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)kHostname, port, &readStream, &writeStream);
  self.inputStream = (__bridge_transfer NSInputStream *)readStream;
  self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;

  [self.inputStream setDelegate:self];
  [self.outputStream setDelegate:self];

  [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

  [self.inputStream open];
  [self.outputStream open];

  self.connected = YES;
  if ([self.delegate respondsToSelector:@selector(didConnectToHost:port:)]) {
    [self.delegate didConnectToHost:[kHostname copy] port:port];
  }
}


- (void)login {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        kUser, @"username",
                        kPass, @"password",
                        nil];
  [self call:kLoginCommand withData:dict];
}


- (void)updateBalance {
  [self call:kUserCommand];  
}


- (void)upload:(UIImage *)image {
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *base64Data = [imageData base64EncodedString];
  self.imageId = [imageData MD5];
  NSDictionary *data = [NSDictionary dictionaryWithObject:base64Data forKey:@"captcha"];
  [self call:kUploadCommand withData:data];
}


- (void)pollWithCaptchaId:(NSNumber *)captchaId {
  NSLog(@"polling captchaId: %@", captchaId);
  if (captchaId != nil) { // can be nil if we poll before the upload is done
    // and call 'captcha'
    [self call:kCaptchaCommand withData:[NSDictionary dictionaryWithObject:captchaId forKey:@"captcha"]];
  }
}


#pragma mark - Internal methods


- (void)call:(NSString *)command {
  [self call:command withData:nil];
}


- (void)call:(NSString *)command withData:(NSDictionary *)data {
  @synchronized(self.commandQueue) {
    [self.commandQueue addObject:command];
  }
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
               captchaId:(NSNumber *)captchaId 
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


#pragma mark - Helpers


- (id)jsonResponse:(NSData *)data {
  NSError *error = nil;
  id res = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  NSAssert((error == nil), @"error must be nil but is: %@", error);
  return res;
}


- (void)handleLoginResponse:(id)response {
  // Example response:
  // {"is_banned": false, "status": 0, "rate": 0.139, "balance": 668.173, "user": 50402}
  id user = [response objectForKey:@"user"];
  if (user != nil) {
    self.loggedIn = YES;
    if ([self.delegate respondsToSelector:@selector(didLogInAs:)]) {
      [self.delegate didLogInAs:user];
    }
  }
}


- (void)handleUploadResponse:(id)response {
  // Example response:
  // {"status": 0, "captcha": 231930898, "is_correct": true, "text": "037233"}
  // (NB: "text" is typically null or "" and is only filled in if the image has been
  // seen and decoded before by the server
  NSNumber *captchaId = [response objectForKey:@"captcha"];
  if (captchaId == nil) {
    NSLog(@"Warning: upload response without captcha id!");
  }
  
  if ([self.delegate respondsToSelector:@selector(didUploadImageId:captchaId:)]) {
    [self.delegate didUploadImageId:self.imageId captchaId:captchaId];
  }
  
  self.textResult = [response objectForKey:@"text"];
  if (self.textResult != nil && ! [self.textResult isEqualToString:@""]) {
    if ([self.delegate respondsToSelector:@selector(didDecodeImageId:captchaId:result:)]) {
      [self.delegate didDecodeImageId:self.imageId captchaId:captchaId result:self.textResult];
    }
  }
}


- (void)handleCaptchaResponse:(id)response {
  // Example response:
  // {"status": 0, "captcha": 232316060, "is_correct": true, "text": "037233"}
  NSNumber *captchaId = [response objectForKey:@"captcha"];
  if (captchaId == nil) {
    NSLog(@"Warning: captcha response without captcha id!");
  }

  self.textResult = [response objectForKey:@"text"];
  if (self.textResult != nil && ! [self.textResult isEqualToString:@""]) {
    if ([self.delegate respondsToSelector:@selector(didDecodeImageId:captchaId:result:)]) {
      [self.delegate didDecodeImageId:self.imageId captchaId:captchaId result:self.textResult];
    }
  }
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
        
        NSMutableData *data = nil;
        uint8_t buffer[1024];
        int len;
        
        while ([self.inputStream hasBytesAvailable]) {
          len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
          if (len > 0) {
            NSData *newData = [NSData dataWithBytes:buffer length:len];
            if (data != nil) {
              [data appendData:newData];
            } else {
              data = [NSMutableData dataWithData:newData];
            }
          }

        }
        
        NSString *currentCommand = nil;
        @synchronized(self.commandQueue) {
          if ([self.commandQueue count] > 0) {
            currentCommand = [self.commandQueue objectAtIndex:0];
            [self.commandQueue removeObjectAtIndex:0];
          }
        }
        
        if (data != nil) {
          NSLog(@"current command: %@", currentCommand);
          NSLog(@"server said: %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
          id response = [self jsonResponse:data];
          if ([currentCommand isEqualToString:kLoginCommand]) {
            [self handleLoginResponse:response];
          } else if ([currentCommand isEqualToString:kUploadCommand]) {
            [self handleUploadResponse:response];
          } else if ([currentCommand isEqualToString:kCaptchaCommand]) {
            [self handleCaptchaResponse:response];
          }
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
      if ([self.commandQueue count] > 0) {
        NSLog(@"Error: Stream closed while commands are active!");
      } else {
        NSLog(@"Stream end event");
      }
			break;
      
    default:
			NSLog(@"Unknown event: %@", streamEvent);
	}
}


@end
