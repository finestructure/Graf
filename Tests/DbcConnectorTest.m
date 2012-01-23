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


- (void)testFoo {       
  NSString *a = @"foo";
  GHTestLog(@"I can log to the GHUnit test console: %@", a);
  
  // Assert a is not NULL, with no custom error description
  GHAssertNotNil(a, @"a must not be nil");
  
  // Assert equal objects, add custom error description
  NSString *b = @"bar";
  GHAssertEqualObjects(a, b, @"A custom error message. a should be equal to: %@.", b);
}


- (void)testConnect {
	[self prepare:@selector(testConnect)];
  
	[self.dbc connect];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
}


#pragma mark - delegate

- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
	//[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testAsync1)];
}

@end