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
  kProcessing
} ImageState;


@interface Image : NSObject


@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, assign) ImageState state;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, assign) NSTimeInterval processingTime;


- (void)transitionTo:(ImageState)newState;

@end
