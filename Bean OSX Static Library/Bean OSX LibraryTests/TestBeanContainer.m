#import <XCTest/XCTest.h>
#import "BeanContainer.h"

@interface TestBeanContainer : XCTestCase

@end

@implementation TestBeanContainer

- (void)testBeanContainer
{
    BeanContainer *c = [BeanContainer containerWithTestCase:self andBeanNamePrefix:@"TEST_BEAN_"];
    XCTAssertNotNil(c);
}

@end
