#import "PTDFirmwareHelper.h"
#import "PTDUtils.h"

@implementation PTDFirmwareHelper


+ (BOOL)firmwareUpdateRequiredForBean:(PTDBean *)bean availableFirmware:(NSString *)version withError:(NSError **)error
{
    // OAD images always need an update
    if ([bean.firmwareVersion hasPrefix:@"OAD"]) {
        return YES;
    }

    NSNumber *onBean = [PTDUtils parseInteger:bean.firmwareVersion];
    NSNumber *available = [PTDUtils parseInteger:version];

    if (!onBean) {
        // TODO: Error: Bean FW version was not OAD and is not integer
        return NO;
    }

    if (!available) {
        // TODO: Error: Available FW version is not integer
        return NO;
    }

    return [available integerValue] > [onBean integerValue];
}

@end
