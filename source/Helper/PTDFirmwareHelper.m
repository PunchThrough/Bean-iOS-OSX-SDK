#import "PTDFirmwareHelper.h"
#import "PTDUtils.h"

@implementation PTDFirmwareHelper

+ (BOOL)firmwareUpdateRequiredForBean:(PTDBean *)bean availableFirmware:(NSString *)version withError:(NSError * __autoreleasing *)error
{
    // OAD images always need an update
    if ([bean.firmwareVersion hasPrefix:@"OAD"]) {
        return YES;
    }

    NSNumber *onBean = [PTDUtils parseInteger:bean.firmwareVersion];
    NSNumber *available = [PTDUtils parseInteger:version];

    if (!onBean) {
        *error = [self errorForNonIntegerVersion:version deviceName:@"Bean"];
        return NO;
    }

    if (!available) {
        *error = [self errorForNonIntegerVersion:version deviceName:@"available firmware"];
        return NO;
    }

    return [available integerValue] > [onBean integerValue];
}

+ (NSError *)errorForNonIntegerVersion:(NSString *)version deviceName:(NSString *)name
{
    NSString *message = @"Firmware version string for %@ could not be parsed as an integer: \"%@\"";
    NSString *desc = [NSString stringWithFormat:message, name, version];
    return [NSError errorWithDomain:@"FirmwareVersionInvalid"
                               code:-1
                           userInfo:@{@"localizedDescription": desc}];
}

@end
