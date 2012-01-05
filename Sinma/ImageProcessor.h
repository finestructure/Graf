//
//  ImageProcessor.h
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>


@interface ImageProcessor : NSObject
{
}


@property (nonatomic, retain) NSString *dataPath;

- (void)setTesseractImage:(UIImage *)image;
- (NSString *)processImage:(UIImage *)image;
- (NSString *)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end
