//
//  Image.h
//  Graf
//
//  Created by Sven A. Schmidt on 14.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>


extern NSString * const kImageStateNew;
extern NSString * const kImageStateIdle;
extern NSString * const kImageStateProcessing;
extern NSString * const kImageStateTimeout;


@interface Image : CouchModel {
  NSString *_imageHash;
}

@property (retain) UIImage *image;
@property (copy) NSString *image_id;
@property (copy) NSString *state;
@property (retain) NSDate *created_at;
@property (copy) NSString *text_result;
@property (retain) NSNumber *processing_time;
@property (copy) NSString *source_device;
@property (copy) NSString *version;
@property (copy) NSString *processed;

- (id)initWithImage:(UIImage *)image inDatabase:(CouchDatabase *)database;

@end
