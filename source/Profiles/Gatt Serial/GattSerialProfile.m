//
//  GattSerialPeripheral.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialProfile.h"

@interface GattSerialProfile () <GattSerialTransportDelegate, GattCharacteristicHandler>
@end

@implementation GattSerialProfile
{
    CBService* serial_pass_service;
    CBCharacteristic* serial_pass_characteristic;
    
    GattTransport * gatt_transport;
    GattSerialTransport* gatt_serial_transport;
}


#pragma mark Public Methods
-(id)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<GattSerialProfileDelegate>)delegate
{
    self = [super init];
    if (self) {
        peripheral = aPeripheral;
        _delegate = delegate;
        
        //Initialize Gatt Transport layer
        gatt_transport = [[GattTransport alloc] initWithCharacteristicHandler:self];
        if(!gatt_transport) return nil;
        
        //Initialize Gatt Serial Transport layer
        gatt_serial_transport = [[GattSerialTransport alloc] initWithGattTransport:gatt_transport];
        if(!gatt_serial_transport) return nil;
        gatt_serial_transport.delegate = self;
        
        //Assign GattTransport layer's delegate to the serial transport layer
        gatt_transport.delegate = gatt_serial_transport;
        
    }
    return self;
}
-(void)validate
{
    // Discover services
    PTDLog(@"Searching for Gatt Serial Pass service: %@", GLOBAL_SERIAL_PASS_SERVICE_UUID);
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_SERVICE_UUID]
                                      , nil]];
    }
}
-(BOOL)isValid:(NSError**)error
{
    BOOL valid = (serial_pass_characteristic &&
                  serial_pass_characteristic.isNotifying
                  )?TRUE:FALSE;
    return valid;
}

-(void)sendMessage:(GattSerialMessage*)message
{
    [gatt_serial_transport sendMessage:message];
}

#pragma mark Private Functions
-(void)__processCharacteristics
{
    if(serial_pass_service){
        if(serial_pass_service.characteristics){
            for(CBCharacteristic* characteristic in serial_pass_service.characteristics){
                if([characteristic.UUID isEqual:[CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_CHARACTERISTIC_UUID]]){
                    serial_pass_characteristic = characteristic;
                }
            }
        }
    }
}


#pragma mark - GattSerialTransportDelegate callbacks
-(void)GattSerialTransport_error:(NSError*)error
{
    if (self.delegate)
    {
        if([self.delegate respondsToSelector:@selector(gattSerialProfile:error:)])
        {
            [self.delegate gattSerialProfile:self error:error];
        }
    }
}
-(void)GattSerialTransport_messageReceived:(GattSerialMessage*)message
{
    if (self.delegate)
    {
        if([self.delegate respondsToSelector:@selector(gattSerialProfile:recievedIncomingMessage:)])
        {
            [self.delegate gattSerialProfile:self recievedIncomingMessage:message];
        }
    }
}

#pragma mark - TxRxCharacteristicUser callbacks
-(void)user:(id<GattCharacteristicObserver>)user hasDataForTransmission:(NSData*)data error:(NSError**)error
{
    if(!peripheral){
        if(error) *error = [BEAN_Helper basicError:@"Peripheral is not connected" domain:@"BEAN API:GATT Serial Profile" code:BeanErrors_NotConnected];
        return;
    }
    if(peripheral.state != CBPeripheralStateConnected){
        if(error) *error = [BEAN_Helper basicError:@"Peripheral is not connected" domain:@"BEAN API:GATT Serial Profile" code:BeanErrors_NotConnected];
        return;
    }
    
    [peripheral writeValue:data forCharacteristic:serial_pass_characteristic type:CBCharacteristicWriteWithoutResponse];
   // PTDLog(@"Packet Written to Serial Pass Characteristic: %@", data);

}

#pragma mark CBPeripheralDelegate callbacks
////////////////  CBPeripheralDeligate Callbacks ////////////////////////////
-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        if(peripheral.services)
        {
            // Discover characteristics of found services
            for (CBService * service in peripheral.services) {
                // Save Gatt Serail service
                if ([service.UUID isEqual:[CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_SERVICE_UUID]]) {
                    PTDLog(@"%@: GATT Serial Pass profile  found", self.class.description);
                    
                    // Save serial pass service
                    serial_pass_service = service;
                    
                    //Check if characterisics are already found.
                    [self __processCharacteristics];
                    
                    //If all characteristics are found
                    if(serial_pass_characteristic)
                    {
                        PTDLog(@"%@: Found all Gatt Serial characteristics", self.class.description);
                        if(serial_pass_characteristic.isNotifying){
                            [self __notifyValidity];
                        }else{
                            //Set characteristic to notify
                            [peripheral setNotifyValue:YES forCharacteristic:serial_pass_characteristic];
                            //Wait until the notification characteristic is registered successfully as "notify" and then alert delegate that device is valid
                        }
                    }else{
                        // Find characteristics of service
                        NSArray * characteristics = [NSArray arrayWithObjects:
                                                     [CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_CHARACTERISTIC_UUID],
                                                     nil];
                        [peripheral discoverCharacteristics:characteristics forService:service];
                    }
                }
            }
        }
    }else {
        PTDLog(@"%@: GATT Serial Pass service discovery was unsuccessful", self.class.description);
        
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service isEqual:serial_pass_service]) {
            [self __processCharacteristics];
            
            NSError* verificationerror;
            if ((
                 serial_pass_characteristic
                 )){
                PTDLog(@"%@: Found all GATT Serial Pass characteristics", self.class.description);
                
                if(serial_pass_characteristic.isNotifying){
                    [self __notifyValidity];
                }else{
                    //Set characteristic to notify
                    [peripheral setNotifyValue:YES forCharacteristic:serial_pass_characteristic];
                    //Wait until the notification characteristic is registered successfully as "notify" and then alert delegate that device is valid
                }
            }else{
                // Could not find all characteristics!
                PTDLog(@"%@: Could not find all GATT Serial Pass characteristics!", self.class.description);
                
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Could not find all GATT Serial Pass characteristics" forKey:NSLocalizedDescriptionKey];
                verificationerror = [NSError errorWithDomain:@"Bluetooth" code:100 userInfo:errorDetail];
            }
            //Alert Delegate
        }
    }
    else {
        PTDLog(@"%@: Characteristics discovery was unsuccessful", self.class.description);
        //Alert Delegate
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        if ([characteristic isEqual:serial_pass_characteristic]) {
            [gatt_transport handler:self hasReceivedData:[characteristic value]];
        }
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //Is the serial pass characteristic
    if([characteristic isEqual:serial_pass_characteristic])
    {
        if (error) {
            // Dropping writeWithoutReponse packets. Stop the firmware upload and notify the delegate
             PTDLog(@"%@: Error: Dropping writeWithoutReponse packets!!", self.class.description);
        }else{

        }
    }
}

- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(!error)
    {
        if([characteristic isEqual:serial_pass_characteristic])
        {
            PTDLog(@"%@: Gatt Serial Characteristic set to \"Notify\"", self.class.description);
            //Alert Delegate that device is connected. At this point, the device should be added to the list of connected devices.
            
            [self __notifyValidity];
        }
    }else{
        PTDLog(@"%@: Error trying to set Characteristic to \"Notify\"", self.class.description);
    }
}


@end
