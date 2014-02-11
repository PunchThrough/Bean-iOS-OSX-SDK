//
//  GATT_Mutable_Serial_Message.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialMessage.h"

@interface GattSerialMessageRxAssembler : NSObject

-(GattSerialMessage*)processPacket:(GattPacket*)packet error:(NSError**)error;

@end
