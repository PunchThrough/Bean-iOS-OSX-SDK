#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "PTDBean.h"
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
    XCTAssertTrue([[PTDUtils parseLeadingInteger:@"123"] integerValue] == 123);
    XCTAssertTrue([[PTDUtils parseLeadingInteger:@"123 "] integerValue] == 123);
    XCTAssertTrue([[PTDUtils parseLeadingInteger:@"123_"] integerValue] == 123);
    XCTAssertNil([PTDUtils parseLeadingInteger:@"?456"]);
    XCTAssertNil([PTDUtils parseLeadingInteger:@" 456"]);
}

/**
 *  Ensure that firmwareUpdateRequiredForBean returns proper values for different firmwares and Beans.
 */
- (void)testfirmwareUpdateRequiredForBean
{
    NSString *oldDate = @"199201110734 Img-X";
    NSString *nowDate = @"201602290130 Img-A";
    NSString *futureDate = @"206304050000 Img-B";
    NSString *oadFirmware = @"OAD Img B";
    
    NSInteger oldDateNumber = 199201110734;
    NSInteger nowDateNumber = 201602290130;
    NSInteger futureDateNumber = 206304050000;
    
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

    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:oldDateNumber withError:&error], FirmwareStatusUpToDate);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:nowDateNumber withError:&error], FirmwareStatusBeanNeedsUpdate);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:oldBean availableFirmware:futureDateNumber withError:&error], FirmwareStatusBeanNeedsUpdate);
    
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:oldDateNumber withError:&error], FirmwareStatusBeanIsNewerThanAvailable);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:nowDateNumber withError:&error], FirmwareStatusUpToDate);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:nowBean availableFirmware:futureDateNumber withError:&error], FirmwareStatusBeanNeedsUpdate);
    
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:oldDateNumber withError:&error], FirmwareStatusBeanIsNewerThanAvailable);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:nowDateNumber withError:&error], FirmwareStatusBeanIsNewerThanAvailable);
    XCTAssertEqual([PTDFirmwareHelper firmwareUpdateRequiredForBean:futureBean availableFirmware:futureDateNumber withError:&error], FirmwareStatusUpToDate);
    
    // Ensure OAD beans always get an update
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:oldDateNumber withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:nowDateNumber withError:&error]);
    XCTAssertTrue([PTDFirmwareHelper firmwareUpdateRequiredForBean:oadBean availableFirmware:futureDateNumber withError:&error]);

    // Ensure no method above errored out
    XCTAssertNil(error);

    // Failure cases

    PTDBean *beanWithInvalidDate = OCMClassMock([PTDBean class]);
    OCMStub(beanWithInvalidDate.firmwareVersion).andReturn(@"NOT_A_NUMBER");

    // Should fail when Bean has an invalid date
    error = nil;
    XCTAssertFalse([PTDFirmwareHelper firmwareUpdateRequiredForBean:beanWithInvalidDate availableFirmware:futureDateNumber withError:&error]);
    XCTAssertNotNil(error);
}

@end
