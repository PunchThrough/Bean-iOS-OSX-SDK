#import "PTDHardwareLookup.h"

@implementation PTDHardwareLookup

/**
 *  Determines the hardware type for a given hardware version string.
 *  @param version Hardware version of the device, i.e. "2C"
 *  @return The hardware type of the device, or PTDHardwareTypeUnknown if no matching device was found
 */
+ (PTDHardwareType)hardwareTypeForVersion:(NSString *)version
{
    // First see if any literals match
    PTDHardwareType type = (PTDHardwareType)[[self typeByLiteral][version] integerValue];
    if (type) return type;

    // Then look up by prefix
    for (NSString *key in [self typeByPrefix]) {
        if ([version hasPrefix:key]) {
            return (PTDHardwareType)[[self typeByPrefix][key] integerValue];
        }
    }

    return PTDHardwareTypeUnknown;
}

+ (NSString *)hardwareNameForVersion:(NSString *)version
{
    return [self nameByType][@([self hardwareTypeForVersion:version])];
}

// Hardware version literals. Some Beans don't start with a number, so look them up directly.
// Static dictionary technique from http://stackoverflow.com/a/13235024
+ (NSDictionary *)typeByLiteral {
    static NSDictionary *inst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ inst = @{

        @"E": @(PTDHardwareTypeBean),

    }; });
    return inst;
}

// Hardware version prefixes. Bean and Bean+ start with a number (type) and end with a letter (revision)
+ (NSDictionary *)typeByPrefix {
    static NSDictionary *inst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ inst = @{

        @"1": @(PTDHardwareTypeBean),
        @"2": @(PTDHardwareTypeBeanPlus),

    }; });
    return inst;
}

// Human-readable hardware names for each hardware type
+ (NSDictionary *)nameByType {
    static NSDictionary *inst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ inst = @{

        @(PTDHardwareTypeUnknown): @"(unknown)",
        @(PTDHardwareTypeBean): @"Bean",
        @(PTDHardwareTypeBeanPlus): @"Bean+",

    }; });
    return inst;
}
@end
