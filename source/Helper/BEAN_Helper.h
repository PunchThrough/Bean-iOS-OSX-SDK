/*

    WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

    This file is CURSED.
    Stuff in here still works, but this file is known to cause problems with Xcode autocomplete.
    Don't waste your time trying to fix autocomplete.

    Consider this file DEPRECATED. Don't put new work into this file.
    If you need to add helper methods, add them to or another helper class.

    WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

*/

#import <Foundation/Foundation.h>
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "PTDBean.h"

@interface BEAN_Helper : NSObject

+(NSNumber*)formatNumberFromString:(NSString*)text WithMaxFractionalDigits:(NSInteger)frac;
+(NSString*)formatStringfromNumber:(NSNumber*)value WithMaxFractionalDigits:(NSInteger)frac;
+(NSData*)hexStringToData:(NSString*)command;

+(const char *) CBUUIDToString:(CBUUID *) UUID;


+(NSString *) UUIDToNSString:(CFUUIDRef) UUID;

+(NSError *) basicError:(NSString*)description domain:(NSString*)description code:(BeanErrors)code;

+(UInt16) computeCRC16:(NSData*)data;
+(UInt16) computeCRC16:(NSData*)data startingCRC:(UInt16)startCrc;

+ (NSData*)dummyData:(NSInteger)length;

@end
