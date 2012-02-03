//
//  MockImageProcessor.m
//  Graf
//
//  Created by Sven A. Schmidt on 02.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "MockImageProcessor.h"
#import "NSData+MD5.h"

@implementation MockImageProcessor

- (void)upload:(UIImage *)image {  
  NSData *imageData = UIImagePNGRepresentation(image);
  NSString *imageId = [imageData MD5];
  
  int time = 2 + arc4random() % 6; // 2-7 seconds run time
  BOOL timeout = (arc4random() % 2) == 0; // 50% timeout chance
  
  if (! timeout ) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
      if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
        [self.delegate didDecodeImageId:imageId result:imageId];
      }
    });
  } else {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
      if ([self.delegate respondsToSelector:@selector(didTimeoutDecodingImageId:)]) {
        [self.delegate didTimeoutDecodingImageId:imageId];
      }
    });
  }
}


- (void)refreshBalance {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
    if ([self.delegate respondsToSelector:@selector(didRefreshBalance:rate:)]) {
      [self.delegate didRefreshBalance:[NSNumber numberWithInt:100] rate:[NSNumber numberWithInt:1]];
    }
  });
}


@end
