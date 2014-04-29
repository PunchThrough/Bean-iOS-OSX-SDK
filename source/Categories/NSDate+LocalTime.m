//
//  NSDate+_LocalTime.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "NSDate+LocalTime.h"

@implementation NSDate (LocalTime)

+ (NSDate *)localDate{
    NSDate* sourceDate = [NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    return [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
}
+ (UInt32)localDateUnixTimeStamp{
    return [[NSDate localDate] timeIntervalSince1970];
}
@end
