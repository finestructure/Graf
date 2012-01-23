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


#pragma mark - tests


- (void)test_connect {
	[self prepare];
  
	[self.dbc connect];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10];
  GHAssertTrue(self.dbc.connected, nil);
}


#pragma mark - delegate

- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
	[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_connect)];
}

@end