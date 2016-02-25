#import <XCTest/XCTest.h>
#import "StatelessUtils.h"

@interface TestStatelessUtils : XCTestCase

@end

@implementation TestStatelessUtils

/**
 *  Verify that the hexDataFromResource helper is properly reading the example sketch.
 */
- (void)testReadHex
{
    NSInteger len = [StatelessUtils bytesFromIntelHexResource:@"blink" usingBundleForClass:[self class]].length;
    XCTAssertEqual(len, 5114);  // Verified by hand - blink.hex represents 5114 bytes of raw data
}

@end
