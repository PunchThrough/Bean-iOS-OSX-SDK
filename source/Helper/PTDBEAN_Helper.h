//
//  Helper.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/12/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface PTDBEAN_Helper : NSObject

+(NSNumber*)formatNumberFromString:(NSString*)text WithMaxFractionalDigits:(NSInteger)frac;
+(NSString*)formatStringfromNumber:(NSNumber*)value WithMaxFractionalDigits:(NSInteger)frac;
+(NSData*)hexStringToData:(NSString*)command;

/*
+(const char *) UUIDToString:(CFUUIDRef)UUID;
*/
+(const char *) CBUUIDToString:(CBUUID *) UUID;


+(NSString *) UUIDToNSString:(CFUUIDRef) UUID;

+(NSError *) basicError:(NSString*)description domain:(NSString*)description code:(NSInteger)code;
     
+(UInt16) computeCRC16:(NSData*)data;
+(UInt16) computeCRC16:(NSData*)data startingCRC:(UInt16)startCrc;

+ (NSData*)dummyData:(NSInteger)length;
@end
