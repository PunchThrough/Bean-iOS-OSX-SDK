//
//  GATT_Transport.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattTransport.h"


@implementation GattTransport
{
}

#pragma mark Public Methods
-(id)initWithCharacteristicHandler:(id<GattCharacteristicHandler>)handler;
{
    if ( self = [super init] ) {
        _characteristicHandler = handler;
    }
    return self;
}

-(void)sendPacket:(GattPacket*)packet error:(NSError**)error
{
    //Send data over BLE
    if(_characteristicHandler)
    {
        [_characteristicHandler user:self hasDataForTransmission:[packet bytes] error:error];
    }
}

-(void)handler:(id<GattCharacteristicHandler>)handler hasTransmittedDataWithError:(NSError*)error
{
    
}
-(void)handler:(id<GattCharacteristicHandler>)handler hasReceivedData:(NSData*)data
{
    NSError* error;
    GattPacket * packet = [[GattPacket alloc] initWithData:data error:&error];
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
