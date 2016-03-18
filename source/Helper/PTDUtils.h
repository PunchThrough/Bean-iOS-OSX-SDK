#import <Foundation/Foundation.h>

@interface PTDUtils : NSObject

/**
 *  Validate and parse an integer at the start of a string to an integer value.
 *  @param string The string that begins with an integer
 *  @return An NSNumber containing the parsed integer, or nil if the string wasn't a valid integer
 */
+ (NSNumber *)parseLeadingInteger:(NSString *)string;

@end
