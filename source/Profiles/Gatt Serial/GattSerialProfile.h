//
//  GattSerialPeripheral.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "OadProfile.h"
#import "BEAN_Globals.h"
#import "GattSerialTransport.h"
#import "Profile_Protocol.h"

#define GLOBAL_SERIAL_PASS_SERVICE_UUID                    PUNCHTHROUGHDESIGN_128_UUID(@"FF10")
#define GLOBAL_SERIAL_PASS_CHARACTERISTIC_UUID             PUNCHTHROUGHDESIGN_128_UUID(@"FF11")

@protocol GattSerialDeviceDelegate;

@interface GattSerialProfile : NSObject <Profile_Protocol>

@property (nonatomic, weak) id<GattSerialDeviceDelegate, ProfileDelegate_Protocol> delegate;

-(id)initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<GattSerialDeviceDelegate, ProfileDelegate_Protocol>)delegate;

-(void)sendMessage:(GattSerialMessage*)message;

@end


@protocol GattSerialDeviceDelegate <NSObject>

@optional
-(void)gattSerialDevice:(GattSerialProfile*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)gattSerialDevice:(GattSerialProfile*)device error:(NSError*)error;
@end


