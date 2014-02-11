//
//  GATT_Transport.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "BEAN_Helper.h"
#import "GattPacket.h"


#define GLOBAL_BEAN_SERVICE_UUID                      @"FF10"
#define GLOBAL_BEAN_CHARACTERISTIC_UUID               @"FF11"

@protocol GattTransportDelegate;

@interface GattTransport : NSObject

@property (nonatomic, weak) id<GattTransportDelegate> delegate;

-(id)initWithPeripheral:(CBPeripheral*)cbperipheral characteristic:(CBCharacteristic*)cbcharacteristic;
-(void)sendPacket:(GattPacket*)packet error:(NSError**)error;
-(void)packetDataRecieved:(NSData*)packetData;
@end

#pragma mark - GattTransportDelegate
@protocol GattTransportDelegate <NSObject>

@optional
-(void)GattTransport_error:(NSError*)error;
-(void)GattTransport_packetReceived:(GattPacket*)packet;
@end