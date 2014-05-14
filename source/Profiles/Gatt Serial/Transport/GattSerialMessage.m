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
        //data must have at least 4 bytes
        if([data length]<4)
        {
            if(error) *error = [BEAN_Helper basicError:@"Message is an invalid length: Too small" domain:@"BEAN API:GATT Serial Message" code:100];
            return nil;
        }
        
        UInt8 header[2];
        UInt8 footer[2];
        
        [data getBytes:&header length:2];
        [data getBytes:&footer range:NSMakeRange([data length]-2, 2)];
        
        _payloadLength = header[0];
        _reserved = header[1];
        _payload = [data subdataWithRange: NSMakeRange (2, [data length]-4)]; //data
        _crc = (((UInt16)footer[1])<<8) + footer[0];
        
        
        UInt16 calculatedCrc = [BEAN_Helper computeCRC16:[data subdataWithRange:NSMakeRange(0, [data length]-2)]];
        if(calculatedCrc != _crc)
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"CRC check failed" forKey:NSLocalizedDescriptionKey];
            [errorDetail setValue:self forKey:@"GattSerialMessage"];
            NSError* local_error = [NSError errorWithDomain:@"BEAN API:GATT Serial Message" code:100 userInfo:errorDetail];
            PTDLog(@"Error: %@ %@", local_error, [local_error userInfo]);
            if(error) *error = local_error;
            return nil;
        }
    }
    return self;
}

-(id)initWithPayload:(NSData*)payload error:(NSError**)error
{
    if ( self = [super init] ) {
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
    [data appendData:[self __getFooterData]];
    
    return [data copy];
}

+(NSInteger)packetCountFromDataLength:(NSInteger)datalength packetSize:(NSInteger)packetsize
{
    return (datalength / packetsize) - ((datalength % packetsize == 0) ? 1 : 0);
}

-(NSData*)__getHeaderData
{
    UInt8 bytes[2];
    bytes[0] = (UInt8)_payloadLength;
    bytes[1] = _reserved;
    
    return [NSData dataWithBytes:bytes length:2];
}

-(NSData*)__getFooterData
{
    UInt8 bytes[2];
    bytes[0] = (UInt8)(_crc & 0xFF);
    bytes[1] = (UInt8)((_crc >> 8) & 0xFF);
    
    return [NSData dataWithBytes:bytes length:2];
}

@end
