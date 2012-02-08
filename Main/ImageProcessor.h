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
- (void)didRefreshBalance:(NSNumber *)balance rate:(NSNumber *)rate;
- (void)didReceiveError:(NSError *)error;

@end



@interface ImageProcessor : NSObject


@property (nonatomic, weak) id<ImageProcessorDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *queue;


- (void)upload:(UIImage *)image;
- (void)refreshBalance;


@end
