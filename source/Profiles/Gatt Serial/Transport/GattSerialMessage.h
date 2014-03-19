//
//  GATT_Serial_Message.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BEAN_Helper.h"
#import "GattPacket.h"

@interface GattSerialMessage : NSObject
{
    @protected UInt8 _payloadLength;
    @protected UInt8 _reserved;
    @protected NSData *_payload;
    @protected UInt16 _crc;
}

@property (readonly, nonatomic) UInt8 payloadLength;
@property (readonly, nonatomic) UInt8 reserved;
@property (readonly, nonatomic, strong) NSData * payload;
@property (readonly, nonatomic) UInt16 crc; //CRC value for entire message

-(id)initWithData:(NSData*)data error:(NSError**)error;
-(id)initWithPayload:(NSData*)payload error:(NSError**)error;

-(NSData*)bytes;

+(NSInteger)packetCountFromDataLength:(NSInteger)datalength packetSize:(NSInteger)packetsize;
@end