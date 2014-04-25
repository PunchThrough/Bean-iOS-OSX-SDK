//
//  GATT_SerialTransport.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/12/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "BEAN_Helper.h"

#import "GattTransport.h"
#import "GattPacket.h"
#import "GattSerialMessageRxAssembler.h"
#import "GattSerialMessage.h"

@protocol GattSerialTransportDelegate;

@interface GattSerialTransport : NSObject <GattTransportDelegate>

@property (nonatomic, weak) id<GattSerialTransportDelegate> delegate;

-(id)initWithGattTransport:(GattTransport*)transport;
-(void)sendMessage:(GattSerialMessage*)message;

@end


#pragma mark - GattSerialTransportDelegate
@protocol GattSerialTransportDelegate <NSObject>

@optional
-(void)GattSerialTransport_error:(NSError*)error;
-(void)GattSerialTransport_messageReceived:(GattSerialMessage*)message;
@end


