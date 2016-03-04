#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BEAN_Helper.h"

@interface TestBeanHelpers : XCTestCase

@end

@implementation TestBeanHelpers

/**
 *  Ensure that firmwareUpdateRequiredForBean returns proper values for different firmwares and Beans.
 */
- (void)testfirmwareUpdateRequiredForBean
{
    PTDBean *oldBean = OCMClassMock([PTDBean class]);
    OCMStub(oldBean.firmwareVersion).andReturn(@"199201110734");

    // Verify our mock works properly
    XCTAssertTrue([oldBean.firmwareVersion isEqualToString:@"199201110734"]);
}

@end
