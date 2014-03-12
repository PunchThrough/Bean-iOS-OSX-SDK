//
//  GATT_Mutable_Serial_Message.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/15/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialMessageRxAssembler.h"
#import "GattSerialMessage.h"

@implementation GattSerialMessageRxAssembler
{
    NSMutableData* payload;
    NSInteger messageIndex;
    NSInteger gattPacketIndex;
    BOOL firstMessage;
}

-(id)init
{
    if ( self = [super init] ) {
        payload = [[NSMutableData alloc] init];
        firstMessage = TRUE;
    }
    return self;
}

-(GattSerialMessage*)processPacket:(GattPacket*)packet error:(NSError**)error
{
    //Check if this is the first packet
    if(packet.startBit==TRUE)
    {
        if(firstMessage)
        {
            firstMessage = FALSE;
        }//Check if Message Count matches expected. Every full message coming in should increment this count (2 bit count, 0,1,2,3,0,1,2,...)
        else if([packet messageCount] != ((++messageIndex)%4))
        {
            *error = [BEAN_Helper basicError:@"Message Count is out of Sequence" domain:@"BEAN API:GATT Serial Message Assembler" code:100];
            //This is a more minor error. Shouldn't return;
        }
        messageIndex = [packet messageCount]; // All preceeding packets in this message should have the same message count
        gattPacketIndex = [packet gattPacketDescendingCount];
    }else{
        
        //Check if Message Count matches expected
        if([packet messageCount] != messageIndex)
        {
            *error = [BEAN_Helper basicError:@"Message Count Discrepancy" domain:@"BEAN API:GATT Serial Message Assembler" code:100];
            return nil;
        }
        
        //Decrement packet counter
        gattPacketIndex--;
        
        //Check if Packet Descending Count matches expected
        if([packet gattPacketDescendingCount] != gattPacketIndex)
        {
            *error = [BEAN_Helper basicError:@"GATT Packet Descending Count Discrepancy" domain:@"BEAN API:GATT Serial Message Assembler" code:100];
            return nil;
        }
    }
    
    /*Possible Cases:
     1. There is a start packet, and no payload data
     2. There is a non-start packet, and partial payload data
     3. There is a start packet, and partial payload data (Error)
     4. There is a non-start packet, and no payload data (Error)
     */
    BOOL partialMessage = (payload && [payload length] > 0)?TRUE:FALSE;
    if(packet.startBit==TRUE && !(partialMessage)) //Case 1
    {
        payload = [[NSMutableData alloc] initWithData:[packet data]];
    }else if(packet.startBit==FALSE && partialMessage) //Case 2
    {
        [payload appendData:[packet data]];
    }else if(packet.startBit==TRUE && partialMessage) //Case 3
    {
        *error = [BEAN_Helper basicError:@"Received a Start packet when a previous message wasn't finished" domain:@"BEAN API:GATT Serial Message Assembler" code:100];
        return nil;
    }else if(packet.startBit==FALSE && !(partialMessage)) //Case 4
    {
        *error = [BEAN_Helper basicError:@"Received a non-Start packet, with no prior message data " domain:@"BEAN API:GATT Serial Message Assembler" code:100];
        return nil;
    }
    
    //Check if this was the last packet in a message
    if([packet gattPacketDescendingCount] == 0) // gattPacketIndex should inherently be 0 as well from logic above
    {
        GattSerialMessage* message = [[GattSerialMessage alloc] initWithData:payload error:error];
        if(*error) return nil;
        //Return the Message
        payload = [[NSMutableData alloc] init];
        return message;
    }
    return nil;
}

@end
