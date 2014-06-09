//
//  BatteryProfile.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/27/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BleProfile.h"

#define SERVICE_BATTERY_MONITOR @"180F"
#define CHARACTERISTIC_BATTERY_MONITOR_LEVEL @"2A19"

#define BATTERY_0_PCNT_VOLTAGE      2.0f
#define BATTERY_100_PCNT_VOLTAGE    3.75f

@protocol BatteryProfileDelegate;

@interface BatteryProfile : BleProfile

@property (nonatomic, weak) id<BatteryProfileDelegate> delegate;
@property (nonatomic, strong) NSNumber *batteryVoltage; // Voltage

-(id)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<BatteryProfileDelegate>)delegate;
-(void)readBattery;

@end




@protocol BatteryProfileDelegate <NSObject>

@optional

-(void)batteryProfileDidUpdate:(BatteryProfile*)profile;


@end