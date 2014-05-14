//
//  AppMessagingLayer.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 3/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "AppMessagingLayer.h"

@implementation AppMessagingLayer

-(id)initWithGattSerialProfile:(GattSerialProfile*)gattSerialProgile{
    self = [super init];
    if (self) {
        _gatt_serial_profile = gattSerialProgile;
    }
    return self;
}

- (void)sendMessageWithID:(UInt16)identifier andPayload:(NSData *)payload{
    UInt8 messageIdBytes[] = {(UInt8)((identifier>>8)&0xFF),(UInt8)((identifier)&0xFF)};
    NSMutableData* data = [[NSMutableData alloc] initWithBytes:messageIdBytes length:2];
    if(payload)[data appendData:payload];
    
    GattSerialMessage* message = [[GattSerialMessage alloc] initWithPayload:data error:nil];
    [_gatt_serial_profile sendMessage:message];
}

#pragma mark gattSerialDevideDelegate callbacks
-(void)gattSerialProfile:(GattSerialProfile*)profile recievedIncomingMessage:(GattSerialMessage*)message{
    //PTDLog(@"Gatt Serial Message Received: %@",[message bytes]);
    
    UInt8 messageIdBytes[2];
    [[message payload] getBytes:messageIdBytes length:2];
    UInt16 messageId = (messageIdBytes[0]<<8) + messageIdBytes[1];
    
    NSData* payload = [[message payload] subdataWithRange:NSMakeRange(2, [message payload].length-2)];
    
    if(_delegate){
        if([_delegate respondsToSelector:@selector(appMessagingLayer:recievedIncomingMessageWithID:andPayload:)]){
            [_delegate appMessagingLayer:self recievedIncomingMessageWithID:messageId andPayload:payload];
        }
    }
}

-(void)gattSerialProfile:(GattSerialProfile*)profile error:(NSError*)error{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(appMessagingLayer:error:)]){
            [_delegate appMessagingLayer:self error:error];
        }
    }
}


@end
