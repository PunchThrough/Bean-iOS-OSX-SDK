#import <Foundation/Foundation.h>

@interface PTDIntelHex : NSObject

/**
 *  The name of the sketch this hex was compiled from. Used by Bean Loaders to set the name of Bean's sketch.
 */
@property (nonatomic, strong) NSString *name;
/**
 *  The version prefix of the hardware this sketch is intended for.
 *  For example, "1" = Bean, "2" = Bean+.
 */
@property (nonatomic, strong) NSString *beanHardwareVersion;

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

