//
//  Constants.h
//  Sinma
//
//  Created by Sven A. Schmidt on 10.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kUuidDefaultsKey;
extern NSString * const kConfigurationDefaultsKey;

@class Configuration;

@interface Constants : NSObject

@property (readonly) NSString *version;

+ (Constants *)sharedInstance;

- (NSString *)deviceUuid;
- (NSArray *)configurations;
- (Configuration *)defaultConfiguration;
- (Configuration *)currentConfiguration;

@end

