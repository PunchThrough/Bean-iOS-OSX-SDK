//
//  Helper.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/12/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBEAN_Helper.h"

@implementation PTDBEAN_Helper

+(NSNumber*)formatNumberFromString:(NSString*)text WithMaxFractionalDigits:(NSInteger)frac{
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setMaximumFractionDigits:frac];
    NSNumber * n = [f numberFromString:[f stringFromNumber:[f numberFromString:text]]];
    if(n)
        return n;
    else
        return nil;
}

+(NSString*)formatStringfromNumber:(NSNumber*)value WithMaxFractionalDigits:(NSInteger)frac{
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    [f setMaximumFractionDigits:frac];
    NSString * n = [f stringFromNumber:value];
    if(n)
        return n;
    else
        return nil;
}

+(NSData*)hexStringToData:(NSString*)command
{
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [command length]/2; i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    NSLog(@"Hex to data: %@", commandToSend);
    
    return commandToSend;
}

/*
+(const char *) UUIDToString:(CFUUIDRef)UUID
{
    if (!UUID) return "NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    return CFStringGetCStringPtr(s, 0);
    
}
 */
+(const char *) CBUUIDToString:(CBUUID *) UUID
{
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}


+(const char *) UUIDToString:(CFUUIDRef)UUID
{
    if (!UUID) return "NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    const char *r = CFStringGetCStringPtr(s, 0);
    CFRelease(s);
    return r;
}
    
+(NSString *) UUIDToNSString:(CFUUIDRef) UUID
{
    return [NSString stringWithFormat:@"%s", [self UUIDToString:UUID]];
}


+(NSError *) basicError:(NSString*)description domain:(NSString*)domain code:(NSInteger)code
{
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:description forKey:NSLocalizedDescriptionKey];
    NSError* error = [NSError errorWithDomain:domain code:code userInfo:errorDetail];
    NSLog(@"Error: %@ %@", error, [error userInfo]);
    return error;
}

+(UInt16) computeCRC16:(NSData*)data
{
    return [PTDBEAN_Helper computeCRC16:data startingCRC:0xFFFF];
}

+(UInt16) computeCRC16:(NSData*)data startingCRC:(UInt16)startCrc;
{
    UInt16 crc =  startCrc;
    
    for (int i = 0; i < [data length]; i++)
    {
        UInt8 byte;
        [data getBytes:&byte range:NSMakeRange(i, 1)];
        crc = (UInt8)(crc >> 8) | (crc << 8);
        crc ^= byte;
        crc ^= (UInt8)(crc & 0xff) >> 4;
        crc ^= (crc << 8) << 4;
        crc ^= ((crc & 0xff) << 4) << 1;
    }
    
    return crc;
}

+ (NSData*)dummyData:(NSInteger)length
{
    NSMutableData* data = [NSMutableData data];
    for(UInt8 i=0;i<length;i++)
    {
        [data appendBytes:&i length:1];
    }
    return [data copy];
}

@end


/*
@interface CBUUID (StringExtraction)

- (NSString *)representativeString;

@end

@implementation CBUUID (StringExtraction)

- (NSString *)representativeString;
{
    NSData *data = [self data];
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return outputString;
}
 
@end
 */