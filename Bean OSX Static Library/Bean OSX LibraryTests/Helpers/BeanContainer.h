#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

/**
 *  BeanContainers are used to manage the state of a physical Bean under test. They simplify test logic by stripping
 *  CoreBluetooth idiosyncrasies from the tests.
 */
@interface BeanContainer : NSObject

/**
 *  Construct a BeanContainer.
 *
 *  To start using a BeanContainer, pass in the XCTestCase that will use the Bean container and the name prefix to use
 *  when discovering Beans that are ready for testing. BeanContainer will begin discovery and return an instance of
 *  itself once a Bean with the right prefix has been discovered.
 *
 *  @param testCase The test case associated with this BeanContainer
 *  @param prefix Beans that begin with this prefix will be selected for testing
 */
+ (BeanContainer *)containerWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix;
/**
 *  Initialize a BeanContainer.
 *
 *  To start using a BeanContainer, pass in the XCTestCase that will use the Bean container and the name prefix to use
 *  when discovering Beans that are ready for testing. BeanContainer will begin discovery and return an instance of
 *  itself once a Bean with the right prefix has been discovered.
 *
 *  @param testCase The test case associated with this BeanContainer
 *  @param prefix Beans that begin with this prefix will be selected for testing
 */
- (instancetype)initWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix;

/**
 *  Connect to the Bean under test.
 *  @return YES if connect succeeded
 */
- (BOOL)connect;
/**
 *  Disconnect from the Bean under test.
 *  @return YES if disconnect succeeded
 */
- (BOOL)disconnect;

/**
 *  Set Bean's LED to a color, verify the LED was set to that color, then set the LED to black.
 *  @param color The color to set Bean's LED to
 *  @return YES if color was set successfully
 */
- (BOOL)blinkWithColor:(NSColor *)color;

/**
 *  Upload a sketch compiled as a raw binary hex file to Bean.
 *  @param hexName The name of the hex file to upload.
 *      This name will be used for the Bean's programmed sketch name as well.
 *      This resource must be present in the test bundle.
 *      For example, to upload <code>mysketch.hex</code>, <code>hexName</code> should be <code>mysketch</code>.
 *      The name of Bean's sketch will be set to <code>mysketch</code>.
 *  @return YES if sketch was uploaded successfully
 */
- (BOOL)uploadSketch:(NSString *)hexName;

/**
 *  Update the firmware on Bean with the images inside the "Firmware Images" folder.
 *  @return YES if firmware update was successful
 */
- (BOOL)updateFirmware;

@end
