#import <XCTest/XCTest.h>
#import "BeanContainer.h"

@interface TestBeanFeatures : XCTestCase

@end

/**
 *  This filter selects Beans named "Bean", the name Bean has out of the box
 */
static BOOL (^beanFilter)(PTDBean *bean) = ^BOOL(PTDBean *bean) {
    return [bean.name isEqualToString:@"Bean"];
};

/**
 *  This filter selects Bean+s named "Bean+", the name Bean+ has out of the box
 */
static BOOL (^beanPlusFilter)(PTDBean *bean) = ^BOOL(PTDBean *bean) {
    return [bean.name isEqualToString:@"Bean+"];
};

@implementation TestBeanFeatures

#pragma mark - Test configuration

- (void)setUp
{
    self.continueAfterFailure = NO;
}

#pragma mark - Feature tests

/**
 *  Test that Bean's LED can be set to a specific color.
 */
- (void)testBlinkBean
{
    BeanContainer *beanContainer = [self containerWithBeanFilter:beanFilter andOptions:nil];
    NSColor *magenta = [NSColor colorWithRed:1 green:0 blue:1 alpha:1];

    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer blinkWithColor:magenta]);
    XCTAssertTrue([beanContainer disconnect]);
}

/**
 *  Test that sketches can be uploaded to Bean.
 */
- (void)testUploadSketchToBean
{
    BeanContainer *beanContainer = [self containerWithBeanFilter:beanFilter andOptions:nil];

    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer uploadSketch:@"blink"]);
    XCTAssertTrue([beanContainer disconnect]);
}

/**
 *  Test that Bean firmware can be updated.
 */
- (void)testBeanFirmwareUpdate
{
    // Connection callback doesn't happen until Bean firmware is fully updated. Increase the connection timeout.
    NSDictionary *options = @{@"connectTimeout": @600};
    BeanContainer *beanContainer = [self containerWithBeanFilter:beanFilter andOptions:options];
    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer updateFirmware]);
    XCTAssertTrue([beanContainer disconnect]);
}

/**
 *  Test that Bean+ firmware can be updated.
 */
- (void)testBeanPlusFirmwareUpdate
{
    // Connection callback doesn't happen until Bean firmware is fully updated. Increase the connection timeout.
    NSDictionary *options = @{@"connectTimeout": @600};
    BeanContainer *beanContainer = [self containerWithBeanFilter:beanPlusFilter andOptions:options];
    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer updateFirmware]);
    XCTAssertTrue([beanContainer disconnect]);
}

/**
 *  Test that the Device Info profile has hardware and firmware version strings.
 */
- (void)testBeanHasDeviceInfo
{
    BeanContainer *beanContainer = [self containerWithBeanFilter:beanFilter andOptions:nil];

    XCTAssertTrue([beanContainer connect]);
    XCTAssertNotNil([beanContainer deviceInfo]);
    XCTAssertTrue([beanContainer disconnect]);
}

#pragma mark - Test helpers

/**
 *  Get a Bean container and abort the test if it doesn't instantiate properly.
 */
- (BeanContainer *)containerWithBeanFilter:(BOOL (^)(PTDBean *bean))filter andOptions:(NSDictionary *)options
{
    BeanContainer *container = [BeanContainer containerWithTestCase:self andBeanFilter:filter andOptions:options];
    XCTAssertNotNil(container);
    return container;
}

@end
