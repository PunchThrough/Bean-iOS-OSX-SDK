#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface StatelessUtils : NSObject

/**
 *  Delay for a specified period of time.
 *  @param testCase The XCTestCase calling this method (usually, self)
 *  @param seconds The amount of time to delay, in seconds
 */
+ (void)delayTestCase:(XCTestCase *)testCase forSeconds:(NSTimeInterval)seconds;

/**
 *  Parse an Intel HEX file (with the extension .hex) into raw bytes.
 *  @param intelHexFileName The name of the Intel HEX file. For example, to read from mysketch.hex,
 *      <code>intelHexFileName</code> should be "mysketch"
 *  @param klass The class to be used to select the bundle. Usually this should be <code>[self class]</code>
 *  @return An NSData object with the contents of the file, or nil if the file couldn't be opened
 */
+ (NSData *)bytesFromIntelHexResource:(NSString *)intelHexFilename usingBundleForClass:(id)klass;

/**
 *  Get the images files from the firmwareImages folder in the test resources folder.
 *  @param  The imageFolder specifies where the .bin files are stored
 *  @return An NSArray object with the contents of the folder, or nil if the folder couldn't be opened
 */
+ (NSArray *)firmwareImagesFromResource:(NSString *)imageFolder;

@end
