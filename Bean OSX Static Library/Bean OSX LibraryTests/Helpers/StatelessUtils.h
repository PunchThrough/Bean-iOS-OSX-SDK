#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface StatelessUtils : NSObject

+ (void)delayTestCase:(XCTestCase *)testCase forSeconds:(NSTimeInterval)seconds;

@end