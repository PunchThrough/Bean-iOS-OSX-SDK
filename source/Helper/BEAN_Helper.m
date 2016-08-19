/*

    WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

    This file is CURSED.
    Stuff in here still works, but this file is known to cause problems with Xcode autocomplete.
    Don't waste your time trying to fix autocomplete.

    Consider this file DEPRECATED. Don't put new work into this file.
    If you need to add helper methods, add them to or another helper class.

    WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

*/

#import "BEAN_Helper.h"

@implementation BEAN_Helper

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
    PTDLog(@"Hex to data: %@", commandToSend);

    return commandToSend;
}

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


+(NSError *) basicError:(NSString*)description domain:(NSString*)domain code:(BeanErrors)code
{
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:description forKey:NSLocalizedDescriptionKey];
    NSError* error = [NSError errorWithDomain:domain code:code userInfo:errorDetail];
    PTDLog(@"Error: %@ %@", error, [error userInfo]);
    return error;
}

+(UInt16) computeCRC16:(NSData*)data
{
    return [BEAN_Helper computeCRC16:data startingCRC:0xFFFF];
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
