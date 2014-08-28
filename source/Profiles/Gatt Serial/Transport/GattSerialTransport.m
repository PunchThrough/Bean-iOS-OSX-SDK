//
//  GATT_SerialTransport.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/12/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialTransport.h"

@implementation GattSerialTransport
{
    __weak GattTransport * gattTransport;
    GattSerialMessageRxAssembler * messageAssembler;
    
    //Outgoing message variables
    NSMutableArray* gattPacketTxQueue;
    BOOL gattPacketTxClearToSend;
    NSInteger outgoingMessageCount; //Two bit counter
    NSTimer* bufferUnloadTimer;
}

#pragma mark Public Methods
-(id)initWithGattTransport:(GattTransport*)transport
{
    if(!transport)return nil;
    if ( self = [super init] ) {
        gattTransport = transport;
        
        messageAssembler = [[GattSerialMessageRxAssembler alloc] init];
        if(!messageAssembler) return nil;
        
        outgoingMessageCount = 0;
        gattPacketTxClearToSend = TRUE;
        gattPacketTxQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)sendMessage:(GattSerialMessage*)message
{
    //If there is no data to send in this message, do nothing
    if(!message) return;
    [gattPacketTxQueue addObjectsFromArray:[self __packetsFromMessage:message]];
    [bufferUnloadTimer invalidate];
    bufferUnloadTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(__unloadOutgoingQueue) userInfo:nil repeats:YES];
}

#pragma mark Private Methods
- (void)__unloadOutgoingQueue
{
    //If we have not heard back from the previous write request, Exit and wait for next attempt
    if(gattPacketTxClearToSend == FALSE) return;
    
    //Send Packet
    NSError* error;
    if(gattTransport && gattPacketTxQueue && [gattPacketTxQueue count] != 0)
    {
        [gattTransport sendPacket:[gattPacketTxQueue objectAtIndex:0] error:&error];
    }else{
        [bufferUnloadTimer invalidate];
        return;
    }
    
    if(error)
    {
        if (self.delegate)
        {
            if([self.delegate respondsToSelector:@selector(GattSerialTransport_error:)])
            {
                [self.delegate GattSerialTransport_error:error];
            }
        }
        if(error.code == BeanErrors_NotConnected){
            //Bean is disconnected, clear the outgoing buffer and stop retrying 
            gattPacketTxQueue = [[NSMutableArray alloc] init];
        }
        return;
    }else{
        //Unload successfully sent packet
        [gattPacketTxQueue removeObjectAtIndex:0];
    }
    
    //If there are no messages, invalidate timer and return
    if([gattPacketTxQueue count] == 0)
    {
        [bufferUnloadTimer invalidate];
        return;
    }
}
     
 -(NSArray*)__packetsFromMessage:(GattSerialMessage*)message
{
    NSMutableArray* packets = [[NSMutableArray alloc] init];
    NSData* messageData = [message bytes];
    
    NSInteger gattPacketDescendingCount = [GattSerialMessage packetCountFromDataLength:[messageData length] packetSize:PACKET_TX_MAX_PAYLOAD_LENGTH];
    for(int i=0; i<[messageData length]; i+=PACKET_TX_MAX_PAYLOAD_LENGTH)
    {
        BOOL startBit = FALSE;
        if(i==0)//First Packet
        {
            startBit = TRUE;
            outgoingMessageCount = (outgoingMessageCount+1)%4; //Two bit counter
        }
        
        unsigned long packetDataSize = ((i + PACKET_TX_MAX_PAYLOAD_LENGTH)<[messageData length]) ? PACKET_TX_MAX_PAYLOAD_LENGTH : ([messageData length] - i);
        NSData* packetData = [messageData subdataWithRange:NSMakeRange (i, packetDataSize)];
        
        NSError* error;
        [packets addObject:[[GattPacket alloc] initWithStartBit:startBit messageCount:outgoingMessageCount gattPacketDescendingCount:gattPacketDescendingCount data:packetData error:&error]];
        
        gattPacketDescendingCount--; // The last packet should have a value of 0 for this
    }
    return [packets copy];
}

#pragma mark GattTransportDelegate callback
-(void)GattTransport_error:(NSError*)error
{
    if(error)
    {
        if (self.delegate)
        {
            if([self.delegate respondsToSelector:@selector(GattSerialTransport_error:)])
            {
                [self.delegate GattSerialTransport_error:error];
            }
        }
        return;
    }
}
-(void)GattTransport_packetReceived:(GattPacket*)packet
{
    NSError* error;
    GattSerialMessage * message = [messageAssembler processPacket:packet error:&error];
    
    if(error)
    {
        if (self.delegate)
        {
            if([self.delegate respondsToSelector:@selector(GattSerialTransport_error:)])
            {
                [self.delegate GattSerialTransport_error:error];
            }
        }
        return;
    }
    
    if(message) // A message has been completed. Return it :D
    {
        if (self.delegate)
        {
            if([self.delegate respondsToSelector:@selector(GattSerialTransport_messageReceived:)])
            {
                [self.delegate GattSerialTransport_messageReceived:message];
            }
        }
    }
}

@end
