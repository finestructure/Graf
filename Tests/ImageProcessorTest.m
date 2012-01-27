#import <GHUnitIOS/GHUnit.h> 
#import "ImageProcessor.h"


@interface ImageProcessorTest : GHAsyncTestCase { }

@end



@implementation ImageProcessorTest


- (void)setUp {
  [super setUp];  
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


- (void)test_01 {
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  GHAssertNotNil(image, @"image must not be nil", nil);

  ImageProcessor *ip = [[ImageProcessor alloc] init];
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
}


@end