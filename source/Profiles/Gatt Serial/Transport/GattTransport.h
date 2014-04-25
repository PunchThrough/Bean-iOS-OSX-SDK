//
//  GATT_Transport.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif
#import "BEAN_Helper.h"
#import "GattPacket.h"
#import "GattCharacteristicHandler.h"
#import "GattCharacteristicObserver.h"


#define GLOBAL_BEAN_SERVICE_UUID                      @"FF10"
#define GLOBAL_BEAN_CHARACTERISTIC_UUID               @"FF11"

@protocol GattTransportDelegate;

@interface GattTransport : NSObject <GattCharacteristicObserver>

@property (nonatomic, weak) id<GattTransportDelegate> delegate;
@property (nonatomic, weak) id<GattCharacteristicHandler> characteristicHandler;

-(id)initWithCharacteristicHandler:(id<GattCharacteristicHandler>)handler;
-(void)sendPacket:(GattPacket*)packet error:(NSError**)error;
@end


#pragma mark - GattTransportDelegate
@protocol GattTransportDelegate <NSObject>

@optional
-(void)GattTransport_error:(NSError*)error;
-(void)GattTransport_packetReceived:(GattPacket*)packet;

@end
