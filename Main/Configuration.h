//
//  Configuration.h
//  Graf
//
//  Created by Sven A. Schmidt on 08.03.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Configuration : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *hostname;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (assign) NSInteger port;
@property (nonatomic, copy) NSString *protocol;
@property (nonatomic, copy) NSString *realm;
@property (nonatomic, copy) NSString *dbname;
@property (nonatomic, copy) NSString *localDbname;

- (NSString *)remoteUrl;

@end
