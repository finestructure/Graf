#import <GHUnitIOS/GHUnit.h> 
#import "DbcConnector.h"

@interface DbcConnectorTest : GHAsyncTestCase<DbcConnectorDelegate> { }

@property (nonatomic, retain) DbcConnector *dbc;
@property (nonatomic, copy) void (^didDecodeDelegateHandler)(NSString *imageId, NSString *result);

@end


@implementation DbcConnectorTest

@synthesize dbc = _dbc;
@synthesize didDecodeDelegateHandler = _didDecodeDelegateHandler;


const NSInteger kCheckProgressStatus = 1000;


- (void)setUp {
  [super setUp];  
  self.dbc = [[DbcConnector alloc] init];
  self.dbc.delegate = self;
  self.didDecodeDelegateHandler = nil;
}


- (void)tearDown {
  [super tearDown];
}


- (void)checkProgress:(BOOL (^)())hasResult {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
    if (hasResult() == YES) {
      [self notify:kCheckProgressStatus];
    } else {
      [self checkProgress:hasResult];
    }
  });
}


#pragma mark - tests


- (void)test_01_connect {
	[self prepare];
  
	[self.dbc connect];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  GHAssertTrue(self.dbc.connected, nil);
}


- (void)test_02_login {
  [self.dbc connect];
  [self prepare];
  
  [self.dbc login];

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  GHAssertTrue(self.dbc.loggedIn, nil);
  GHAssertEqualStrings(@"50402", [[self.dbc.user objectForKey:@"user"] stringValue], nil);
  GHAssertTrue(self.dbc.balance > 0, nil);
}


- (void)test_03_upload {
  [self.dbc connect];
  [self.dbc login];
  [self prepare];

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);
  
  NSString *imageId = [self.dbc upload:image];
  GHAssertNotNil(imageId, @"imageId must not be nil", nil);
  
  self.didDecodeDelegateHandler = ^(NSString *imageId, NSString *result){
  };
  
  [self checkProgress:^BOOL{
    return [[self.dbc.decoded objectForKey:imageId] objectForKey:@"captcha"] != nil
    && [self.dbc.uploadQueue count] == 0;
  }];
  [self waitForStatus:kCheckProgressStatus timeout:20]; 
  
  GHAssertTrue([self.dbc.uploadQueue count] == 0, @"upload queue size must be 0", nil);
  NSDictionary *result = [self.dbc.decoded objectForKey:imageId];
  GHAssertNotNil(result, @"result must not be nil", nil);
  id captcha = [result objectForKey:@"captcha"];
  GHAssertNotNil(captcha, @"captcha must not be nil", nil);
}


- (void)test_04_decoded {
  [self.dbc connect];
  [self.dbc login];
  [self prepare];

  __block NSString *imageId = nil;
  __block NSString *textResult = nil;
  __block typeof(self) bself = self;
  self.didDecodeDelegateHandler = ^(NSString *anImageId, NSString *result){
    imageId = anImageId;
    textResult = result;
    [bself notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_04_decoded)];
  };

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  NSString *actualImageId = [self.dbc upload:image];  
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:40];
  
  GHAssertEqualStrings(actualImageId, imageId, nil);
  GHAssertEqualStrings(@"037233", textResult, nil);
  GHAssertEqualStrings(@"037233", [self.dbc resultForId:imageId], nil);
}


- (void)test_05_poll {
  [self.dbc connect];
  [self.dbc login];
  [self prepare];
  
  __block NSString *imageId = nil;
  __block NSString *textResult = nil;
  __block typeof(self) bself = self;
  self.didDecodeDelegateHandler = ^(NSString *anImageId, NSString *result){
    imageId = anImageId;
    textResult = result;
    [bself notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_05_poll)];
  };

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  NSString *actualImageId = [self.dbc upload:image];

  [self.dbc poll:imageId];
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:40];
  
  GHAssertEqualStrings(actualImageId, imageId, nil);
  GHAssertEqualStrings(@"037233", textResult, nil);
}


#pragma mark - delegate


- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
	[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_01_connect)];
}


- (void)didLogInAs:(NSString *)user {
  [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_02_login)];
}


- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result {
  self.didDecodeDelegateHandler(imageId, result);
}


@end