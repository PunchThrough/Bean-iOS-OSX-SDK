#import <XCTest/XCTest.h>
#import "BeanContainer.h"

@interface TestBeanContainer : XCTestCase

@property (nonatomic, strong) BeanContainer *beanContainer;

@end

@implementation TestBeanContainer

#pragma mark - Test configuration

- (void)setUp
{
    self.continueAfterFailure = NO;

    self.beanContainer = [BeanContainer containerWithTestCase:self andBeanNamePrefix:@"TEST_BEAN_"];
    XCTAssertNotNil(self.beanContainer);
}

- (void)tearDown
{
    self.beanContainer = nil;
}

#pragma mark - Feature tests

/**
 *  Test that Bean's LED can be set to a specific color.
 */
- (void)testBlinkBean
{
    NSColor *magenta = [NSColor colorWithRed:1 green:0 blue:1 alpha:1];

    XCTAssertTrue([self.beanContainer connect]);
    XCTAssertTrue([self.beanContainer blinkWithColor:magenta]);
    XCTAssertTrue([self.beanContainer disconnect]);
}

/**
 *  Test that sketches can be uploaded to Bean.
 */
- (void)testUploadSketchToBean
{
    XCTAssertTrue([self.beanContainer connect]);
    XCTAssertTrue([self.beanContainer uploadSketch:@"blink"]);
    XCTAssertTrue([self.beanContainer disconnect]);
}

/**
 *  Test that Bean firmware can be updated.
 */
- (void)testBeanFirmwareUpdate
{
    XCTAssertTrue([self.beanContainer connect]);
    XCTAssertTrue([self.beanContainer updateFirmware]);
    XCTAssertTrue([self.beanContainer disconnect]);
}

@end
