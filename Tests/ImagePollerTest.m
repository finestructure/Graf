#import <GHUnitIOS/GHUnit.h> 
#import "ImagePoller.h"
#import "DbcConnector.h"

@interface ImagePollerTest : GHAsyncTestCase<DbcConnectorDelegate> { }

@property (nonatomic, retain) DbcConnector *dbc;
@property (nonatomic, copy) NSString *captchaId;
@property (nonatomic, copy) NSString *result;

@end


@implementation ImagePollerTest


@synthesize dbc = _dbc;
@synthesize captchaId = _captchaId;
@synthesize result = _result;



- (void)setUp {
  [super setUp];  
  self.dbc = [[DbcConnector alloc] init];
  self.dbc.delegate = self;
  self.captchaId = nil;
  self.result = nil;
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


- (void)test_01_poll {
  [self.dbc connect];
  [self.dbc login];
  
  [self prepare];

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  [self.dbc upload:image];

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  GHAssertNotNil(self.captchaId, nil);

  [self prepare];
  
  ImagePoller *poller = [[ImagePoller alloc] initWithInterval:5 
                                                      timeout:50 
                                                    captchaId:self.captchaId 
                                                          dbc:self.dbc 
                                            completionHandler:^{
                                              [self notify:kGHUnitWaitStatusSuccess];
                                            } 
                                               timeoutHandler:^{
                                                 [self notify:kGHUnitWaitStatusFailure];
                                               }];
  [poller start];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:60];

  GHAssertEqualStrings(@"037233", self.result, nil);
}


#pragma mark - delegate


- (void)didUploadImageId:(NSString *)imageId captchaId:(NSString *)captchaId {
  self.captchaId = captchaId;
	[self notify:kGHUnitWaitStatusSuccess];
}


- (void)didDecodeImageId:(NSString *)imageId captchaId:(NSString *)captchaId result:(NSString *)result {
  self.result = result;
  [self notify:kGHUnitWaitStatusSuccess];
}


- (void)didTimeoutDecodingImageId:(NSString *)imageId {
  [self notify:kGHUnitWaitStatusFailure];
}


@end