//
//  ImageProcessor.h
//  Sinma
//
//  Created by Sven A. Schmidt on 12.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DbcConnector;

@interface ImageProcessor : NSObject

@property (nonatomic, retain) DbcConnector *dbc;

- (NSString *)processImage:(UIImage *)image;
- (float)balance;

@end
