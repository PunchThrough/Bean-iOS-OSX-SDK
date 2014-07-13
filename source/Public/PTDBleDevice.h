//
//  BleDevice.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 6/24/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface PTDBleDevice : NSObject <CBPeripheralDelegate>{
    CBPeripheral*               _peripheral;
    NSArray*                    _profiles;
    NSNumber*                   _RSSI;
    NSDictionary*               _advertisementData;
    NSDate*                     _lastDiscovered;
}


-(id)initWithPeripheral:(CBPeripheral*)peripheral;
-(void)interrogateAndValidate;
-(BOOL)requiredProfilesAreValid;

@end
