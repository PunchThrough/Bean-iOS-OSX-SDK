//
//  GATT_Serial_Packet.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattPacket.h"
#import "BEAN_Helper.h"

@implementation GattPacket

-(id)initWithData:(NSData*)characteristicData error:(NSError**)error {
    if ( self = [super init] ) {
        //Characteristic Data must have at least 2 bytes
        if([characteristicData length]<2)
        {
            *error = [BEAN_Helper basicError:@"Packet length is too small" domain:@"BEAN API:GATT Serial Packet" code:100];
            return nil;
        }
        UInt8 firstbyte;
        [characteristicData getBytes:&firstbyte length:1];
        _startBit = (firstbyte & 0x80)?TRUE:FALSE; // "Start Bit"
        _messageCount = (firstbyte & 0x60)>>5; //Message Count
        _gattPacketDescendingCount = (firstbyte & 0x1F); // GATT Packet Descending Count
        _data = [characteristicData subdataWithRange: NSMakeRange (1, [characteristicData length]-1)]; //data
    }
    return self;
}

-(id)initWithStartBit:(BOOL)startBit messageCount:(NSInteger)messageCount gattPacketDescendingCount:(NSInteger)gattPacketDescendingCount data:(NSData*)data error:(NSError**)error
{
    if ( self = [super init] ) {
        _startBit = startBit;
        _messageCount = messageCount;
        _gattPacketDescendingCount = gattPacketDescendingCount;
        _data = [data copy];
    }
    return self;
}

-(NSData*)bytes
{
    UInt8 header = (_startBit?0x80:0x00) | ((_messageCount<<5)&0x60) | (_gattPacketDescendingCount&0x1F) ;
    NSMutableData* data = [[NSMutableData alloc] initWithBytes:&header length:1];
    [data appendData:_data];
    
    return [data copy];
}

@end
