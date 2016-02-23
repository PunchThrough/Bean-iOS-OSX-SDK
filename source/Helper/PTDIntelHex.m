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
    PTDIntelHex *h = [PTDIntelHex alloc];
    return [h initWithHexString:hexString];
}

+ (PTDIntelHex *)intelHexFromFileURL:(NSURL *)file
{
    PTDIntelHex *h = [PTDIntelHex alloc];
    return [h initWithFileURL:file];
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

- (BOOL)parseHexString:(NSString *)hexString
{
    NSArray *rawlines = [hexString componentsSeparatedByString:@"\n"];
    for (NSString *rawline in rawlines) {
        if (rawline.length >= 11) {
            if (![[rawline substringWithRange:NSMakeRange(0, 1)] isEqual:@":"]) {
                return FALSE;
            }
            
            PTDIntelHexLine *line = [[PTDIntelHexLine alloc] init];
            
            line.byteCount = (UInt8)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(1, 2)]];
            line.address = (UInt16)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(3, 4)]];
            line.recordType = (PTDIntelHexLineRecordType)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(7, 2)]];
            line.data = [self bytesFromHexString:[rawline substringWithRange:NSMakeRange(9, line.byteCount * 2)]];
            line.checksum = (UInt8)[self numberFromHexString:[rawline substringWithRange:NSMakeRange(9 + (line.byteCount * 2), 2)]];
            
            [self.lines addObject:line];
            
            if (!line.data) {
                return FALSE;
            }
            if ([line.data length] != line.byteCount) {
                return FALSE;
            }
        }
    }
    return TRUE;
}

- (unsigned)numberFromHexString:(NSString *)hexString
{
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&result];
    return result;
}

- (NSData *)bytesFromHexString:(NSString *)hexString
{
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i + 2 <= hexString.length; i += 2) {
        NSString *hexByteStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hexByteStr];
        unsigned int intValue;
        if ([scanner scanHexInt:&intValue])
            [data appendBytes:&intValue length:1];
    }
    return [data copy];
}

@end
