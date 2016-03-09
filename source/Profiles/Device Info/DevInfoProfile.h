#import <Foundation/Foundation.h>

#import "BleProfile.h"

#define SERVICE_DEVICE_INFORMATION @"180A"
#define CHARACTERISTIC_HARDWARE_VERSION @"2A27"
#define CHARACTERISTIC_FIRMWARE_VERSION @"2A26"
#define CHARACTERISTIC_SOFTWARE_VERSION @"2A28"

@interface DevInfoProfile : BleProfile <BleProfile>

@property(nonatomic, strong) NSString *firmwareVersion;
@property(nonatomic, strong) NSString *hardwareVersion;

- (void)readFirmwareVersionWithCompletion:(void (^)(void))firmwareVersionCompletion;
- (void)readHardwareVersionWithCompletion:(void (^)(void))hardwareVersionCompletion;

@end
