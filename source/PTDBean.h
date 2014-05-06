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

@class PTDBeanRadioConfig;
@class PTDBeanManager;
@protocol PTDBeanDelegate;

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

@interface PTDBean : NSObject

@property (nonatomic, weak) id<PTDBeanDelegate> delegate;
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
-(PTDBeanManager*)beanManager;

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
-(void)setRadioConfig:(PTDBeanRadioConfig*)config;
-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;
@end

@protocol PTDBeanDelegate <NSObject>

@optional
//-(void)beanDevice:(BeanDevice*)device recievedIncomingMessage:(GattSerialMessage*)message;
-(void)bean:(PTDBean*)bean error:(NSError*)error;
-(void)bean:(PTDBean*)bean didProgramArduinoWithError:(NSError*)error;
-(void)bean:(PTDBean*)bean ArduinoProgrammingTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
-(void)bean:(PTDBean*)bean serialDataReceived:(NSData*)data;
-(void)bean:(PTDBean*)bean didUpdatePairingPin:(UInt16)pinCode;
#if TARGET_OS_IPHONE
-(void)bean:(PTDBean*)bean didUpdateLedColor:(UIColor*)color;
#else
-(void)bean:(PTDBean*)bean didUpdateLedColor:(NSColor*)color;
#endif
-(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration;
-(void)bean:(PTDBean*)bean didUpdateTemperature:(NSNumber*)degrees_celsius;
-(void)bean:(PTDBean*)bean didUpdateLoopbackPayload:(NSData*)payload;
-(void)bean:(PTDBean*)bean didUpdateRadioConfig:(PTDBeanRadioConfig*)config;
-(void)bean:(PTDBean*)bean didUpdateScratchNumber:(NSNumber*)number withValue:(NSData*)data;
-(void)bean:(PTDBean*)bean completedFirmwareUploadWithError:(NSError*)error;
-(void)bean:(PTDBean*)bean firmwareUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
-(void)bean:(PTDBean*)bean didUpdateSketchName:(NSString*)name dateProgrammed:(NSDate*)date crc32:(UInt32)crc;
@end