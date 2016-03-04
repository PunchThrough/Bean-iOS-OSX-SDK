#import <XCTest/XCTest.h>
#import "PTDHardwareLookup.h"

@interface TestPTDHardwareLookup : XCTestCase

@end

@implementation TestPTDHardwareLookup

/**
 *  Verify that hardwareNameForVersion looks up the hardware name for Bean versions properly.
 */
- (void)testHardwareTypeLookupWorks
{
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"E"] == PTDHardwareTypeBean);
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"1"] == PTDHardwareTypeBean);
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"1E"] == PTDHardwareTypeBean);
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"1C"] == PTDHardwareTypeBean);
    
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"2"] == PTDHardwareTypeBeanPlus);
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"2A"] == PTDHardwareTypeBeanPlus);
    XCTAssertTrue([PTDHardwareLookup hardwareTypeForVersion:@"2D"] == PTDHardwareTypeBeanPlus);
}

/**
 *  Verify that hardwareNameForVersion looks up the hardware name for Bean versions properly.
 */
- (void)testHardwareNameLookupWorks
{
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"E"] isEqualToString:@"Bean"]);
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"1"] isEqualToString:@"Bean"]);
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"1E"] isEqualToString:@"Bean"]);
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"1C"] isEqualToString:@"Bean"]);
    
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"2"] isEqualToString:@"Bean+"]);
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"2A"] isEqualToString:@"Bean+"]);
    XCTAssertTrue([[PTDHardwareLookup hardwareNameForVersion:@"2D"] isEqualToString:@"Bean+"]);
}

@end
