//
//  CBPeripheral+RSSI_Universal.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/26/15.
//  Copyright (c) 2015 Punch Through Design. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>


@interface CBPeripheral (RSSI_Universal)
- (NSNumber*)RSSI_Universal;
@end
