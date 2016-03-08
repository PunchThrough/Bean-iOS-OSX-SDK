#import <Foundation/Foundation.h>
#import "PTDBean.h"

typedef NS_ENUM(NSUInteger, FirmwareStatus) {
    FirmwareStatusCouldNotDetermine,
    FirmwareStatusUpToDate,
    FirmwareStatusBeanNeedsUpdate,
    FirmwareStatusBeanIsNewerThanAvailable,
};

@interface PTDFirmwareHelper : NSObject

/**
 *  Check if a Bean is running out-of-date firmware and should be updated. This method takes into account the firmware
 *  that is available in the client. If Bean has newer firmware than the client, this returns NO.
 *  @param bean The Bean to be inspected for firmware state
 *  @param version The firmware version available in the client. Should be a simple 12-digit datestamp parsed as an integer.
 *      For example, "201501110000_A_BEAN_PLUS.bin" should first be parsed to the integer 201501110000
 *  @param error Pass in an NSError object. If an error occurs, this will be set to the error.
 *      If successful, this will be nil
 *  @return YES if Bean's firmware is out of date, NO if Bean has equivalent or newer firmware, NO if an error occurred
 */
+ (FirmwareStatus)firmwareUpdateRequiredForBean:(PTDBean *)bean availableFirmware:(NSInteger)version withError:(NSError * __autoreleasing *)error;

@end
