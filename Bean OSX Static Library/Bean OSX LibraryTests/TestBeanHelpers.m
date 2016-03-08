#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "PTDUtils.h"
#import "PTDFirmwareHelper.h"

@interface TestBeanHelpers : XCTestCase

@end

@implementation TestBeanHelpers

/**
 *  Ensure that parseInteger parses integers and nothing else.
 */
- (void)testParseInteger
{
    XCTAssertTrue([[PTDUtils parseInteger:@"123"] integerValue] == 123);
    XCTAssertNil([PTDUtils parseInteger:@"123 "]);
    XCTAssertNil([PTDUtils parseInteger:@"123_"]);
    XCTAssertNil([PTDUtils parseInteger:@"?456"]);
    XCTAssertNil([PTDUtils parseInteger:@" 456"]);
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
    
    // Success cases

    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:oldDate withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:nowDate withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:futureDate withError:&error]);

    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:oldDate withError:&error]);
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:nowDate withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:futureDate withError:&error]);

    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:oldDate withError:&error]);
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:nowDate withError:&error]);
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:futureDate withError:&error]);

    // Ensure OAD beans always get an update
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:oldDate withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:nowDate withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:futureDate withError:&error]);

    // Ensure no method above errored out
    XCTAssertNil(error);

    // Failure cases

    PTDBean *beanWithInvalidDate = OCMClassMock([PTDBean class]);
    OCMStub(beanWithInvalidDate.firmwareVersion).andReturn(@"12345xyz");

    // Should fail when Bean has an invalid date
    error = nil;
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:beanWithInvalidDate availableFirmware:futureDate withError:&error]);
    XCTAssertNotNil(error);

    // Should fail when firmware has an invalid date
    error = nil;
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:@"12345xyz" withError:&error]);
    XCTAssertNotNil(error);
    
}

@end
