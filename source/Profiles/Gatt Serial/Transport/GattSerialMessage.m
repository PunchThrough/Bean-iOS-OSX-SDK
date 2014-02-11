//
//  GATT_Serial_Message.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialMessage.h"
#import "BEAN_Helper.h"

@implementation GattSerialMessage

-(id)initWithData:(NSData*)data error:(NSError**)error
{
    if ( self = [super init] ) {
        //data must have at least 6 bytes
        if([data length]<6)
        {
            *error = [BEAN_Helper basicError:@"Message length is too small" domain:@"BEAN API:GATT Serial Message" code:100];
            return nil;
        }
        
        UInt8 header[4];
        UInt8 footer[2];
        
        [data getBytes:&header length:4];
        [data getBytes:&footer range:NSMakeRange([data length]-2, 2)];
        
        _messageTypeID = header[0];
        _payloadLength = (((UInt16)header[2])<<8) + header[1];
        _reserved = header[3];
        _payload = [data subdataWithRange: NSMakeRange (4, [data length]-6)]; //data
        _crc = (((UInt16)footer[1])<<8) + footer[0];
        
        
        UInt16 calculatedCrc = [BEAN_Helper computeCRC16:[data subdataWithRange:NSMakeRange(0, [data length]-2)]];
        if(calculatedCrc != _crc)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"CRC check failed" forKey:NSLocalizedDescriptionKey];
            [errorDetail setValue:self forKey:@"GattSerialMessage"];
            *error = [NSError errorWithDomain:@"BEAN API:GATT Serial Message" code:100 userInfo:errorDetail];
            NSLog(@"Error: %@ %@", *error, [*error userInfo]);
            return nil;
        }
    }
    return self;
}

-(id)initWithMessageTypeID:(UInt8)messageTypeID payload:(NSData*)payload error:(NSError**)error
{
    if ( self = [super init] ) {
        _messageTypeID = messageTypeID;
        _payloadLength = [payload length];
        _reserved = 0;
        _payload = [payload copy];
        
        UInt16 headercrc = [BEAN_Helper computeCRC16:[self __getHeaderData]];
        _crc = [BEAN_Helper computeCRC16:payload startingCRC:headercrc];
    }
    return self;
}

-(NSData*)bytes
{
    NSMutableData* data = [[NSMutableData alloc] initWithData:[self __getHeaderData]];
    [data appendData:_payload];
    
    UInt8 footer[2];
    footer[0] = (UInt8)(_crc | 0xFF);
    footer[1] = (UInt8)((_crc >> 8) | 0xFF);
    
    [data appendBytes:footer length:2];
    
    return [data copy];
}

+(NSInteger)packetCountFromDataLength:(NSInteger)datalength packetSize:(NSInteger)packetsize
{
    return (datalength / packetsize) - ((datalength % packetsize == 0) ? 1 : 0);
}

-(NSData*)__getHeaderData
{
    UInt8 bytes[4];
    
    bytes[0] = _messageTypeID;
    bytes[1] = (UInt8)(_payloadLength | 0xFF);
    bytes[2] = (UInt8)((_payloadLength >> 8) | 0xFF);
    bytes[3] = _reserved;
    
    return [NSData dataWithBytes:bytes length:4];
}


@end
