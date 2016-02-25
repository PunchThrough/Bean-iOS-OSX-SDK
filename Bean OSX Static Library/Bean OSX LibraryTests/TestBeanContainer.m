#import <XCTest/XCTest.h>
#import "BeanContainer.h"

@interface TestBeanContainer : XCTestCase

@end

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
    BeanContainer *c = [BeanContainer containerWithTestCase:self andBeanNamePrefix:@"TEST_BEAN_"];
    XCTAssertNotNil(c);

    NSColor *magenta = [NSColor colorWithRed:1 green:0 blue:1 alpha:1];

    XCTAssertTrue([c connect]);
    XCTAssertTrue([c blinkWithColor:magenta]);
    XCTAssertTrue([c disconnect]);
}

/**
 *  Test that sketches can be uploaded to Bean.
 */
- (void)testUploadSketchToBean
{
    BeanContainer *c = [BeanContainer containerWithTestCase:self andBeanNamePrefix:@"TEST_BEAN_"];
    XCTAssertNotNil(c);

    XCTAssertTrue([c connect]);
    XCTAssertTrue([c uploadSketch:@"blink"]);
    XCTAssertTrue([c disconnect]);
}

@end
