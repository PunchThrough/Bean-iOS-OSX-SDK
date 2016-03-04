#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BEAN_Helper.h"

@interface TestBeanHelpers : XCTestCase

@end

@implementation TestBeanHelpers

/**
 *  Ensure that toInteger parses integers and nothing else.
 */
- (void)testToInteger
{
    XCTAssertTrue([[BEAN_Helper toInteger:@"123"] integerValue] == 123);
    XCTAssertNil([BEAN_Helper toInteger:@"123 "]);
    XCTAssertNil([BEAN_Helper toInteger:@"123_"]);
    XCTAssertNil([BEAN_Helper toInteger:@"?456"]);
    XCTAssertNil([BEAN_Helper toInteger:@" 456"]);
}

/**
 *  Ensure that firmwareUpdateRequiredForBean returns proper values for different firmwares and Beans.
 */
- (void)testfirmwareUpdateRequiredForBean
{
    NSString *oldDate = @"199201110734";
    NSString *nowDate = @"201602290130";
    NSString *futureDate = @"206304050000";
    NSString *oadFirmware = @"OAD Img B";

    PTDBean *oldBean = OCMClassMock([PTDBean class]);
    OCMStub(oldBean.firmwareVersion).andReturn(oldDate);
    PTDBean *nowBean = OCMClassMock([PTDBean class]);
    OCMStub(nowBean.firmwareVersion).andReturn(nowDate);
    PTDBean *futureBean = OCMClassMock([PTDBean class]);
    OCMStub(futureBean.firmwareVersion).andReturn(futureDate);
    PTDBean *oadBean = OCMClassMock([PTDBean class]);
    OCMStub(oadBean.firmwareVersion).andReturn(oadFirmware);

    // Verify our mock works properly
    XCTAssertTrue([oldBean.firmwareVersion isEqualToString:oldDate]);

    NSError *error;

    XCTAssertFalse([BEAN_Helper firmwareUpdateRequiredForBean:oldBean availableFirmware:oldDate withError:&error]);
    XCTAssertTrue([BEAN_Helper firmwareUpdateRequiredForBean:oldBean availableFirmware:nowDate withError:&error]);
    XCTAssertTrue([BEAN_Helper firmwareUpdateRequiredForBean:oldBean availableFirmware:futureDate withError:&error]);

    XCTAssertFalse([BEAN_Helper firmwareUpdateRequiredForBean:nowBean availableFirmware:oldDate withError:&error]);
    XCTAssertFalse([BEAN_Helper firmwareUpdateRequiredForBean:nowBean availableFirmware:nowDate withError:&error]);
    XCTAssertTrue([BEAN_Helper firmwareUpdateRequiredForBean:nowBean availableFirmware:futureDate withError:&error]);

    XCTAssertFalse([BEAN_Helper firmwareUpdateRequiredForBean:futureBean availableFirmware:oldDate withError:&error]);
    XCTAssertFalse([BEAN_Helper firmwareUpdateRequiredForBean:futureBean availableFirmware:nowDate withError:&error]);
    XCTAssertFalse([BEAN_Helper firmwareUpdateRequiredForBean:futureBean availableFirmware:futureDate withError:&error]);

    XCTAssertTrue([BEAN_Helper firmwareUpdateRequiredForBean:oadBean availableFirmware:oldDate withError:&error]);
    XCTAssertTrue([BEAN_Helper firmwareUpdateRequiredForBean:oadBean availableFirmware:nowDate withError:&error]);
    XCTAssertTrue([BEAN_Helper firmwareUpdateRequiredForBean:oadBean availableFirmware:futureDate withError:&error]);

    XCTAssertNil(error);
}

@end
