//
//  BeanDevice.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <IOBluetooth/IOBluetooth.h>

#define ARDUINO_OAD_GENERIC_TIMEOUT_SEC 6

@class BeanManager;
@protocol BeanDelegate;

typedef enum { //These occur in sequence
    BeanState_Unknown = 0,
    BeanState_Discovered,
    BeanState_AttemptingConnection,
    BeanState_AttemptingValidation,
    BeanState_ConnectedAndValidated,
    BeanState_AttemptingDisconnection
} BeanState;


@interface Bean : NSObject

@property (nonatomic, weak) id<BeanDelegate> delegate;

//-(void)sendMessage:(GattSerialMessage*)message;

-(NSUUID*)identifier;
-(NSString*)name;
-(NSNumber*)RSSI;
-(BeanState)state;
-(NSDictionary*)advertisementData;
-(NSDate*)lastDiscovered;
-(BeanManager*)beanManager;

-(void)sendLoopbackDebugMessage:(NSInteger)length;
-(void)sendSerialMessage:(NSData*)data;
-(void)programArduinoWithRawHexImage:(NSData*)hexImage;
-(void)setLedColor:(NSColor*)color;

@end


@protocol BeanDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)bean:(Bean*)device error:(NSError*)error;
-(void)bean:(Bean*)device receivedMessage:(NSData*)data;
-(void)bean:(Bean*)device didProgramArduinoWithError:(NSError*)error;
@end