#import "ScratchProfile.h"


@interface ScratchProfile ()

@property (nonatomic, strong) CBService *service_scratch;
@property (nonatomic, strong) CBCharacteristic *characteristic_bank1;
@property (nonatomic, strong) CBCharacteristic *characteristic_bank2;
@property (nonatomic, strong) CBCharacteristic *characteristic_bank3;
@property (nonatomic, strong) CBCharacteristic *characteristic_bank4;
@property (nonatomic, strong) CBCharacteristic *characteristic_bank5;

@end


@implementation ScratchProfile

@dynamic delegate;  // Delegate is already synthesized by BleProfile

+ (void)load
{
    [super registerProfile:self serviceUUID:BEAN_SCRATCH_SERVICE_UUID];
}

- (id)initWithService:(CBService *)service
{
    self = [super init];
    if (!self) return nil;
    
    self.service_scratch = service;
    peripheral = service.peripheral;
    
    return self;
}

- (void)validate
{
    NSArray *characteristics = @[[CBUUID UUIDWithString:BEAN_SCRATCH_BANK1_CHARACTERISTIC_UUID],
                                 [CBUUID UUIDWithString:BEAN_SCRATCH_BANK2_CHARACTERISTIC_UUID],
                                 [CBUUID UUIDWithString:BEAN_SCRATCH_BANK3_CHARACTERISTIC_UUID],
                                 [CBUUID UUIDWithString:BEAN_SCRATCH_BANK4_CHARACTERISTIC_UUID],
                                 [CBUUID UUIDWithString:BEAN_SCRATCH_BANK5_CHARACTERISTIC_UUID]];
    [peripheral discoverCharacteristics:characteristics forService:self.service_scratch];
    [self __notifyValidity];
}

- (BOOL)isValid:(NSError **)error
{
    return (self.service_scratch &&
            self.characteristic_bank1 &&
            self.characteristic_bank2 &&
            self.characteristic_bank3 &&
            self.characteristic_bank4 &&
            self.characteristic_bank5
            );
}


- (BOOL)readScratchBank:(NSInteger)bank {
    switch (bank) {
    case 1:
        if (!self.characteristic_bank1) return NO;
        [peripheral readValueForCharacteristic:self.characteristic_bank1];
        break;
    case 2:
        if (!self.characteristic_bank2) return NO;
        [peripheral readValueForCharacteristic:self.characteristic_bank2];
        break;
    case 3:
        if (!self.characteristic_bank3) return NO;
        [peripheral readValueForCharacteristic:self.characteristic_bank3];
        break;
    case 4:
        if (!self.characteristic_bank4) return NO;
        [peripheral readValueForCharacteristic:self.characteristic_bank4];
        break;
    case 5:
        if (!self.characteristic_bank5) return NO;
        [peripheral readValueForCharacteristic:self.characteristic_bank5];
        break;
    default:
        return NO;
    }
    return YES;
}

#pragma mark Private Methods

/**
 *  Process the characteristics discovered and store the relevant ones into local variables for future use.
 */
- (void)__processCharacteristics
{
    if (!self.service_scratch) return;
    if (!self.service_scratch.characteristics) return;
    
    for (CBCharacteristic *characteristic in self.service_scratch.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BEAN_SCRATCH_BANK1_CHARACTERISTIC_UUID]]) {
            self.characteristic_bank1 = characteristic;
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BEAN_SCRATCH_BANK2_CHARACTERISTIC_UUID]]) {
            self.characteristic_bank2 = characteristic;
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BEAN_SCRATCH_BANK3_CHARACTERISTIC_UUID]]) {
            self.characteristic_bank3 = characteristic;
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BEAN_SCRATCH_BANK4_CHARACTERISTIC_UUID]]) {
            self.characteristic_bank4 = characteristic;
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BEAN_SCRATCH_BANK5_CHARACTERISTIC_UUID]]) {
            self.characteristic_bank5 = characteristic;
        }
    }
}


#pragma mark CBPeripheralDelegate callbacks

- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (![service isEqual:self.service_scratch]) return;
    
    if (error) {
        PTDLog(@"%@: Discovery of Device Information characteristics was unsuccessful", self.class.description);
        return;
    }
    [self __processCharacteristics];
    
    if (!self.characteristic_bank1) {
        PTDLog(@"%@: Did not find Scratch Bank 1 characteristic", self.class.description);
        return;
    };
    if (!self.characteristic_bank2) {
        PTDLog(@"%@: Did not find Scratch Bank 2 characteristic", self.class.description);
        return;
    };
    if (!self.characteristic_bank3) {
        PTDLog(@"%@: Did not find Scratch Bank 3 characteristic", self.class.description);
        return;
    };
    if (!self.characteristic_bank4) {
        PTDLog(@"%@: Did not find Scratch Bank 4 characteristic", self.class.description);
        return;
    };
    if (!self.characteristic_bank5) {
        PTDLog(@"%@: Did not find Scratch Bank 5 characteristic", self.class.description);
        return;
    };
    
    PTDLog(@"%@: Found all Scratch characteristics", self.class.description);
    
    [peripheral setNotifyValue:TRUE forCharacteristic:self.characteristic_bank1];
    [peripheral setNotifyValue:TRUE forCharacteristic:self.characteristic_bank2];
    [peripheral setNotifyValue:TRUE forCharacteristic:self.characteristic_bank3];
    [peripheral setNotifyValue:TRUE forCharacteristic:self.characteristic_bank4];
    [peripheral setNotifyValue:TRUE forCharacteristic:self.characteristic_bank5];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        PTDLog(@"Error reading characteristic: %@, %@", characteristic.UUID, error);
        return;
    }
    
    if ([characteristic isEqual:self.characteristic_bank1]) {
        self.scratchBank1 = characteristic.value;
        PTDLog(@"%@: Scratch Bank 1 updated", self.class.description);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateScratchBank:data:)]) {
            [self.delegate didUpdateScratchBank:1 data:self.scratchBank1];
        }
        
    } else if ([characteristic isEqual:self.characteristic_bank2]) {
        self.scratchBank2 = characteristic.value;
        PTDLog(@"%@: Scratch Bank 2 updated", self.class.description);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateScratchBank:data:)]) {
            [self.delegate didUpdateScratchBank:2 data:self.scratchBank1];
        }
        
    } else if ([characteristic isEqual:self.characteristic_bank3]) {
        self.scratchBank3 = characteristic.value;
        PTDLog(@"%@: Scratch Bank 3 updated", self.class.description);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateScratchBank:data:)]) {
            [self.delegate didUpdateScratchBank:3 data:self.scratchBank1];
        }
        
    } else if ([characteristic isEqual:self.characteristic_bank4]) {
        self.scratchBank4 = characteristic.value;
        PTDLog(@"%@: Scratch Bank 4 updated", self.class.description);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateScratchBank:data:)]) {
            [self.delegate didUpdateScratchBank:4 data:self.scratchBank1];
        }
        
    } else if ([characteristic isEqual:self.characteristic_bank5]) {
        self.scratchBank5 = characteristic.value;
        PTDLog(@"%@: Scratch Bank 5 updated", self.class.description);
        if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateScratchBank:data:)]) {
            [self.delegate didUpdateScratchBank:5 data:self.scratchBank1];
        }
    }
}

- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    int bank = 0;
    
    if ([characteristic isEqual:self.characteristic_bank1]) {
        bank = 1;
    } else if ([characteristic isEqual:self.characteristic_bank2]) {
        bank = 2;
    } else if ([characteristic isEqual:self.characteristic_bank3]) {
        bank = 3;
    } else if ([characteristic isEqual:self.characteristic_bank4]) {
        bank = 4;
    } else if ([characteristic isEqual:self.characteristic_bank5]) {
        bank = 5;
    }
    
    if (error) {
        PTDLog(@"%@: Error trying to set Scratch Bank %d Characteristic to \"Notify\"", self.class.description, bank);
        return;
    }
    
    PTDLog(@"%@: Scratch Bank %d Characteristic set to \"Notify\"", self.class.description, bank);
    
    [peripheral readValueForCharacteristic:characteristic];
}

@end
