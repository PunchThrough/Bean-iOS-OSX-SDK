//
//  TestPTDIntelHex.m
//  Bean OSX Library
//
//  Created by Matthew Lewis on 2/23/16.
//  Copyright © 2016 Punch Through Design. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PTDIntelHex.h"

@interface TestPTDIntelHex : XCTestCase

@property (nonatomic, strong) NSString *intelHexPath;
@property (nonatomic, strong) NSString *intelHexString;
@property (nonatomic, strong) NSData *expectedBytes;

@end

@implementation TestPTDIntelHex

- (void)setUp {
    [super setUp];

    self.intelHexPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"IntelHexSource" ofType:@"hex"];
    NSError *error;
    self.intelHexString = [NSString stringWithContentsOfFile:self.intelHexPath encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);

    NSString *bytesPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"IntelHexBinary" ofType:@"bin"];
    self.expectedBytes = [NSData dataWithContentsOfFile:bytesPath];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 *  Ensure PTDIntelHex parses Intel HEX data from an NSString into NSData.
 */
- (void)testStringsToBytes
{
    PTDIntelHex *hexObject = [PTDIntelHex intelHexFromHexString:self.intelHexString];
    NSData *hexBytes = [hexObject bytes];
    XCTAssertTrue([hexBytes isEqualToData:self.expectedBytes]);
}

/**
 *  Ensure PTDIntelHex parses Intel HEX data from a file path into NSData.
 */
- (void)testFileToBytes
{
    PTDIntelHex *hexObject = [PTDIntelHex intelHexFromFileURL:[NSURL fileURLWithPath:self.intelHexPath]];
    NSData *hexBytes = [hexObject bytes];
    XCTAssertTrue([hexBytes isEqualToData:self.expectedBytes]);
}

/**
 *  Ensure PTDIntelHex sets the sketch name when it parses a sketch from an NSURL file object.
 */
- (void)testFileSetsName
{
    PTDIntelHex *hexObject = [PTDIntelHex intelHexFromFileURL:[NSURL fileURLWithPath:self.intelHexPath]];
    XCTAssertTrue([hexObject.name isEqualToString:@"IntelHexSource"]);
}

@end
