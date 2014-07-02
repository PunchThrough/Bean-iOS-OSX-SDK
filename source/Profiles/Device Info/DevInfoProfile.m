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
}

#pragma mark Public Methods

-(id)initWithPeripheral:(CBPeripheral*)aPeripheral
{
    self = [super init];
    if (self) {
        //Init Code
        peripheral = aPeripheral;
    }
    return self;
}
-(void)validate
{
    // Discover services
    PTDLog(@"Searching for Device Information service: %@", SERVICE_DEVICE_INFORMATION);
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:SERVICE_DEVICE_INFORMATION]
                                      , nil]];
    }
}
-(BOOL)isValid:(NSError**)error
{
    return (service_deviceInformation &&
            characteristic_hardware_version &&
            characteristic_firmware_version &&
            characteristic_software_version &&
            _firmwareVersion)?TRUE:FALSE;
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
-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        if(!(service_deviceInformation))
        {
            if(peripheral.services)
            {
                for (CBService * service in peripheral.services) {
                    if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_DEVICE_INFORMATION]]) {
                        PTDLog(@"%@: Device Information profile  found", self.class.description);
                        
                        // Save Dev Info service
                        service_deviceInformation = service;

                        //Check if characterisics are already found.
                        [self __processCharacteristics];
                        
                        //If all characteristics are found
                        if(characteristic_hardware_version &&
                             characteristic_firmware_version &&
                             characteristic_software_version)
                        {
                            PTDLog(@"%@: Found all Device Information characteristics", self.class.description);
                            [peripheral readValueForCharacteristic:characteristic_firmware_version];
                        }else{
                            // Find characteristics of service
                            NSArray * characteristics = [NSArray arrayWithObjects:
                                                         [CBUUID UUIDWithString:CHARACTERISTIC_HARDWARE_VERSION],
                                                         [CBUUID UUIDWithString:CHARACTERISTIC_FIRMWARE_VERSION],
                                                         [CBUUID UUIDWithString:CHARACTERISTIC_SOFTWARE_VERSION],
                                                         nil];
                            [peripheral discoverCharacteristics:characteristics forService:service];
                        }
                    }
                }
            }
        }
    }else {
        PTDLog(@"%@: Service discovery was unsuccessful", self.class.description);
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if(!(characteristic_hardware_version &&
             characteristic_firmware_version &&
             characteristic_software_version))
        {
            if ([service isEqual:service_deviceInformation]) {
                [self __processCharacteristics];
                
                NSError* verificationerror;
                if ((
                     characteristic_hardware_version &&
                     characteristic_firmware_version &&
                     characteristic_software_version
                     )){
                    PTDLog(@"%@: Found all Device Information characteristics", self.class.description);
                    
                    //Read device firmware version
                    [peripheral readValueForCharacteristic:characteristic_firmware_version];
                    
                }else {
                    // Could not find all characteristics!
                    PTDLog(@"%@: Could not find all Device Information characteristics!", self.class.description);
                    
                    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                    [errorDetail setValue:@"Could not find all Device Information characteristics" forKey:NSLocalizedDescriptionKey];
                    verificationerror = [NSError errorWithDomain:@"Bluetooth" code:100 userInfo:errorDetail];
                }
                //Alert Delegate
            }
        }
    }
    else {
        PTDLog(@"%@: Characteristics discovery was unsuccessful", self.class.description);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        if(characteristic == characteristic_firmware_version){
            PTDLog(@"%@: Device Firmware Version Found", self.class.description);
            _firmwareVersion = [[NSString alloc] initWithData:[characteristic value] encoding:NSUTF8StringEncoding];
            [self __notifyValidity];
        }
    }
}


@end
