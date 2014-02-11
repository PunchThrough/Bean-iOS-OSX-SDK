//
//  BeanDevice.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "GattSerialProfile.h"

@protocol BeanDeviceDelegate;

@interface BeanDevice : NSObject

@property (nonatomic, assign) id<BeanDeviceDelegate> delegate;

-(id)initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<BeanDeviceDelegate>)delegate;
-(BOOL)isValid:(NSError**)error;

@end


@protocol BeanDeviceDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)beanDevice:(BeanDevice*)device error:(NSError*)error;
-(void)beanDeviceIsValid:(BeanDevice*)device;
@end