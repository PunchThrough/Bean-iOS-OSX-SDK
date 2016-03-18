//
//  PTDBleDevice+Protected.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 8/14/15.
//  Copyright (c) 2015 Punch Through Design. All rights reserved.
//


#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "PTDBleDevice.h"

@interface PTDBleDevice (Protected)

-(CBPeripheral*)peripheral;

-(void)setState:(BeanState)state;
-(void)setRSSI:(NSNumber*)rssi;
-(void)setAdvertisementData:(NSDictionary*)adData;
-(void)setLastDiscovered:(NSDate*)date;


@end