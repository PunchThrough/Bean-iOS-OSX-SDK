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

#import "PTDBean.h"

@interface BEAN_Helper : NSObject

+(NSNumber*)formatNumberFromString:(NSString*)text WithMaxFractionalDigits:(NSInteger)frac;
+(NSString*)formatStringfromNumber:(NSNumber*)value WithMaxFractionalDigits:(NSInteger)frac;
+(NSData*)hexStringToData:(NSString*)command;

/*
+(const char *) UUIDToString:(CFUUIDRef)UUID;
*/
+(const char *) CBUUIDToString:(CBUUID *) UUID;


+(NSString *) UUIDToNSString:(CFUUIDRef) UUID;

+(NSError *) basicError:(NSString*)description domain:(NSString*)description code:(BeanErrors)code;
     
+(UInt16) computeCRC16:(NSData*)data;
+(UInt16) computeCRC16:(NSData*)data startingCRC:(UInt16)startCrc;

+ (NSData*)dummyData:(NSInteger)length;

/**
 *  Check if a Bean is running out-of-date firmware and should be updated. This method takes into account the firmware
 *  that is available in the client. If Bean has newer firmware than the client, this returns NO.
 *  @param bean The Bean to be inspected for firmware state
 *  @param version The firmware version available in the client. Should be a simple 12-digit datestamp that can be
 *      parsed as an integer, i.e. "201501110000"
 *  @return YES if Bean's firmware is out of date, NO if Bean has equivalent or newer firmware
 */
+ (BOOL)firmwareUpdateRequiredForBean:(PTDBean *)bean availableFirmware:(NSString *)version;

@end
