//
//  DbcConnector.h
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DbcConnectorDelegate<NSObject>

@optional
- (void)errorOccurred:(NSError *)error;
- (void)responseReceived:(NSString *)response;

@end



@interface DbcConnector : NSObject <NSStreamDelegate>

@property (nonatomic, assign) id<DbcConnectorDelegate> delegate;

@property (assign) BOOL connected;
@property (assign) BOOL loggedIn;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;

- (BOOL)connect;
- (void)login;
- (void)call:(NSString *)command;
- (void)call:(NSString *)command withData:(NSDictionary *)data;

@end

