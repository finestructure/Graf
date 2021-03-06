//
//  Image.m
//  Graf
//
//  Created by Sven A. Schmidt on 14.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "Image.h"
#import "NSData+MD5.h"
#import "Constants.h"


NSString * const kImageStateNew = @"new";
NSString * const kImageStateIdle = @"idle";
NSString * const kImageStateProcessing = @"processing";
NSString * const kImageStateTimeout = @"timeout";

NSString * const kImageAttachmentKey = @"snapshot.png";


@implementation Image

@dynamic image_id;
@dynamic state;
@dynamic created_at;
@dynamic text_result;
@dynamic processing_time;
@dynamic source_device;
@dynamic version;
@dynamic processed;


- (id)initWithImage:(UIImage *)image inDatabase:(CouchDatabase *)database
{
  self = [super init];
  if (self) {
    // set image hash first, because it's the doc id needed by doc creation
    // (which is triggered by the database setter below)
    _imageHash = [UIImagePNGRepresentation(image) MD5];
    self.database = database;
    self.image = image;
    self.image_id = _imageHash;
    self.created_at = [NSDate date];
    self.source_device = [[Constants sharedInstance] deviceUuid];
    self.version = [[Constants sharedInstance] version];
    self.text_result = @"";
    self.state = kImageStateNew;
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
    [self createAttachmentWithName:kImageAttachmentKey type:@"image/png" body:data];
  }
}


- (NSString*)idForNewDocumentInDatabase:(CouchDatabase *)db	{
  return _imageHash;
}


@end
