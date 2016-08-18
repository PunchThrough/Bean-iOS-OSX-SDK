#import <Foundation/Foundation.h>
@class PTDBean;  // to avoid circular import

/**
 *  Represents the firmware update status of a Bean.
 */
typedef NS_ENUM(NSUInteger, FirmwareStatus) {
    /**
     *  Could not determine if Bean needs a firmware update. Check the error param for details.
     */
    FirmwareStatusCouldNotDetermine,
    /**
     *  Firmware on Bean is current with the available firmware.
     */
    FirmwareStatusUpToDate,
    /**
     *  Available firmware is newer than firmware on Bean.
     */
    FirmwareStatusBeanNeedsUpdate,
    /**
     *  Firmware on Bean is newer than available firmware.
     */
    FirmwareStatusBeanIsNewerThanAvailable,
};

@interface PTDFirmwareHelper : NSObject

/**
 *  Check if a Bean is running out-of-date firmware and should be updated. This method takes into account the firmware
 *  that is available in the client. If Bean has newer firmware than the client, this returns NO.
 *  @param bean The Bean to be inspected for firmware state
 *  @param version The firmware version available in the client. Should be a simple 12-digit datestamp.
 *      For example, "201501110000_A_BEAN_PLUS.bin" should first be parsed to the string 201501110000
 *  @param error Pass in an NSError object. If an error occurs, this will be set to the error.
 *      If successful, this will be nil
 *  @return FirmwareStatus that represents the status of Bean's firmware in relation to the available firmware
 */
+ (FirmwareStatus)firmwareUpdateRequiredForBean:(PTDBean *)bean availableFirmware:(NSString *)version withError:(NSError * __autoreleasing *)error;

/**
 *  Check if a Bean is running an OAD firmware update image. These images are not fully functional and only support firmware updates.
 *  @param bean The Bean to be inspected for OAD image state
 *  @return YES if Bean is running an OAD image, NO if Bean is running any other image
 */
+ (BOOL)oadImageRunningOnBean:(PTDBean *)bean;

@end
