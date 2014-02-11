//
//  CBPeripheral+UniqueId.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/2/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface CBPeripheral (UniqueId)

- (NSUUID *)uniqueID;
+ (NSUUID *)blankID;
@end
