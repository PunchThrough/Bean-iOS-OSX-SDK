//
//  Bean_OSX_LibraryTests.m
//  Bean OSX LibraryTests
//
//  Created by Raymond Kampmeier on 2/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PTDBeanManager.h"

@interface Bean_OSX_LibraryTests : XCTestCase <PTDBeanManagerDelegate>

@property (nonatomic, strong) void (^beanDiscovered)(PTDBean *bean);

@end

@implementation Bean_OSX_LibraryTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - tests

- (void)testFindBean
{
    // given
    NSString *beanName = @"NEO";
    PTDBeanManager *beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    XCTestExpectation *waitedForBTPoweredOn = [self expectationWithDescription:@"Waited for Bluetooth to power on"];

    // Delay for some time (??) so that CBCentralManager connection state becomes PoweredOn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [waitedForBTPoweredOn fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    // given
    __block PTDBean *targetBean;
    NSError *error;
    
    // when
    XCTestExpectation *beanFound = [self expectationWithDescription:@"Target Bean found"];
    self.beanDiscovered = ^void(PTDBean *bean) {
        NSLog(@"Found Bean: %@", bean);
        if ([bean.name isEqualToString:beanName]) {
            NSLog(@"Found target Bean: %@", bean);
            targetBean = bean;
            [beanFound fulfill];
        }
    };
    
    [beanManager startScanningForBeans_error:&error];
    if (error) {
        XCTFail(@"startScanningForBeans should not fail");
        return;
    }
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    // then
    XCTAssertNotNil(targetBean, @"targetBean should not be nil");
}

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // given
        __block PTDBean *targetBean;
        NSError *error;

        // when
        XCTestExpectation *beanFound = [self expectationWithDescription:@"Target Bean found"];
        self.beanDiscovered = ^void(PTDBean *bean) {
            NSLog(@"Found Bean: %@", bean);
            if ([bean.name isEqualToString:beanName]) {
                PTDLog(@"Found target Bean: %@", bean);
                targetBean = bean;
                [beanFound fulfill];
            }
        };
        
        [beanManager startScanningForBeans_error:&error];
        if (error) {
            XCTFail(@"startScanningForBeans should not fail");
            return;
        }
        
        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
            XCTFail(@"Timeout while waiting to discover target Bean: %@", beanName);
            return;
        }];
        
        // then
        XCTAssertNotNil(targetBean, @"targetBean should not be nil");
    });
}


#pragma mark - bean manager delegate

- (void)BeanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    NSLog(@"Discovered Bean: %@", bean);
    if (self.beanDiscovered) {
        self.beanDiscovered(bean);
    }
}

#pragma mark - bean delegates

@end
