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


NSString * const kUser = @"abstracture";
NSString * const kPass = @"i8Kn37rD8v";
NSString * const kHostname = @"api.deathbycaptcha.com";
const int kPortStart = 8123;
const int kPortEnd = 8130;

// valid commands
NSString * const kLoginCommand = @"login";
NSString * const kUploadCommand = @"upload";
NSString * const kUserCommand = @"user";
NSString * const kCaptchaCommand = @"captcha";


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
    [self.delegate didConnectToHost:kHostname port:port];
  }
}


- (void)disconnect {
  [self.inputStream close];
  [self.outputStream close];
  [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [self.inputStream setDelegate:nil];
  [self.outputStream setDelegate:nil];
  self.inputStream = nil;
  self.outputStream = nil;
}


- (void)login {
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        kUser, @"username",
                        kPass, @"password",
                        nil];
  [self call:kLoginCommand withData:dict];
}


- (void)refreshBalance {
  [self call:kUserCommand];  
}


- (NSString *)upload:(UIImage *)image {
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *base64Data = [imageData base64EncodedString];
  self.imageId = [imageData MD5];
  NSDictionary *data = [NSDictionary dictionaryWithObject:base64Data forKey:@"captcha"];
  [self call:kUploadCommand withData:data];
  return self.imageId;
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
    if (written == -1) {
      NSError *error = [self.outputStream streamError];
      NSLog(@"Error while writing data: %d %@", [error code], [error localizedDescription]);
      return;
    }
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


- (void)handleUserResponse:(id)response {
  // Example response:
  // {"is_banned": false, "status": 0, "rate": 0.139, "balance": 668.173, "user": 50402}
  NSNumber *rate = [response objectForKey:@"rate"];
  NSNumber *balance = [response objectForKey:@"balance"];
  if (rate != nil && balance != nil) {
    if ([self.delegate respondsToSelector:@selector(didRefreshBalance:rate:)]) {
      [self.delegate didRefreshBalance:balance rate:rate];
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


- (NSArray *)jsonResponses:(NSData *)data {
  NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  NSArray *components = [string componentsSeparatedByString:@"}"];
  NSMutableArray *results = [NSMutableArray array];
  for (NSString *comp in components) {
    if (! [comp isEqualToString:@""]) {
      NSString *jsonString = [NSString stringWithFormat:@"%@}", comp];
      id jsonObject = [self jsonResponse:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
      [results addObject:jsonObject];
    }
  }
  return results;
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
        NSInteger len;
        
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
          NSArray *responses = [self jsonResponses:data];
          for (id response in responses) {
            if (currentCommand == kLoginCommand) {
              [self handleLoginResponse:response];
            } else if (currentCommand == kUserCommand) {
              [self handleUserResponse:response];
            } else if (currentCommand == kUploadCommand) {
              [self handleUploadResponse:response];
            } else if (currentCommand == kCaptchaCommand) {
              [self handleCaptchaResponse:response];
            }
          }
        }
      }
      break;
      
    case NSStreamEventHasSpaceAvailable:
      NSLog(@"Has space available");
      break;
      
		case NSStreamEventErrorOccurred: {
			NSLog(@"Error");
      NSLog(@"Stream status: %d", [self.inputStream streamStatus]);
      NSError *error = [self.inputStream streamError];
      if (error != nil) {
        NSLog(@"Error info: %d %@", [error code], [error localizedDescription]);
      }
    }
			break;
      
		case NSStreamEventEndEncountered: {
      NSLog(@"Stream end event");
      if ([self.commandQueue count] > 0) {
        NSLog(@"Error: Stream closed while commands are active!");
        NSLog(@"Stream status: %d", [self.inputStream streamStatus]);
        NSError *error = [self.inputStream streamError];
        if (error != nil) {
          NSLog(@"Error info: %d %@", [error code], [error localizedDescription]);
        }
        if ([self.delegate respondsToSelector:@selector(didDisconnectWithError:)]) {
          NSError *error = [NSError errorWithDomain:@"DbcConnector" code:1 userInfo:nil];
          [self.delegate didDisconnectWithError:error];
        }
      } else {
        // we don't really care about error state if the command queue is empty, i.e. all
        // responses that we expected have been handled
        // just report that the stream is closed
        if ([self.delegate respondsToSelector:@selector(didDisconnect)]) {
          [self.delegate didDisconnect];
        }
      }
    }
			break;
      
    default: {
			NSLog(@"Unknown event: %@", streamEvent);
      NSLog(@"Stream status: %d", [self.inputStream streamStatus]);
      NSError *error = [self.inputStream streamError];
      if (error != nil) {
        NSLog(@"Error info: %d %@", [error code], [error localizedDescription]);
      }
    }
	}
}


@end
