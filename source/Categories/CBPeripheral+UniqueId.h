////
////  CBPeripheral+UniqueId.h
////  BleArduino
////
////  Created by Raymond Kampmeier on 1/2/14.
////  Copyright (c) 2014 Punch Through Design. All rights reserved.
////
//
#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (UniqueId)

- (NSUUID *)uniqueID;
+ (NSUUID *)blankID;
@end
