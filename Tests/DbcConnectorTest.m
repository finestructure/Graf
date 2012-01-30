#import <GHUnitIOS/GHUnit.h> 
#import "DbcConnector.h"

@interface DbcConnectorTest : GHAsyncTestCase<DbcConnectorDelegate> {
  BOOL connectNotification;
  BOOL loginNotification;
  BOOL uploadNotification;
  BOOL decodeNotification;
}

@property (nonatomic, retain) DbcConnector *dbc;
@property (nonatomic, copy) NSString *imageId;
@property (nonatomic, copy) NSNumber *captchaId;

@end


@implementation DbcConnectorTest

@synthesize dbc = _dbc;
@synthesize imageId = _imageId;
@synthesize captchaId = _captchaId;


const NSInteger kCheckProgressStatus = 1000;


- (void)setUp {
  [super setUp];  
  self.dbc = [[DbcConnector alloc] init];
  self.dbc.delegate = self;
  self.imageId = nil;
  self.captchaId = nil;
  connectNotification = NO;
  loginNotification = NO;
  uploadNotification = NO;
  decodeNotification = NO;
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
  connectNotification = YES;
	[self prepare];
  
	[self.dbc connect];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  GHAssertTrue(self.dbc.connected, nil);
}


- (void)test_02_login {
  loginNotification = YES;
  [self.dbc connect];
  [self prepare];
  
  [self.dbc login];

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  GHAssertTrue(self.dbc.loggedIn, nil);
}


- (void)test_03_upload {
  uploadNotification = YES;
  [self.dbc connect];
  [self.dbc login];

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);
  
  [self prepare];

  [self.dbc upload:image];
  
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20]; 
  GHAssertNotNil(self.imageId, nil);
  GHAssertNotNil(self.captchaId, nil);
}


#pragma mark - delegate


- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
  if (connectNotification)
    [self notify:kGHUnitWaitStatusSuccess];
}


- (void)didLogInAs:(NSString *)user {
  if (loginNotification)
    [self notify:kGHUnitWaitStatusSuccess];
}


- (void)didUploadImageId:(NSString *)imageId captchaId:(NSNumber *)captchaId {
  self.imageId = imageId;
  self.captchaId = captchaId;
  if (uploadNotification)
    [self notify:kGHUnitWaitStatusSuccess];
}


- (void)didDecodeImageId:(NSString *)imageId captchaId:(NSNumber *)captchaId result:(NSString *)result {
  if (decodeNotification)
    [self notify:kGHUnitWaitStatusSuccess];
}


@end