#import <GHUnitIOS/GHUnit.h> 
#import "DbcConnector.h"

@interface DbcConnectorTest : GHAsyncTestCase<DbcConnectorDelegate> { }

@property (nonatomic, retain) DbcConnector *dbc;

@end


@implementation DbcConnectorTest

@synthesize dbc = _dbc;


- (void)setUp {
  [super setUp];  
  self.dbc = [[DbcConnector alloc] init];
  self.dbc.delegate = self;
}


- (void)tearDown {
  [super tearDown];
}


- (void)checkProgress:(BOOL (^)())hasResult {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
    if (hasResult() == YES) {
      [self notify:kGHUnitWaitStatusSuccess];
    } else {
      [self checkProgress:hasResult];
    }
  });
}


#pragma mark - tests


- (void)test_connect {
	[self prepare];
  
	[self.dbc connect];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:5];
  GHAssertTrue(self.dbc.connected, nil);
}


- (void)test_login {
  [self.dbc connect];
  [self prepare];
  
  [self.dbc login];

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:5];
  GHAssertTrue(self.dbc.loggedIn, nil);
  GHAssertEqualStrings(@"50402", [[self.dbc.user objectForKey:@"user"] stringValue], nil);
  GHAssertTrue(self.dbc.balance > 0, nil);
}


- (void)test_upload {
  [self.dbc connect];
  [self.dbc login];
  [self prepare];

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);
  
  NSString *imageId = [self.dbc upload:image];
  GHAssertNotNil(imageId, @"imageId must not be nil", nil);
  
  [self checkProgress:^BOOL{
    return [[self.dbc.decoded objectForKey:imageId] objectForKey:@"captcha"] != nil
    && [self.dbc.uploadQueue count] == 0;
  }];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:30]; 
  
  GHAssertTrue([self.dbc.uploadQueue count] == 0, @"upload queue size must be 0", nil);
  NSDictionary *result = [self.dbc.decoded objectForKey:imageId];
  GHAssertNotNil(result, @"result must not be nil", nil);
  id captcha = [result objectForKey:@"captcha"];
  GHAssertNotNil(captcha, @"captcha must not be nil", nil);
}


#pragma mark - delegate


- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
	[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_connect)];
}


- (void)didLogInAs:(NSString *)user {
  [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_login)];
}

@end