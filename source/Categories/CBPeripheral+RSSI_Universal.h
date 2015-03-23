//
//  CBPeripheral+RSSI_Universal.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/26/15.
//  Copyright (c) 2015 Punch Through Design. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif


@interface CBPeripheral (RSSI_Universal)
- (NSNumber*)RSSI_Universal;
@end
