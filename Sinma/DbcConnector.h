//
//  DbcConnector.h
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


// delegate protocal

@protocol DbcConnectorDelegate <NSObject>

@optional

- (void)didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)didLogInAs:(NSString *)user;
- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result;

@end


// class declaration

@interface DbcConnector : NSObject <NSStreamDelegate> {
  dispatch_queue_t requestQueue;
}

@property (nonatomic, assign) id<DbcConnectorDelegate> delegate;

@property (nonatomic, retain) GCDAsyncSocket *socket;
@property (assign) BOOL connected;
@property (assign) BOOL loggedIn;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, retain) NSString *response;
@property (nonatomic, retain) NSDictionary *user;
@property (nonatomic, retain) NSMutableDictionary *decoded;
@property (nonatomic, retain) NSMutableArray *uploadQueue;
@property (nonatomic, retain) NSMutableArray *captchaQueue;

// internal

- (BOOL)connect;
- (void)login;
- (void)call:(NSString *)command tag:(long)tag;
- (void)call:(NSString *)command withData:(NSDictionary *)data tag:(long)tag;

// API
  
- (float)balance;
- (NSString *)upload:(UIImage *)image;
- (void)poll:(NSString *)imageId;


@end

