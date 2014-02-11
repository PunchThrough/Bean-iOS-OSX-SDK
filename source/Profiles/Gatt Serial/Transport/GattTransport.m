//
//  GATT_Transport.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattTransport.h"

@interface GattTransport () <CBPeripheralDelegate>
@end

@implementation GattTransport
{
    __weak CBPeripheral * peripheral;
    __weak CBCharacteristic * serialCharacteristic;
}

#pragma mark Public Methods
-(id)initWithPeripheral:(CBPeripheral*)cbperipheral characteristic:(CBCharacteristic*)cbcharacteristic;
{
    if ( self = [super init] ) {
        peripheral = cbperipheral;
        serialCharacteristic = cbcharacteristic;
    }
    return self;
}

-(void)sendPacket:(GattPacket*)packet error:(NSError**)error
{
    //Send data over BLE
    if(peripheral && serialCharacteristic)
    {
        [peripheral writeValue:[packet bytes] forCharacteristic:serialCharacteristic type:CBCharacteristicWriteWithoutResponse];
        NSLog(@"Writing Data: %@", packet );
    }
}

-(void)packetDataRecieved:(NSData*)packetData
{
    NSError* error;
    GattPacket * packet = [[GattPacket alloc] initWithData:packetData error:&error];
    if(!packet || error)
    {
        if (self.delegate)
        {
            if([self.delegate respondsToSelector:@selector(GattTransport_error:)])
            {
                [self.delegate GattTransport_error:error];
            }
        }
        return;
    }
    
    if (self.delegate)
    {
        if([self.delegate respondsToSelector:@selector(GattTransport_packetReceived:)])
        {
            [self.delegate GattTransport_packetReceived:packet];
        }
    }
}



@end
