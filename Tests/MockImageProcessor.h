//
//  MockImageProcessor.h
//  Graf
//
//  Created by Sven A. Schmidt on 02.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageProcessor.h"

@interface MockImageProcessor : ImageProcessor

- (void)upload:(UIImage *)image;
- (void)refreshBalance;

@end
