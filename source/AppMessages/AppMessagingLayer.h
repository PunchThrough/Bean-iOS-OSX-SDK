//
//  AppMessagingLayer.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 3/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GattSerialProfile.h"

@protocol AppMessagingLayerDelegate;

@interface AppMessagingLayer : NSObject <GattSerialProfileDelegate>

@property (nonatomic, weak) id<AppMessagingLayerDelegate> delegate;
@property (nonatomic, weak) GattSerialProfile* gatt_serial_profile;

-(id)initWithGattSerialProfile:(GattSerialProfile*)gattSerialProgile;
-(void)sendMessageWithID:(UInt16)identifier andPayload:(NSData*)payload;

@end



@protocol AppMessagingLayerDelegate <NSObject>

-(void)appMessagingLayer:(AppMessagingLayer*)layer recievedIncomingMessageWithID:(UInt16)identifier andPayload:(NSData*)payload;
-(void)appMessagingLayer:(AppMessagingLayer*)later error:(NSError*)error;

@end