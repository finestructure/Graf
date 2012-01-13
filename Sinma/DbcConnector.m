//
//  DbcConnector.m
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "DbcConnector.h"


#warning TEMPORARY
const NSString *kUser = @"abstracture";
const NSString *kPass = @"i8Kn37rD8v";
const NSString *kHostname = @"api.deathbycaptcha.com";
const int kPort = 8123; // to 8131


@implementation DbcConnector

@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}


- (void)dealloc {
  
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

  return YES;
}


#pragma mark - NSStreamDelegate


- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
  NSLog(@"stream event %i", streamEvent);
	switch (streamEvent) {
      
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
      
		case NSStreamEventHasBytesAvailable:
			break;			
      
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
      
		case NSStreamEventEndEncountered:
			break;
      
		default:
			NSLog(@"Unknown event");
	}
}


@end
