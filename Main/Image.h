//
//  Image.h
//  Graf
//
//  Created by Sven A. Schmidt on 14.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>

@interface Image : CouchModel {
  NSString *_imageHash;
}

@property (retain) UIImage *image;
@property (copy) NSString *image_id;
@property (copy) NSString *state;
@property (retain) NSDate *created_at;
@property (copy) NSString *text_result;
@property (retain) NSNumber *processing_time;
@property (copy) NSString *owner;
@property (copy) NSString *version;

- (id)initWithImage:(UIImage *)image inDatabase:(CouchDatabase *)database;

@end
