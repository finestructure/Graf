//
//  BalanceRequest.h
//  Graf
//
//  Created by Sven A. Schmidt on 01.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseRequest.h"


@interface BalanceRequest : BaseRequest

@property (nonatomic, retain) NSNumber *rate;
@property (nonatomic, retain) NSNumber *balance;

@end
