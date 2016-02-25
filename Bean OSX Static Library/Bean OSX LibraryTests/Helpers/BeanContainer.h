#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface BeanContainer : NSObject

+ (BeanContainer *)containerWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix;
- (instancetype)initWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix;

@end
