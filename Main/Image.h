//
//  Image.h
//  Graf
//
//  Created by Sven A. Schmidt on 25.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum ImageState {
  kIdle,
  kProcessing,
  kTimeout
} ImageState;


@interface Image : NSObject


@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, assign) ImageState state;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, assign) NSTimeInterval processingTime;
@property (nonatomic, copy) NSString *textResult;


- (void)transitionTo:(ImageState)newState;
- (NSTimeInterval)elapsed;

@end