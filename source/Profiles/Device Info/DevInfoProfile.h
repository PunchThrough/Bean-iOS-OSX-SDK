//
//  BLEDevice.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 8/16/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BleProfile.h"

#define SERVICE_DEVICE_INFORMATION @"180A"
#define CHARACTERISTIC_HARDWARE_VERSION @"2A27"
#define CHARACTERISTIC_FIRMWARE_VERSION @"2A26"
#define CHARACTERISTIC_SOFTWARE_VERSION @"2A28"


@interface DevInfoProfile : BleProfile

@property (nonatomic, strong) NSString *firmwareVersion;

-(id)initWithPeripheral:(CBPeripheral*)peripheral;

@end

