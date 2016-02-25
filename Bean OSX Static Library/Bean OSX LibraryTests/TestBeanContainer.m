#import <XCTest/XCTest.h>
#import "BeanContainer.h"

@interface TestBeanContainer : XCTestCase

@end

@implementation TestBeanContainer

- (void)setUp
{
    self.continueAfterFailure = NO;
}

- (void)testBlinkBean
{
    BeanContainer *c = [BeanContainer containerWithTestCase:self andBeanNamePrefix:@"TEST_BEAN_"];
    XCTAssertNotNil(c);

    NSColor *magenta = [NSColor colorWithRed:1 green:0 blue:1 alpha:1];

    XCTAssertTrue([c connect]);
    XCTAssertTrue([c blinkWithColor:magenta]);
    XCTAssertTrue([c disconnect]);
}

@end
