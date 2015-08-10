//
//  SpeedConnectionTests.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 8/10/15.
//  Copyright (c) 2015 Punch Through Design. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "PTDBeanManager.h"
#import "ConfigurationConstants.h"

@interface SpeedConnectionTests : XCTestCase  <PTDBeanManagerDelegate, PTDBeanDelegate>
{
    PTDBeanManager * beanManager;
    PTDBean * testBean;
    XCTestExpectation *setUpExpectation, *tearDownExpectation, *testExpectation;
}

@end

@implementation SpeedConnectionTests

- (void)setUp {
    [super setUp];
    setUpExpectation = [self expectationWithDescription:@"setUp Expectations"];
    beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    
    [self waitForExpectationsWithTimeout:kExpectationTimeoutDelay_seconds handler:^(NSError *error) {
        XCTAssert(!error, @"Couldn't find the test Bean. Make sure there is a Bean in the area with name: %@", TestBeanName);
    }];
}

- (void)tearDown {
    tearDownExpectation = [self expectationWithDescription:@"tearDown Expectations"];
    NSError* error;
    [beanManager disconnectBean:testBean error:&error];
    XCTAssert(!error, @"Error while trying to disconnect from the test Bean");
    
    [self waitForExpectationsWithTimeout:kExpectationTimeoutDelay_seconds handler:^(NSError *error) {
        XCTAssert(!error, @"Couldn't disconnect from the test Bean.");
    }];    [super tearDown];
}

// Connect and disconnect from the test Bean.
// Faster connection is achieved, as this setup/connection routine only requires the Gatt Serial profile.
- (void)testConnection
{
    // setUp and tearDown inherently include the testing for this
}

- (void)testLEDBlink
{
    testExpectation  = [self expectationWithDescription:@"testLEDBlink Expectation"];
    [testBean setLedColor:[NSColor colorWithRed:1 green:1 blue:1 alpha:1]];
    int64_t delayInSeconds = 3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [testBean setLedColor:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
    });
    // Delay for 1 second longer to allow for LED-off command to go through
    delayInSeconds = 4;
    popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [testExpectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:kExpectationTimeoutDelay_seconds handler:^(NSError *error) {
        XCTAssert(!error, @"Timeout.");
    }];
}

#pragma - mark Internal Methods
- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(manager.state == BeanManagerState_PoweredOn){
        [beanManager startScanningForBeans_error:nil];
    }
}

- (void)beanManager:(PTDBeanManager*)manager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    XCTAssert(!error);
    if ([[bean name] isEqualToString:[NSString stringWithFormat:@"%@",TestBeanName]]){
        testBean = bean;
        [beanManager stopScanningForBeans_error:nil];
        [beanManager connectToBean:bean
                       withOptions:@{ PTDBeanManagerConnectionOptionProfilesRequiredToConnect : @[
                                              NSClassFromString(@"GattSerialProfile")
                                        ]}
                             error:nil];
    }
}

- (void)beanManager:(PTDBeanManager*)manager didConnectBean:(PTDBean*)bean error:(NSError*)error{
    XCTAssert(!error);
    XCTAssert(bean);
    XCTAssert(testBean);
    XCTAssert([bean isEqualTo:testBean]);
    XCTAssert(testBean.state == BeanState_ConnectedAndValidated);
    
    testBean.delegate = self;
    
    if(setUpExpectation){
        [setUpExpectation fulfill];
    }
}

- (void)beanManager:(PTDBeanManager*)manager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    XCTAssert(!error);
    if(tearDownExpectation){
        [tearDownExpectation fulfill];
    }
}
@end
