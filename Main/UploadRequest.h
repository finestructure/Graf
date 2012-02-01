//
//  Worker.h
//  Graf
//
//  Created by Sven A. Schmidt on 27.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRequest.h"


@interface UploadRequest : BaseRequest<DbcConnectorDelegate>

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, retain) NSNumber *captchaId;
@property (nonatomic, copy) NSString *textResult;


- (id)initWithImage:(UIImage *)image;

@end
