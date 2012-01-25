//
//  Image.h
//  Graf
//
//  Created by Sven A. Schmidt on 25.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Image : NSObject

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;

@end
