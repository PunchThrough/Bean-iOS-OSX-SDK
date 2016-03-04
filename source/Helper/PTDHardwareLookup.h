#import <Foundation/Foundation.h>

@interface PTDHardwareLookup : NSObject

typedef NS_ENUM(NSUInteger, PTDHardwareType) {
    PTDHardwareTypeUnknown = 0,
    PTDHardwareTypeBean,
    PTDHardwareTypeBeanPlus,
};

/**
 *  Determines the hardware type for a given hardware version string.
 *  @param version Hardware version of the device, i.e. "2C"
 *  @return The hardware type of the device, or PTDHardwareTypeUnknown if no matching device was found
 */
+ (PTDHardwareType)hardwareTypeForVersion:(NSString *)version;

/**
 *  Returns the human-readable name for a given hardware version string.
 *  @param version Hardware version of the device, i.e. "2C"
 *  @return The human-readable name of the device, i.e. "Bean+", or nil if no matching device was found
 */
+ (NSString *)hardwareNameForVersion:(NSString *)version;

@end
