//
//  Constants.m
//  Sinma
//
//  Created by Sven A. Schmidt on 10.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Constants.h"

NSString * const kImageScaleDefault = @"ImageScale";
NSString * const kNumbersOnlyDefault = @"NumbersOnly";
NSString * const kPageModeDefault = @"PageMode";


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


@end

