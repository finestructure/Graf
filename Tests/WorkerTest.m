#import <GHUnitIOS/GHUnit.h> 
#import "Worker.h"


@interface WorkerTest : GHAsyncTestCase { }

@end


@implementation WorkerTest


#pragma mark - tests


- (void)test_01_worker {
  [self prepare];
  
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  Worker *worker = [[Worker alloc] initWithImage:image];
 
  [worker addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
  
  [worker main];

  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:20];
  GHAssertEqualStrings(@"037233", worker.textResult, nil);
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