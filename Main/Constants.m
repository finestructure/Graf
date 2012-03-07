//
//  Constants.m
//  Sinma
//
//  Created by Sven A. Schmidt on 10.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Constants.h"

NSString * const kUuidDefaultsKey = @"UuidDefaultsKey";


@implementation Constants


+ (Constants *)sharedInstance {
  static Constants *sharedInstance = nil;
  
  if (sharedInstance) {
    return sharedInstance;
  }
  
  @synchronized(self) {
    if (! sharedInstance) {
      sharedInstance = [[Constants alloc] init];
    }
    
    return sharedInstance;
  }
}


- (NSString *)version {
  static NSString *version = nil;
  
  if (version) {
    return version;
  }
  
  @synchronized(self) {
    if (! version) {
      version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    }
  }
  
  return version;
}


- (NSString *)deviceUuid {
  static NSString *uuid = nil;
  
  if (uuid != nil) {
    return uuid;
  }
  
  @synchronized(self) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id res = [defaults objectForKey:kUuidDefaultsKey];
    if (res != nil) {
      uuid = res;
    } else {
      CFUUIDRef _uuid;
      CFStringRef _uuidStr;
      _uuid = CFUUIDCreate(NULL);
      _uuidStr = CFUUIDCreateString(NULL, _uuid);
      uuid = (__bridge_transfer NSString *)_uuidStr;
      CFRelease(_uuid);
      [defaults setObject:uuid forKey:kUuidDefaultsKey];
    }
  }
  
  return uuid;
}


- (NSArray *)servers {
  static NSArray *servers = nil;
  if (servers != nil) {
    return servers;
  }
  @synchronized(self) {
    if (servers == nil) {
      servers = [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:
                  @"Production",
                  @"name",
                  @"graf",
                  @"dbname", 
                  nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:
                  @"Test",
                  @"name",
                  @"graf_test",
                  @"dbname", 
                  nil],
                 nil];
    }
  }
  return servers;
}


@end

