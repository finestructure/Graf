//
//  DbcConnector.h
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "ImagePoller.h"


// delegate protocal

@protocol DbcConnectorDelegate <NSObject>

@optional

- (void)didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)didLogInAs:(NSString *)user;
- (void)didDecodeImageId:(NSString *)imageId captchaId:(NSString *)captchaId result:(NSString *)result;
- (void)didUploadImageId:(NSString *)imageId captchaId:(NSString *)captchaId;
- (void)didDisconnectWithError:(NSError *)error;
- (void)didUpdateBalance:(float)newBalance;

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
@property (nonatomic, retain) ImagePoller *imagePoller;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, copy) NSString *textResult;

// internal

- (BOOL)connect;
- (void)login;
- (void)call:(NSString *)command tag:(long)tag;
- (void)call:(NSString *)command withData:(NSDictionary *)data tag:(long)tag;

// API
  
- (void)updateBalance;
- (void)upload:(UIImage *)image;
- (void)pollWithCaptchaId:(NSString *)captchaId;
- (void)pollWithInterval:(NSTimeInterval)interval 
                 timeout:(NSTimeInterval)timeout 
               captchaId:(NSString *)imageId 
       completionHandler:(void (^)())completionHandler
          timeoutHandler:(void (^)())timeoutHandler;


@end

