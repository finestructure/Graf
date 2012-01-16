//
//  DbcConnector.h
//  Sinma
//
//  Created by Sven A. Schmidt on 13.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


@interface DbcConnector : NSObject <NSStreamDelegate> {
  dispatch_queue_t requestQueue;
}

@property (nonatomic, retain) GCDAsyncSocket *socket;
@property (assign) BOOL connected;
@property (assign) BOOL loggedIn;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, retain) NSString *response;

+ (DbcConnector *)sharedInstance;

- (BOOL)connect;
- (void)login;
- (id)call:(NSString *)command;
- (id)call:(NSString *)command withData:(NSDictionary *)data;

- (float)balance;
- (NSUInteger)upload:(UIImage *)image;
- (NSString *)decode:(UIImage *)image;

@end

