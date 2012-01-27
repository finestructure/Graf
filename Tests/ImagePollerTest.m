#import <GHUnitIOS/GHUnit.h> 
#import "ImagePoller.h"
#import "DbcConnector.h"

@interface ImagePollerTest : GHAsyncTestCase<DbcConnectorDelegate> { }

@property (nonatomic, retain) DbcConnector *dbc;

@end


@implementation ImagePollerTest


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


- (void)test_01_poll {
  [self.dbc connect];
  [self.dbc login];
  
  [self prepare];

  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  NSString *imageId = [self.dbc upload:image];

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];

  [self prepare];
  
  ImagePoller *poller = [[ImagePoller alloc] initWithInterval:5 
                                                      timeout:50 
                                                      imageId:imageId 
                                                          dbc:self.dbc 
                                            completionHandler:^{
                                              [self notify:kGHUnitWaitStatusSuccess];
                                            } 
                                               timeoutHandler:^{
                                                 [self notify:kGHUnitWaitStatusFailure];
                                               }];
  [poller start];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:60];

  GHAssertEqualStrings(@"037233", [self.dbc resultForId:imageId], nil);
}


#pragma mark - delegate


- (void)didUploadImageId:(NSString *)imageId {
	[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_01_poll)];
}


@end