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
@property (nonatomic, strong) NSDate *dateProgrammed;
@property (nonatomic, strong) NSString *sketchName;

//-(void)sendMessage:(GattSerialMessage*)message;

-(NSUUID*)identifier;
-(NSString*)name;
-(NSNumber*)RSSI;
-(BeanState)state;
-(NSDictionary*)advertisementData;
-(NSDate*)lastDiscovered;
-(NSString*)firmwareVersion;
-(BeanManager*)beanManager;

-(void)readArduinoSketchInfo;
-(void)programArduinoWithRawHexImage:(NSData*)hexImage andImageName:(NSString*)name;
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
-(void)setScratchNumber:(NSInteger)scratchNumber withValue:(NSData*)value;
-(void)readScratchBank:(NSInteger)bank;
-(void)readTemperature;
-(void)setPairingPin:(UInt16)pinCode;
-(void)readRadioConfig;
-(void)setRadioConfig:(BeanRadioConfig*)config;
-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;
@end

@protocol BeanDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)bean:(Bean*)bean error:(NSError*)error;
-(void)bean:(Bean*)bean didProgramArduinoWithError:(NSError*)error;
-(void)bean:(Bean*)bean ArduinoProgrammingTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
-(void)bean:(Bean*)bean serialDataReceived:(NSData*)data;
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
-(void)bean:(Bean*)bean didUpdateScratchNumber:(NSNumber*)number withValue:(NSData*)data;
-(void)bean:(Bean*)bean completedFirmwareUploadWithError:(NSError*)error;
-(void)bean:(Bean*)bean firmwareUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
-(void)bean:(Bean*)bean didUpdateSketchName:(NSString*)name dateProgrammed:(NSDate*)date crc32:(UInt32)crc;
@end