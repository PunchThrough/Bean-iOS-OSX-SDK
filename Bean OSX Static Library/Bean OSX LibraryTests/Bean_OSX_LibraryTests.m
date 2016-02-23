//
//  Bean_OSX_LibraryTests.m
//  Bean OSX LibraryTests
//
//  Created by Raymond Kampmeier on 2/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PTDBeanManager.h"

@interface Bean_OSX_LibraryTests : XCTestCase <PTDBeanManagerDelegate, PTDBeanDelegate>

@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSString *beanName;
@property (nonatomic, strong) __block PTDBean *testBean;

@property (nonatomic, strong) void (^beanBlock)(PTDBean *bean);

@end

@implementation Bean_OSX_LibraryTests

- (void)setUp
{
    [super setUp];

    // Prepare BeanManager and make sure it's happy with Bluetooth powered on
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    [self delayForSeconds:1];
    
    self.beanName = @"NEO";
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // clear blocks
    [self cleanup];
}

#pragma mark - tests

- (void)testDiscoverBean
{
    [self discoverBean];
}

- (void)testConnectBean
{
    [self discoverBean];
    [self connectBean];
    [self disconnectBean];
}

- (void)testBlinkBean
{
    [self discoverBean];
    [self connectBean];
    [self blinkBean];
    [self disconnectBean];
}

#pragma mark - bean manager delegate

- (void)BeanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    NSLog(@"Discovered Bean: %@", bean);
    if (self.beanBlock) {
        self.beanBlock(bean);
    }
}

- (void)BeanManager:(PTDBeanManager *)beanManager didConnectToBean:(PTDBean *)bean error:(NSError *)error
{
    NSLog(@"Connected Bean: %@", bean);
    if (self.beanBlock) {
        self.beanBlock(bean);
    }
}

#pragma mark - bean delegate

- (void)bean:(PTDBean *)bean didUpdateLedColor:(NSColor *)color
{
    NSLog(@"Blinked Bean: %@", bean);
    if (self.beanBlock) {
        self.beanBlock(bean);
    }
}

#pragma mark - test helpers

- (void)delayForSeconds:(NSInteger)seconds
{
    XCTestExpectation *waitedForXSeconds = [self expectationWithDescription:@"Waited for some specific time"];
    
    // Delay for some time (??) so that CBCentralManager connection state becomes PoweredOn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [waitedForXSeconds fulfill];
    });
    
    [self waitForExpectationsWithTimeout:seconds + 1 handler:nil];
}

- (void)cleanup
{
    // reset blocks so no test interference occurs, since blocks are triggered by BeanManager delegates
    self.beanBlock = nil;
}

- (void)discoverBean
{
    // given
    NSError *error;
    self.testBean = nil;
    
    // when
    XCTestExpectation *beanDiscover = [self expectationWithDescription:@"Target Bean found"];
    self.beanBlock = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Discovered target Bean: %@", bean);
            self.testBean = bean;
            [beanDiscover fulfill];
        }
    };
    
    // scan
    [self.beanManager startScanningForBeans_error:&error];
    if (error) {
        XCTFail(@"startScanningForBeans should not fail");
        return;
    }
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    // stop scan
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        XCTFail(@"stopScanningForBeans should not fail");
        return;
    }
    
    // then
    XCTAssertNotNil(self.testBean, @"targetBean should not be nil");
}

- (void)connectBean
{
    // given
    NSError *error;
    
    // when
    XCTestExpectation *beanConnect = [self expectationWithDescription:@"Target Bean connected"];
    self.beanBlock = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Connected target Bean: %@", bean);
            bean.delegate = self;
            self.testBean = bean;
            [beanConnect fulfill];
        }
    };
    
    // connect
    NSError *connectError;
    [self.beanManager connectToBean:self.testBean error:&connectError];
    // connectError always throws a "connection in progress" error, so don't assert that it is not nil
    // TODO: Isolate, reproduce error, figure out why this happens

    // then
    [self waitForExpectationsWithTimeout:20 handler:nil];
    XCTAssertTrue(self.testBean.state == BeanState_ConnectedAndValidated);
}

- (void)disconnectBean
{
    // disconnect
    NSError *disconnectError;
    [self.beanManager disconnectBean:self.testBean error:&disconnectError];
    XCTAssertNil(disconnectError);
}

- (void)blinkBean
{
    // when
    XCTestExpectation *beanBlink = [self expectationWithDescription:@"Target Bean blinked"];
    self.beanBlock = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Blinked target Bean: %@", bean);
            [beanBlink fulfill];
        }
    };
    
    // blink
    [self.testBean setLedColor: [NSColor blueColor]];
    [self.testBean readLedColor];
    
    // then
    [self waitForExpectationsWithTimeout:20 handler:nil];
    [self.testBean setLedColor: [NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0]];
}



@end
