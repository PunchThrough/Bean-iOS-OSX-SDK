#import <Foundation/Foundation.h>

#import "BleProfile.h"

#define SERVICE_DEVICE_INFORMATION @"180A"
#define CHARACTERISTIC_HARDWARE_VERSION @"2A27"
#define CHARACTERISTIC_FIRMWARE_VERSION @"2A26"
#define CHARACTERISTIC_SOFTWARE_VERSION @"2A28"

/**
 *  Provides information on when DevInfoProfile properties are updated with new data.
 */
@protocol DevInfoProfileDelegate <NSObject>

@optional

/**
 *  Called when the <code>firmwareVersion</code> property has been updated with new data from the device.
 */
- (void)firmwareVersionDidUpdate;
/**
 *  Called when the <code>hardwareVersion</code> property has been updated with new data from the device.
 */
- (void)hardwareVersionDidUpdate;

@end

/**
 *  Provides access to the hardware version and firmware version characteristics of a Bean device.
 */
@interface DevInfoProfile : BleProfile <BleProfile>

/**
 *  The delegate for this device. Called when DevInfoProfile properties are updated.
 */
@property (nonatomic, weak) id<DevInfoProfileDelegate> delegate;
/**
 *  The firmware version for this device. Requested by a call to <code>readFirmwareVersion</code>.
 */
@property (nonatomic, strong) NSString *firmwareVersion;
/**
 *  The firmware version for this device. Requested by a call to <code>readHardwareVersion</code>.
 */
@property (nonatomic, strong) NSString *hardwareVersion;

/**
 *  Request the firmware version for this device. Firmware version is available in property <code>firmwareVersion</code> after <code>firmwareVersionDidUpdate</code> in <code>DevInfoProfileDelegate</code> is called.
 *
 *  @return YES if the device is ready and request succeeded, NO if the device was not ready and the request was not made
 */
- (BOOL)readFirmwareVersion;
/**
 *  Request the hardware version for this device. Hardware version is available in property <code>hardwareVersion</code> after <code>hardwareVersionDidUpdate</code> in <code>DevInfoProfileDelegate</code> is called.
 *
 *  @return YES if the device is ready and request succeeded, NO if the device was not ready and the request was not made
 */
- (BOOL)readHardwareVersion;

@end
