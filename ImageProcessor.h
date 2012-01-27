//
//  ImageProcessor.h
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ImageProcessorDelegate <NSObject>

@optional

- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result;
- (void)didTimeoutDecodingImageId:(NSString *)imageId;

@end



@interface ImageProcessor : NSObject

- (NSString *)upload:(UIImage *)image;
- (void)pollForImageId:(NSString *)imageId;


@end
