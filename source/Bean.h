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

@class BeanRadioConfig;
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

typedef struct {
    double x;
    double y;
    double z;
} PTDAcceleration;

typedef enum {
    PTDTxPower_4dB = 0,
    PTDTxPower_0dB,
    PTDTxPower_neg6dB,
    PTDTxPower_neg23dB,
} PTDTxPower_dB;

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

-(void)programArduinoWithRawHexImage:(NSData*)hexImage;
-(void)sendLoopbackDebugMessage:(NSInteger)length;
-(void)sendSerialData:(NSData*)data;
-(void)sendSerialString:(NSString*)string;
-(void)readAccelerationAxis;
#if TARGET_OS_IPHONE
-(void)setLedColor:(UIColor*)color;
#else
-(void)setLedColor:(NSColor*)color;
#endif
-(void)readLedColor;
-(void)setScratchNumber:(UInt8)scratchNumber withValue:(NSData*)value;
-(void)readScratchBank:(UInt8)bank;
-(void)readTemperature;
-(void)setPairingPin:(UInt16)pinCode;
-(void)readRadioConfig;
-(void)setRadioConfig:(BeanRadioConfig*)config;
@end

@protocol BeanDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)bean:(Bean*)device error:(NSError*)error;
-(void)bean:(Bean*)device receivedMessage:(NSData*)data;
-(void)bean:(Bean*)device didProgramArduinoWithError:(NSError*)error;
-(void)bean:(Bean*)bean serialDataReceived:(NSData*)data;
-(void)bean:(Bean*)bean didUpdateAdvertisingInterval: (NSNumber*) interval_ms;
-(void)bean:(Bean*)bean didUpdatePairingPin:(UInt16)pinCode;
#if TARGET_OS_IPHONE
-(void)bean:(Bean*)bean didUpdateLedColor:(UIColor*)color;
#else
-(void)bean:(Bean*)bean didUpdateLedColor:(NSColor*)color;
#endif
-(void)bean:(Bean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration;
-(void)bean:(Bean*)bean didUpdateTemperature:(NSNumber*)degrees_celsius;
-(void)bean:(Bean*)bean didUpdateLoopbackPayload:(NSData*)payload;
-(void)bean:(Bean*)bean didUpdateRadioConfig:(BeanRadioConfig*)config;
@end