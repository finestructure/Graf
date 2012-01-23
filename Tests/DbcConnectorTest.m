#import <GHUnitIOS/GHUnit.h>
#import "DbcConnector.h"


@interface DbcConnectorTest : GHAsyncTestCase { }

@property (nonatomic, retain) DbcConnector *dbc;

@end


@implementation DbcConnectorTest



- (void)setUp {
  [super setUp];  
  self.dbc = [[DbcConnector alloc] init];
}


- (void)tearDown {
  [super tearDown];
}


- (void)testAsync1 {
	[self prepare];
  
	[_model1 sendRequest];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
}


#pragma mark - delegate

- (void)modelObjectDidFinishLoading:(ModelObject *)modelObject {
	[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testAsync1)];
}

@end