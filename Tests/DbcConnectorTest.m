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
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:5];
  GHAssertTrue(self.dbc.connected, nil);
}


- (void)test_login {
  [self.dbc connect];
  [self prepare];
  
  [self.dbc login];

	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:5];
  GHAssertTrue(self.dbc.loggedIn, nil);
  GHAssertEqualStrings(@"50402", [[self.dbc.user objectForKey:@"user"] stringValue], nil);
}


#pragma mark - delegate


- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
	[self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_connect)];
}


- (void)didLogInAs:(NSString *)user {
  [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(test_login)];
}

@end