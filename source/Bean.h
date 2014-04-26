//
//  BeanDevice.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#define ARDUINO_OAD_GENERIC_TIMEOUT_SEC 6

#define BeanInvalidArgurment @"BeanInvalidArgurment"
#define BeanNotConnected @"BeanNotConnected"

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

#if TARGET_OS_IPHONE
-(void)setLedColor:(UIColor*)color;
#else
-(void)setLedColor:(NSColor*)color;
#endif
-(void)setName:(NSString*)name;
-(void)readAccelerationAxis;
-(void)setAdvertisingInterval:(NSTimeInterval)interval;
@end


@protocol BeanDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)bean:(Bean*)device error:(NSError*)error;
-(void)bean:(Bean*)device receivedMessage:(NSData*)data;
-(void)bean:(Bean*)device didProgramArduinoWithError:(NSError*)error;
-(void)bean:(Bean*)bean serialDataReceived:(NSData*)data;
-(void)bean:(Bean*)bean didUpdateAdvertisingInterval: (NSNumber*) interval_ms;
-(void)bean:(Bean*)bean didUpdatePairingPin:(NSInteger)pinCode;

#if TARGET_OS_IPHONE
-(void)bean:(Bean*)bean didUpdateLedColor:(UIColor*)color;
#else
-(void)bean:(Bean*)bean didUpdateLedColor:(NSColor*)color;
#endif
// TODO : check with ray on CMAcceleration
-(void)bean:(Bean*)bean didUpdateAccelerationXAxis:(double)x yAxis:(double)y zAxis:(double)z;
-(void)bean:(Bean*)bean didUpdateTemperature:(NSNumber*)degrees_celsius;

@end