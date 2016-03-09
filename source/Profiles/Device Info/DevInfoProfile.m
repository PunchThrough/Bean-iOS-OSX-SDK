#import "DevInfoProfile.h"

@interface DevInfoProfile ()

@property (nonatomic, strong) void (^firmwareVersionCompletion)(void);
@property (nonatomic, strong) void (^hardwareVersionCompletion)(void);
@property (nonatomic, strong) CBService *service_deviceInformation;
@property (nonatomic, strong) CBCharacteristic *characteristic_firmware_version;
@property (nonatomic, strong) CBCharacteristic *characteristic_hardware_version;
@property (nonatomic, strong) NSOperationQueue *firmwareVersionQueue;
@property (nonatomic, strong) NSOperationQueue *hardwareVersionQueue;

@end

@implementation DevInfoProfile

+ (void)load
{
    [super registerProfile:self serviceUUID:SERVICE_DEVICE_INFORMATION];
}

#pragma mark Public Methods

- (id)initWithService:(CBService *)service
{
    self = [super init];
    if (!self) return nil;

    self.firmwareVersionQueue = [[NSOperationQueue alloc] init];
    self.hardwareVersionQueue = [[NSOperationQueue alloc] init];
    self.firmwareVersionQueue.suspended = YES;
    self.hardwareVersionQueue.suspended = YES;
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

- (void)readFirmwareVersionWithCompletion:(void (^)(void))firmwareVersionCompletion
{
    [self.firmwareVersionQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            firmwareVersionCompletion();
        }];
    }];
}

- (void)readHardwareVersionWithCompletion:(void (^)(void))hardwareVersionCompletion
{
    [self.hardwareVersionQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            hardwareVersionCompletion();
        }];
    }];
}

- (NSString *)firmwareVersion
{
    if (self.firmwareVersion) return self.firmwareVersion;

    // Wait until firmware version is available
    PTDLog(@"firmwareVersion call blocking.");
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{}];
    [self.firmwareVersionQueue addOperations:@[ op ] waitUntilFinished:YES];
    
    return self.firmwareVersion;
}

- (NSString *)hardwareVersion
{
    if (self.hardwareVersion) return self.hardwareVersion;

    // Wait until hardware version is available
    PTDLog(@"hardwareVersion call blocking.");
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{}];
    [self.hardwareVersionQueue addOperations:@[ op ] waitUntilFinished:YES];
    
    return _hardwareVersion;
}

#pragma mark Private Functions
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
    if (error) {
        PTDLog(@"%@: Discovery of Device Information characteristics was unsuccessful", self.class.description);
        return;
    }
    if (!self.characteristic_hardware_version) return;
    if (!self.characteristic_firmware_version) return;
    if (![service isEqual:self.service_deviceInformation]) return;

    [self __processCharacteristics];

    PTDLog(@"%@: Found all Device Information characteristics", self.class.description);
    [peripheral readValueForCharacteristic:self.characteristic_firmware_version];
    [peripheral readValueForCharacteristic:self.characteristic_hardware_version];
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

    if ([characteristic isEqual:self.characteristic_firmware_version]) {
        self.firmwareVersion = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
        PTDLog(@"%@: Device Firmware Version Found: %@", self.class.description, self.firmwareVersion);
        self.firmwareVersionQueue.suspended = NO;

    } else if ([characteristic isEqual:self.characteristic_hardware_version]) {
        self.hardwareVersion = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
        PTDLog(@"%@: Device Hardware Version Found: %@", self.class.description, self.hardwareVersion);
        self.hardwareVersionQueue.suspended = NO;
    }
}

@end
