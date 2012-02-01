#import <GHUnitIOS/GHUnit.h> 
#import "UploadRequest.h"


@interface WorkerTest : GHAsyncTestCase { }

@end


@implementation WorkerTest


#pragma mark - tests


- (void)test_01_worker {
  [self prepare];
  
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  UploadRequest *worker = [[UploadRequest alloc] initWithImage:image];
 
  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  
  [worker start];

  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
  GHAssertEqualStrings(worker.textResult, @"037233", nil);
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