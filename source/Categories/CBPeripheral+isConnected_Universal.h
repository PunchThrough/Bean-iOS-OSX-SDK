//
//  CBPeripheral+isConnected_iOS567.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 4/30/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif


@interface CBPeripheral (isConnected_Universal)
- (BOOL)isConnected_Universal;
@end
