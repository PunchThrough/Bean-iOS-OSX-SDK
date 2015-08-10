//
//  Bean_OSX_LibraryTests.m
//  Bean OSX LibraryTests
//
//  Created by Raymond Kampmeier on 2/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PTDBeanManager.h"
#import "ConfigurationConstants.h"

@interface DefaultConnectionTests : XCTestCase <PTDBeanManagerDelegate, PTDBeanDelegate>
{
    PTDBeanManager * beanManager;
    PTDBean * testBean;
    XCTestExpectation *setUpExpectation, *tearDownExpectation, *testExpectation;
    XCTestExpectation *rssiReadExpectation;
}
@end

@implementation DefaultConnectionTests

// This method is called before the invocation of each test method in the class.
- (void)setUp
{
    [super setUp];
    setUpExpectation = [self expectationWithDescription:@"setUp Expectations"];
    beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    
    [self waitForExpectationsWithTimeout:kExpectationTimeoutDelay_seconds handler:^(NSError *error) {
        XCTAssert(!error, @"Couldn't find the test Bean. Make sure there is a Bean in the area with name: %@", TestBeanName);
    }];
}

// This method is called after the invocation of each test method in the class.
- (void)tearDown
{
    tearDownExpectation = [self expectationWithDescription:@"tearDown Expectations"];
    NSError* error;
    [beanManager disconnectBean:testBean error:&error];
    XCTAssert(!error, @"Error while trying to disconnect from the test Bean");
    
    [self waitForExpectationsWithTimeout:kExpectationTimeoutDelay_seconds handler:^(NSError *error) {
        XCTAssert(!error, @"Couldn't disconnect from the test Bean.");
    }];
    [super tearDown];
}

#pragma - mark Functional Tests

// Connect and disconnect from the test Bean
- (void)testConnection
{
    // setUp and tearDown inherently include the testing for this
}

// Sets the test Bean's LED to full intensity (white) for 3 seconds
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

// Reads the test Bean's RSSI value
- (void)testReadRSSI
{
    rssiReadExpectation  = [self expectationWithDescription:@"RSSI Read Expectation"];
    
    [testBean readRSSI];
    
    [self waitForExpectationsWithTimeout:kExpectationTimeoutDelay_seconds handler:^(NSError *error) {
        XCTAssert(!error, @"Timeout.");
    }];
    
    NSLog(@"Bean RSSI: %@", testBean.RSSI);
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
        [beanManager connectToBean:bean error:nil];
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

- (void)beanDidUpdateRSSI:(PTDBean *)bean error:(NSError *)error{
    if(rssiReadExpectation){
        [rssiReadExpectation fulfill];
    }
}
@end
