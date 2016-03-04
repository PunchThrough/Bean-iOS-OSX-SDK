#import <XCTest/XCTest.h>
#import "BeanContainer.h"

@interface TestBeanContainer : XCTestCase

@end

/**
 *  This filter selects Beans with names that start with "TEST_BEAN_"
 */
static BOOL (^testBeanFilter)(PTDBean *bean) = ^BOOL(PTDBean *bean) {
    return [bean.name hasPrefix:@"TEST_BEAN_"];
};

/**
 *  This filter selects Beans named "Bean", the name Bean has out of the box
 */
static BOOL (^outOfBoxFilter)(PTDBean *bean) = ^BOOL(PTDBean *bean) {
    return [bean.name isEqualToString:@"Bean"];
};

@implementation TestBeanContainer

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
    BeanContainer *beanContainer = [self containerWithBeanFilter:testBeanFilter andOptions:nil];
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
    BeanContainer *beanContainer = [self containerWithBeanFilter:testBeanFilter andOptions:nil];

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
    BeanContainer *beanContainer = [self containerWithBeanFilter:outOfBoxFilter andOptions:options];
    
    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer updateFirmware]);
    XCTAssertTrue([beanContainer disconnect]);
}

/**
 *  Test that Bean firmware can be updated even when Bean is in a "recovery mode" firmware image
 *  (Bean is named "Bean update image").
 */
- (void)testBeanFirmwareUpdateAndRecover
{
    // Connection callback doesn't happen until Bean firmware is fully updated. Increase the connection timeout.
    NSDictionary *options = @{@"connectTimeout": @600};
    
    // Connect to a fresh Bean, upload one firmware image, and disconnect to put Bean into an OAD recovery state
    BeanContainer *beanContainer = [self containerWithBeanFilter:outOfBoxFilter andOptions:options];
    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer updateFirmwareOnce]);
    XCTAssertTrue([beanContainer cancelFirmwareUpdate]);
    XCTAssertTrue([beanContainer disconnect]);
    
    // Bean's name doesn't always change in the OS X CoreBluetooth cache quickly enough to be seen during a single test.
    // Select the mid-update Bean by UUID, not by name.
    PTDBean *midUpdateBean = beanContainer.bean;
    BOOL (^midUpdateBeanFilter)(PTDBean *bean) = ^BOOL(PTDBean *bean) {
        return [bean isEqualToBean:midUpdateBean];
    };

    // Connect to the mid-update Bean and finish uploading its remaining images
    beanContainer = [self containerWithBeanFilter:midUpdateBeanFilter andOptions:options];
    XCTAssertTrue([beanContainer connect]);
    XCTAssertTrue([beanContainer updateFirmware]);
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
