#import "DevInfoProfile.h"

@interface DevInfoProfile ()

@property (nonatomic, strong) CBService *service_deviceInformation;
@property (nonatomic, strong) CBCharacteristic *characteristic_firmware_version;
@property (nonatomic, strong) CBCharacteristic *characteristic_hardware_version;

@end

@implementation DevInfoProfile

@dynamic delegate;  // Delegate is already synthesized by BleProfile

+ (void)load
{
    [super registerProfile:self serviceUUID:SERVICE_DEVICE_INFORMATION];
}

#pragma mark Public Methods

- (id)initWithService:(CBService *)service
{
    self = [super init];
    if (!self) return nil;

    self.service_deviceInformation = service;
    peripheral = service.peripheral;

    return self;
}

- (void)validate
{
    NSArray *characteristics = @[[CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION],
                                 [CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION]];
    [peripheral discoverCharacteristics:characteristics forService:self.service_deviceInformation];
    [self __notifyValidity];
}

- (BOOL)isValid:(NSError **)error
{
    return (self.service_deviceInformation &&
            self.characteristic_hardware_version &&
            self.characteristic_firmware_version &&
            self.firmwareVersion &&
            self.hardwareVersion);
}

- (BOOL)readHardwareVersion
{
    if (!self.characteristic_hardware_version) return NO;

    [peripheral readValueForCharacteristic:self.characteristic_hardware_version];
    return YES;
}

- (BOOL)readFirmwareVersion
{
    if (!self.characteristic_firmware_version) return NO;

    [peripheral readValueForCharacteristic:self.characteristic_firmware_version];
    return YES;
}

#pragma mark Private Methods

/**
 *  Process the characteristics discovered and store the relevant ones into local variables for future use.
 */
- (void)__processCharacteristics
{
    if (!self.service_deviceInformation) return;
    if (!self.service_deviceInformation.characteristics) return;

    for (CBCharacteristic *characteristic in self.service_deviceInformation.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION]]) {
            self.characteristic_hardware_version = characteristic;
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION]]) {
            self.characteristic_firmware_version = characteristic;
        }
    }
}

#pragma mark CBPeripheralDelegate callbacks

- (void)peripheral:(CBPeripheral *)aPeripheral
    didDiscoverCharacteristicsForService:(CBService *)service
                                   error:(NSError *)error
{
    if (![service isEqual:self.service_deviceInformation]) return;
 
    if (error) {
        PTDLog(@"%@: Discovery of Device Information characteristics was unsuccessful", self.class.description);
        return;
    }
    [self __processCharacteristics];

    if (!self.characteristic_hardware_version) {
        PTDLog(@"%@: Did not find Hardware Version characteristic", self.class.description);
        return;
    };
    if (!self.characteristic_firmware_version) {
        PTDLog(@"%@: Did not find Firmware Version characteristic", self.class.description);
        return;
    };

    PTDLog(@"%@: Found all Device Information characteristics", self.class.description);
    [self readHardwareVersion];
    [self readFirmwareVersion];
}

- (void)peripheral:(CBPeripheral *)peripheral
    didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
                              error:(NSError *)error
{
    if (error) {
        if ([characteristic isEqual:self.characteristic_hardware_version]) {
            PTDLog(@"Warning: Couldn't read data for Device Info Profile -> Hardware Version. "
                   @"This is typically seen when Beans are running an OAD update-only (recovery) image. "
                   @"You can safely ignore this warning if Bean is in the middle of a firmware update. "
                   @"Error: %@",
                   error);

        } else {
            PTDLog(@"Error reading characteristic: %@, %@", characteristic.UUID, error);
        }
        
        return;
    }
    
    NSString *charValue = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];

    if ([characteristic isEqual:self.characteristic_firmware_version]) {
        self.firmwareVersion = charValue;
        PTDLog(@"%@: Device Firmware Version Found: %@", self.class.description, self.firmwareVersion);
        if (self.delegate && [self.delegate respondsToSelector:@selector(firmwareVersionDidUpdate)]) {
            [self.delegate firmwareVersionDidUpdate];
        }

    } else if ([characteristic isEqual:self.characteristic_hardware_version]) {
        self.hardwareVersion = charValue;
        PTDLog(@"%@: Device Hardware Version Found: %@", self.class.description, self.hardwareVersion);
        if (self.delegate && [self.delegate respondsToSelector:@selector(hardwareVersionDidUpdate)]) {
            [self.delegate hardwareVersionDidUpdate];
        }
    }
}

@end
