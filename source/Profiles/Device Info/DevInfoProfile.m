//
//  BLEDevice.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 8/16/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//

#import "DevInfoProfile.h"


@implementation DevInfoProfile
{
    CBService* service_deviceInformation;
    CBCharacteristic* characteristic_hardware_version;
    CBCharacteristic* characteristic_firmware_version;
    CBCharacteristic* characteristic_software_version;
    NSOperationQueue* firmwareVersionQueue;
}

+(void)load
{
    [super registerProfile:self serviceUUID:SERVICE_DEVICE_INFORMATION];
}

#pragma mark Public Methods

-(id)initWithService:(CBService*)service
{
    self = [super init];
    if (self) {
        //Init Code`
        service_deviceInformation = service;
        peripheral = service.peripheral;
        firmwareVersionQueue = [[NSOperationQueue alloc] init];
        firmwareVersionQueue.suspended = YES;
    }
    return self;
}

-(void)validate
{
    // Find characteristics of service
    NSArray * characteristics = [NSArray arrayWithObjects:
                                 [CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION],
                                 //[CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION],
                                 //[CBUUID UUIDWithString:CHARACTERISTIC_SOFTWARE_VERSION],
                                 nil];
    [peripheral discoverCharacteristics:characteristics forService:service_deviceInformation];
    [self __notifyValidity];
}

-(BOOL)isValid:(NSError**)error
{
    return (service_deviceInformation &&
            //characteristic_hardware_version &&
            characteristic_firmware_version &&
            //characteristic_software_version &&
            _firmwareVersion)?TRUE:FALSE;
}

-(void)readFirmwareVersionWithCompletion:(void (^)(void))firmwareVersionCompletion
{
    [firmwareVersionQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            firmwareVersionCompletion();
        }];
    }];
}

-(NSString*)firmwareVersion
{
    if (_firmwareVersion)
        return _firmwareVersion;
    PTDLog(@"firmwareVersion call blocking.");
    // Wait until firmware version is available
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{}];
    [firmwareVersionQueue addOperations:@[op] waitUntilFinished: YES];
    return _firmwareVersion;
}

#pragma mark Private Functions
-(void)__processCharacteristics
{
    if(service_deviceInformation){
        if(service_deviceInformation.characteristics){
            for(CBCharacteristic* characteristic in service_deviceInformation.characteristics){
                if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION]]){
                    characteristic_hardware_version = characteristic;
                }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION]]){
                    characteristic_firmware_version = characteristic;
                }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_SOFTWARE_VERSION]]){
                    characteristic_software_version = characteristic;
                }
            }
        }
    }
}

#pragma mark CBPeripheralDelegate callbacks

-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if( error ){
        PTDLog(@"%@: Characteristics discovery was unsuccessful", self.class.description);
        return;
    }
    
    // Do we already have all of our characteristics?
    if(characteristic_hardware_version &&
         characteristic_firmware_version &&
         characteristic_software_version)
    { return; }
    
    // Is this not the service we're interested in?
    if( ![service isEqual:service_deviceInformation] ) { return; }
    
    [self __processCharacteristics];
    
    if(characteristic_firmware_version == nil) {
        // Could not find all characteristics!
        PTDLog(@"%@: Could not find all Device Information characteristics!", self.class.description);
        return;
    }

    PTDLog(@"%@: Found all Device Information characteristics", self.class.description);
    //Read device firmware version
    [peripheral readValueForCharacteristic:characteristic_firmware_version];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if( error ) { return; }
    // Is this not the characteristic that we're interested in?
    if(![characteristic isEqual:characteristic_firmware_version]) { return; }
    
    _firmwareVersion = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
    PTDLog(@"%@: Device Firmware Version Found: %@", self.class.description, _firmwareVersion);
    firmwareVersionQueue.suspended = NO;
}


@end
