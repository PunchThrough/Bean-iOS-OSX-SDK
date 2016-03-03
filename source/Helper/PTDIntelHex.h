#import <Foundation/Foundation.h>

@interface PTDIntelHex : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *beanHardwareVersion;

/**
 *  Create a PTDIntelHex object from a string of Intel HEX data.
 */
+ (PTDIntelHex *)intelHexFromHexString:(NSString *)hexString;

/**
 *  Create a PTDIntelHex object from a file that contains Intel HEX data.
 */
+ (PTDIntelHex *)intelHexFromFileURL:(NSURL *)file;

/**
 *  Initialize a PTDIntelHex object from an Intel HEX string.
 */
- (id)initWithHexString:(NSString *)hexString;

/**
 *  Initialize a PTDIntelHex object from a file that contains Intel HEX data.
 */
- (id)initWithFileURL:(NSURL *)file;

/**
 *  The bytes of raw data parsed from the original Intel HEX source data.
 */
- (NSData *)bytes;

@end

