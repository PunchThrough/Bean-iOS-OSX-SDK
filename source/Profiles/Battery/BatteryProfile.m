//
//  BatteryProfile.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/27/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BatteryProfile.h"

@implementation BatteryProfile
{
    CBService* service_battery;
    CBCharacteristic* characteristic_battery_level;
}

#pragma mark Public Methods

-(id)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<BatteryProfileDelegate>)delegate;
{
    self = [super init];
    if (self) {
        //Init Code
        peripheral = aPeripheral;
        _delegate = delegate;
    }
    return self;
}
-(void)readBattery{
    if(peripheral.state == CBPeripheralStateConnected){
        if(characteristic_battery_level){
            [peripheral readValueForCharacteristic:characteristic_battery_level];
        }
    }
}
-(void)validate
{
    // Discover services
    PTDLog(@"Searching for Battery Monitoring service: %@", SERVICE_BATTERY_MONITOR);
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:SERVICE_BATTERY_MONITOR]
                                      , nil]];
    }
}
-(BOOL)isValid:(NSError**)error
{
    return (service_battery &&
            characteristic_battery_level &&
            characteristic_battery_level.isNotifying
            )?TRUE:FALSE;
}

#pragma mark Private Functions
-(void)__processCharacteristics
{
    if(service_battery){
        if(service_battery.characteristics){
            for(CBCharacteristic* characteristic in service_battery.characteristics){
                if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_BATTERY_MONITOR_LEVEL]]){
                    characteristic_battery_level = characteristic;
                }
            }
        }
    }
}

-(NSNumber*)__voltageFromPercentage:(NSNumber*)percentage{
    if([percentage floatValue] <= 0){
        return @(BATTERY_0_PCNT_VOLTAGE);
    }else if([percentage floatValue] >= 100){
        return @(BATTERY_100_PCNT_VOLTAGE);
    }else{
        float delta = (BATTERY_100_PCNT_VOLTAGE - BATTERY_0_PCNT_VOLTAGE) * [percentage floatValue] / 100.0f;
        return @(BATTERY_0_PCNT_VOLTAGE + delta);
    }
}

#pragma mark CBPeripheralDelegate callbacks
-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        if(!(service_battery))
        {
            if(peripheral.services)
            {
                for (CBService * service in peripheral.services) {
                    if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_BATTERY_MONITOR]]) {
                        PTDLog(@"%@: Battery Monitoring profile  found", self.class.description);
                        
                        // Save Dev Info service
                        service_battery = service;
                        
                        //Check if characterisics are already found.
                        [self __processCharacteristics];
                        
                        //If all characteristics are found
                        if(characteristic_battery_level)
                        {
                            PTDLog(@"%@: Found all Battery Monitoring characteristics", self.class.description);
                            //Set Battery Level characteristic to notify
                            [peripheral setNotifyValue:TRUE forCharacteristic:characteristic_battery_level];
                        }else{
                            // Find characteristics of service
                            NSArray * characteristics = [NSArray arrayWithObjects:
                                                         [CBUUID UUIDWithString:CHARACTERISTIC_BATTERY_MONITOR_LEVEL],
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
        if(!(characteristic_battery_level))
        {
            if ([service isEqual:service_battery]) {
                [self __processCharacteristics];
                
                NSError* verificationerror;
                if ((
                     characteristic_battery_level
                     )){
                    PTDLog(@"%@: Found all Battery Monitoring characteristics", self.class.description);
                    
                    //Set Battery Level characteristic to notify
                    [peripheral setNotifyValue:TRUE forCharacteristic:characteristic_battery_level];
                }else {
                    // Could not find all characteristics!
                    PTDLog(@"%@: Could not find all Battery Monitoring characteristics!", self.class.description);
                    
                    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                    [errorDetail setValue:@"Could not find all Battery Monitoring characteristics" forKey:NSLocalizedDescriptionKey];
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
        if(characteristic == characteristic_battery_level){
            UInt8 byte;
            [characteristic.value getBytes:&byte length:1];
            _batteryVoltage = [self __voltageFromPercentage:[NSNumber numberWithInt:byte]];
            PTDLog(@"%@: Battery Level Found: %@ Volts", self.class.description, _batteryVoltage);
            
            if(_delegate){
                if ([self.delegate respondsToSelector:@selector(batteryProfileDidUpdate:)]) {
                    [self.delegate batteryProfileDidUpdate:self];
                }
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(!error){
        if([characteristic isEqual:characteristic_battery_level])
        {
            PTDLog(@"%@: Battery Monitor Characteristic set to \"Notify\"", self.class.description);
            //Alert Delegate that device is connected. At this point, the device should be added to the list of connected devices.
            
            [peripheral readValueForCharacteristic:characteristic_battery_level];
            [self __notifyValidity];
        }
    }else{
        PTDLog(@"%@: Error trying to set Battery Monitor Characteristic to \"Notify\"", self.class.description);
    }
}




@end
