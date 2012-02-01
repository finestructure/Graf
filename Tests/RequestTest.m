#import <GHUnitIOS/GHUnit.h> 
#import "UploadRequest.h"
#import "BalanceRequest.h"


@interface RequestTest : GHAsyncTestCase { }

@end


@implementation RequestTest


#pragma mark - tests


- (void)test_01_worker {
  [self prepare];
  
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  UploadRequest *worker = [[UploadRequest alloc] initWithImage:image];
 
  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  
  [worker start];

  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
  [worker removeObserver:self forKeyPath:@"isFinished"];

  GHAssertEqualStrings(worker.textResult, @"037233", nil);
}


- (void)test_02_balance {
  [self prepare];
  
  BalanceRequest *request = [[BalanceRequest alloc] init];
  [request addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  [request start];
  
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  [request removeObserver:self forKeyPath:@"isFinished"];
  
  GHAssertNotNil(request.rate, nil);
  GHAssertNotNil(request.balance, nil);
}


#pragma mark KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  NSLog(@"KVO: %@ %@ %@", keyPath, object, change);
  if ([keyPath isEqualToString:@"isFinished"]) {
    [self notify:kGHUnitWaitStatusSuccess];
  }
}


@end