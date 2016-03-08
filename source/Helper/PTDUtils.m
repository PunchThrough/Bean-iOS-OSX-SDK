#import "PTDUtils.h"

@implementation PTDUtils

// http://stackoverflow.com/a/11588643
+ (NSNumber *)parseLeadingInteger:(NSString *)string
{
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    NSInteger parsed;
    if (![scanner scanInteger:&parsed]) return nil;
    return [NSNumber numberWithInteger:parsed];
}

@end
