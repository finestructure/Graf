//
//  Constants.m
//  Sinma
//
//  Created by Sven A. Schmidt on 10.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Constants.h"

#import "Configuration.h"

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


- (NSArray *)configurations {
  static NSMutableArray *configurations = nil;
  if (configurations != nil) {
    return configurations;
  }
  @synchronized(self) {
    if (configurations == nil) {
      configurations = [NSMutableArray array];
      {
        Configuration *c = [[Configuration alloc] init];
        c.name = @"Production";
        c.hostname = @"graf.abstracture.de";
        c.username = @"graf";
        c.password = @"BaumHinkelstein";
        c.port = 443;
        c.protocol = @"https";
        c.realm = @"Graf";
        c.dbname = @"graf";
        c.localDbname = c.dbname;
        [configurations addObject:c];
      }
      {
        Configuration *c = [[Configuration alloc] init];
        c.name = @"Test";
        c.hostname = @"graf.abstracture.de";
        c.username = @"graf";
        c.password = @"BaumHinkelstein";
        c.port = 443;
        c.protocol = @"https";
        c.realm = @"Graf";
        c.dbname = @"graf_test";
        c.localDbname = c.dbname;
        [configurations addObject:c];
      }
    }
  }
  return configurations;
}


@end

