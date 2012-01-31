#import <GHUnitIOS/GHUnit.h> 
#import "ImageProcessor.h"


@interface ImageProcessorTest : GHAsyncTestCase<ImageProcessorDelegate> { }

@property (nonatomic, copy) NSString *textResult;

@end



@implementation ImageProcessorTest

@synthesize textResult = _textResult;


- (void)setUp {
  [super setUp];
  self.textResult = nil;
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


- (void)test_01_queue {
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);

  ImageProcessor *ip = [[ImageProcessor alloc] init];
  ip.delegate = self;
  [ip upload:image];
  
  [self prepare];
  [self checkProgress:^BOOL{
    return [ip.queue operationCount] == 1;
  }];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:2];
  
  [self prepare];
  [self checkProgress:^BOOL{
    return [ip.queue operationCount] == 0;
  }];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:30];
  
  GHAssertEqualStrings(@"037233", self.textResult, nil);
}


- (void)test_02_result {
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);
  
  [self prepare];

  ImageProcessor *ip = [[ImageProcessor alloc] init];
  ip.delegate = self;
  [ip upload:image];
  
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:60];
  
  GHAssertEqualStrings(@"037233", self.textResult, nil);
}


#pragma mark ImageProcessorDelegate


- (void)didDecodeImageId:(NSString *)imageId captchaId:(NSNumber *)captchaId result:(NSString *)result
{
  self.textResult = result;
  [self notify:kGHUnitWaitStatusSuccess];
}


- (void)didTimeoutDecodingImageId:(NSString *)imageId {
  [self notify:kGHUnitWaitStatusFailure];
}


@end