//
//  Image.m
//  Graf
//
//  Created by Sven A. Schmidt on 14.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Image.h"
#import "NSData+MD5.h"


NSString * const kImageAttachmentKey = @"snapshot.png";


@implementation Image

@dynamic imageId, state, created_at, text_result, processing_time, owner;


- (id)initWithImage:(UIImage *)image inDatabase:(CouchDatabase *)database
{
  self = [super initWithNewDocumentInDatabase:database];
  if (self) {
    self.image = image;
    self.created_at = [NSDate date];
  }
  return self;
}


- (UIImage*)image {
  CouchAttachment* a = [self attachmentNamed:kImageAttachmentKey];
  if (!a) {
    return nil;
  }
  return [[UIImage alloc] initWithData: a.body];
}


- (void)setImage:(UIImage*)image {
  if (! image) {
    [self removeAttachmentNamed:kImageAttachmentKey];
  } else {
    NSData* data = UIImagePNGRepresentation(image);
    self.imageId = [data MD5];
    [self createAttachmentWithName:kImageAttachmentKey type:@"image/png" body:data];
  }
}


- (NSString*)idForNewDocumentInDatabase:(CouchDatabase *)db	{
  return self.imageId;
}


@end
