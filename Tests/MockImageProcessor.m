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
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
    if ([self.delegate respondsToSelector:@selector(didDecodeImageId:result:)]) {
      [self.delegate didDecodeImageId:imageId result:imageId];
    }
  });
}


- (void)refreshBalance {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
    if ([self.delegate respondsToSelector:@selector(didRefreshBalance:rate:)]) {
      [self.delegate didRefreshBalance:[NSNumber numberWithInt:100] rate:[NSNumber numberWithInt:1]];
    }
  });
}


@end
