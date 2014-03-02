//
//  BeanDevice.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialProfile.h"

@protocol BeanDelegate;

@interface Bean : NSObject

@property (nonatomic, assign) id<BeanDelegate> delegate;
@property (nonatomic, assign, readonly) NSUUID* identifier;

-(id)initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<BeanDelegate>)delegate;

-(BOOL)isValid:(NSError**)error;

-(void)sendMessage:(GattSerialMessage*)message;

@end


@protocol BeanDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)bean:(Bean*)device error:(NSError*)error;

-(void)beanIsValid:(Bean*)device error:(NSError*)error;

-(void)bean:(Bean*)device receivedMessage:(NSData*)data;

@end