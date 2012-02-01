#import <GHUnitIOS/GHUnit.h> 
#import "ImageProcessor.h"


@interface ImageProcessorTest : GHAsyncTestCase<ImageProcessorDelegate> { }

@property (nonatomic, copy) NSString *textResult;
@property (nonatomic, retain) NSNumber *rate;
@property (nonatomic, retain) NSNumber *balance;

@end



@implementation ImageProcessorTest

@synthesize textResult = _textResult;
@synthesize rate = _rate;
@synthesize balance = _balance;


- (void)setUp {
  [super setUp];
  self.textResult = nil;
  self.rate = nil;
  self.balance = nil;
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


- (void)test_01_upload {
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);

  ImageProcessor *ip = [[ImageProcessor alloc] init];
  ip.delegate = self;
  [ip upload:image];
  
  [self prepare];
  [self checkProgress:^BOOL{
    return [ip.queue count] == 1;
  }];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:2];
  
  [self prepare];
  [self checkProgress:^BOOL{
    return [ip.queue count] == 0;
  }];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:30];
  
  GHAssertEqualStrings(self.textResult, @"037233", nil);
}


- (void)test_02_balance {
  ImageProcessor *ip = [[ImageProcessor alloc] init];
  ip.delegate = self;
  
  [self prepare];
  [ip refreshBalance];
  
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  
  GHAssertNotNil(self.rate, nil);
  GHAssertNotNil(self.balance, nil);
}


#pragma mark ImageProcessorDelegate


- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result
{
  self.textResult = result;
  [self notify:kGHUnitWaitStatusSuccess];
}


- (void)didTimeoutDecodingImageId:(NSString *)imageId {
  [self notify:kGHUnitWaitStatusFailure];
}


- (void)didRefreshBalance:(NSNumber *)balance rate:(NSNumber *)rate {
  self.rate = rate;
  self.balance = balance;
  [self notify:kGHUnitWaitStatusSuccess];
}



@end