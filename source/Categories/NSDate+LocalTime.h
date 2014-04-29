//
//  NSDate+_LocalTime.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (LocalTime)

+ (NSDate *)localDate;
+ (UInt32)localDateUnixTimeStamp;

@end
