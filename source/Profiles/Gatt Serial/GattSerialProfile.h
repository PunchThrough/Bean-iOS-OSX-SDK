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

@protocol GattSerialProfileDelegate;

@interface GattSerialProfile : NSObject <Profile_Protocol>

@property (nonatomic, weak) id<GattSerialProfileDelegate> delegate;
@property (nonatomic, weak) id<ProfileDelegate_Protocol> profileDelegate;

-(id)initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<GattSerialProfileDelegate>)delegate;

-(void)sendMessage:(GattSerialMessage*)message;

@end


@protocol GattSerialProfileDelegate <NSObject>

@optional
-(void)gattSerialProfile:(GattSerialProfile*)profile recievedIncomingMessage:(GattSerialMessage*)message;
-(void)gattSerialProfile:(GattSerialProfile*)profile error:(NSError*)error;
@end


