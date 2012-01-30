//
//  DbcConnector.h
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImagePoller.h"


// delegate protocol

@protocol DbcConnectorDelegate <NSObject>

@optional

- (void)didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)didLogInAs:(NSString *)user;
- (void)didDecodeImageId:(NSString *)imageId captchaId:(NSString *)captchaId result:(NSString *)result;
- (void)didUploadImageId:(NSString *)imageId captchaId:(NSString *)captchaId;
- (void)didDisconnectWithError:(NSError *)error;
- (void)didUpdateBalance:(float)newBalance;

@end


@interface DbcConnector : NSObject <NSStreamDelegate>

@property (nonatomic, assign) id<DbcConnectorDelegate> delegate;

@property (assign) BOOL connected;
@property (assign) BOOL loggedIn;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic, retain) ImagePoller *imagePoller;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, copy) NSString *textResult;
@property (nonatomic, copy) NSString *currentCommand;


// internal

- (void)call:(NSString *)command;
- (void)call:(NSString *)command withData:(NSDictionary *)data;
- (void)pollWithInterval:(NSTimeInterval)interval 
                 timeout:(NSTimeInterval)timeout 
               captchaId:(NSString *)imageId 
       completionHandler:(void (^)())completionHandler
          timeoutHandler:(void (^)())timeoutHandler;

// API

- (void)connect;
- (void)login;
- (void)updateBalance;
- (void)upload:(UIImage *)image;
- (void)pollWithCaptchaId:(NSString *)captchaId;

@end

