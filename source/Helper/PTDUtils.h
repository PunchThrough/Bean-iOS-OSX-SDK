#import <Foundation/Foundation.h>

@interface PTDUtils : NSObject

/**
 *  Validate and parse a string to an integer value.
 *  @param string The string to be parsed as an integer
 *  @return An NSNumber containing the parsed integer, or nil if the string wasn't a valid integer
 */
+ (NSNumber *)parseInteger:(NSString *)string;

@end
