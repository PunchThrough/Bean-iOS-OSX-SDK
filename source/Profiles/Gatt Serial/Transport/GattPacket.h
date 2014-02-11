//
//  GATT_Serial_Packet.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PACKET_TX_MAX_PAYLOAD_LENGTH 19
@interface GattPacket : NSObject

@property (nonatomic) BOOL startBit;
@property (nonatomic) NSInteger messageCount;
@property (nonatomic) NSInteger gattPacketDescendingCount;
@property (nonatomic, strong) NSData * data;

-(id)initWithData:(NSData*)characteristicData error:(NSError**)error;
-(id)initWithStartBit:(BOOL)startBit messageCount:(NSInteger)messageCount gattPacketDescendingCount:(NSInteger)gattPacketDescendingCount data:(NSData*)data error:(NSError**)error;
-(NSData*)bytes;

@end
