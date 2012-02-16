//
//  Constants.h
//  Sinma
//
//  Created by Sven A. Schmidt on 10.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kImageScaleDefault;
extern NSString * const kNumbersOnlyDefault;
extern NSString * const kPageModeDefault;


@interface Constants : NSObject

@property (readonly) NSString *version;

+ (Constants *)sharedInstance;

@end

