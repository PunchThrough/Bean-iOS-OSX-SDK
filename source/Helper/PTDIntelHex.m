#import "PTDIntelHex.h"
#import "PTDIntelHexLine.h"

@interface PTDIntelHex ()

/**
 *  The intermediate list of <code>PTDIntelHexLine</code>s.
 *
 *  These are created when Intel HEX is parsed. They're read to generate <code>- (NSData *)bytes</code>.
 */
@property (nonatomic, strong) NSMutableArray *lines;

@end

@implementation PTDIntelHex

+ (PTDIntelHex *)intelHexFromHexString:(NSString *)hexString
{
    return [[PTDIntelHex alloc] initWithHexString:hexString];
}

+ (PTDIntelHex *)intelHexFromFileURL:(NSURL *)file
{
    return [[PTDIntelHex alloc] initWithFileURL:file];
}

- (id)initWithHexString:(NSString *)hexString
{
    self = [super init];
    if (self) {
        _lines = [[NSMutableArray alloc] init];
        if (![self parseHexString:hexString]) {
            return nil;
        }
    }
    return self;
}

- (id)initWithFileURL:(NSURL *)file
{
    self = [super init];
    if (self) {
        _lines = [[NSMutableArray alloc] init];

        NSError *err;
        NSString *fileContents = [NSString stringWithContentsOfFile:file.path encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            return nil;
        }

        if (![self parseHexString:fileContents]) {
            return nil;
        }

        // Set this object's name property to the filename (without .hex extension) of the NSURL file
        _name = [[[file absoluteString] lastPathComponent] componentsSeparatedByString:@"."][0];
    }
    return self;
}

- (NSData *)bytes
{
    NSMutableData *imageData = [[NSMutableData alloc] init];
    
    for (PTDIntelHexLine *line in self.lines) {
        if (line.recordType == PTDIntelHexLineRecordType_Data) {
            [imageData appendData:line.data];
        }
    }
    return [imageData copy];
}

/**
 *  Parse a string of Intel HEX data into the internal <code>self.lines</code> list of Intel HEX lines.
 *  @param hexString the string of Intel HEX to parse
 *  @return YES if parsing succeeded, NO otherwise
 */
- (BOOL)parseHexString:(NSString *)hexString
{
    NSArray *rawlines = [hexString componentsSeparatedByString:@"\n"];
    for (NSString *rawline in rawlines) {
        if (rawline.length >= 11) {
            if (![[rawline substringWithRange:NSMakeRange(0, 1)] isEqual:@":"]) {
                return FALSE;
            }

            PTDIntelHexLine *line = [[PTDIntelHexLine alloc] init];

            // Byte count: offset 1, 2 chars
            line.byteCount = [self numberFromHexString:rawline offset:1 len:2];

            // Address: offset 3, 4 chars
            line.address = [self numberFromHexString:rawline offset:3 len:4];

            // Record type: offset 7, 2 chars
            line.recordType = (PTDIntelHexLineRecordType)[self numberFromHexString:rawline offset:7 len:2];

            // Data: offset 9, (byte count x 2) chars
            line.data = [self bytesFromHexString:rawline offset:9 len:line.byteCount * 2];
            if (!line.data) {
                return FALSE;
            }
            if ([line.data length] != line.byteCount) {
                return FALSE;
            }

            // Checksum: offset (9 + byte count x 2), len 2
            line.checksum = [self numberFromHexString:rawline offset:(9 + (line.byteCount * 2)) len:2];

            [self.lines addObject:line];
        }
    }
    return TRUE;
}

/**
 *  Parse an unsigned integer from a slice of a string containing ASCII hex characters.
 *  @param hexString The string with ASCII hex characters
 *  @param offset The offset of the first character in the slice. 0 starts from the beginning of the string.
 *  @param len The number of characters in the slice
 *  @return The unsigned integer parsed from the slice of hex characters
 */
- (NSUInteger)numberFromHexString:(NSString *)hexString offset:(NSUInteger)offset len:(NSUInteger)len
{
    NSString *sliced = [hexString substringWithRange:NSMakeRange(offset, len)];
    return [self numberFromHexString:sliced];
}

/**
 *  Parse an unsigned integer from a string containing ASCII hex characters.
 *  @param hexString The string with ASCII hex characters
 *  @return The unsigned integer parsed from the hex characters
 */
- (NSUInteger)numberFromHexString:(NSString *)hexString
{
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&result];
    return result;
}

/**
 *  Parse raw bytes from a string containing ASCII hex characters.
 *  @param The string with ASCII hex characters
 *  @param offset The offset of the first character in the slice. 0 starts from the beginning of the string.
 *  @param len The number of characters in the slice
 *  @return An NSData object containing the raw bytes from the hex string
 */
- (NSData *)bytesFromHexString:(NSString *)hexString offset:(NSUInteger)offset len:(NSUInteger)len
{
    NSString *sliced = [hexString substringWithRange:NSMakeRange(offset, len)];
    return [self bytesFromHexString:sliced];
}

/**
 *  Parse raw bytes from a string containing ASCII hex characters.
 *  @param The string with ASCII hex characters
 *  @return An NSData object containing the raw bytes from the hex string
 */
- (NSData *)bytesFromHexString:(NSString *)hexString
{
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i + 2 <= hexString.length; i += 2) {
        NSString *hexByteStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hexByteStr];
        unsigned int intValue;
        if ([scanner scanHexInt:&intValue]) {
            [data appendBytes:&intValue length:1];
        }
    }
    return [data copy];
}

@end
