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
#import "PTDBleDevice.h"

#define ARDUINO_OAD_GENERIC_TIMEOUT_SEC 3
#define TPDBeanErrorDomain @"TPDBeanErrorDomain"

@class PTDBeanRadioConfig;
@class PTDBeanManager;
@protocol PTDBeanDelegate;

/**
 *  Error states returned by PTDBeanDelegate bean:error:
 
 */
typedef NS_ENUM(NSInteger, BeanErrors) {
    /**
     *  An input argument was invalid
     */
    BeanErrors_InvalidArgument = 0,
    /**
     *  Bluetooth is not turned on
     */
    BeanErrors_BluetoothNotOn,
    /**
     *  The bean is not connected
     */
    BeanErrors_NotConnected,
    /**
     *  No Peripheral discovered with corresponding UUID
     */
    BeanErrors_NoPeriphealDiscovered,
    /**
     *  Device with UUID already connected to this Bean
     */
    BeanErrors_AlreadyConnected,
    /**
     *  A device with this UUID is in the process of being connected to
     */
    BeanErrors_AlreadyConnecting,
    /**
     *  The device's current state is not eligible for a connection attempt
     */
    BeanErrors_DeviceNotEligible,
    /**
     *  No device with this UUID is currently connected
     */
    BeanErrors_FailedDisconnect
};

/**
 *  Represents the state of the Bean connection
 */
typedef NS_ENUM(NSInteger, BeanState) {
    /**
     *  Used for initialization and unknown error states
     */
    BeanState_Unknown = 0,
    /**
     *  Bean has been discovered by a central
     */
    BeanState_Discovered,
    /**
     *  Bean is attempting to connect with a central
     */
    BeanState_AttemptingConnection,
    /**
     *  Bean is undergoing validation
     */
    BeanState_AttemptingValidation,
    /**
     *  Bean is connected
     */
    BeanState_ConnectedAndValidated,
    /**
     *  Bean is disconnecting
     */
    BeanState_AttemptingDisconnection
};

/**
 *  Represents the Bean's Arduino power state
 */
typedef NS_ENUM(NSInteger, ArduinoPowerState) {
    /**
     *  Used for initialization and unknown error states
     */
    ArduinoPowerState_Unknown = 0,
    /**
     *  Bean has been discovered by a central
     */
    ArduinoPowerState_Off,
    /**
     *  Bean is attempting to connect with a central
     */
    ArduinoPowerState_On
};

/**
 *  docset does not work here
 */
typedef struct {
    double x;
    double y;
    double z;
} PTDAcceleration;

/**
 *  Transmission power levels availabe to the Bean
 */
typedef NS_ENUM(NSUInteger, PTDTxPower_dB) {
    /**
     *  4db. Do this to maximize your tranmission strength.
     */
    PTDTxPower_4dB = 0,
    /**
     *  0db. This is the default value.
     */
    PTDTxPower_0dB,
    /**
     *  -6db
     */
    PTDTxPower_neg6dB,
    /**
     *  -23db. Use this to maximize power savings.
     */
    PTDTxPower_neg23dB
};
/**
 *  Advertising modes availabe to the Bean
 */
typedef NS_ENUM(NSUInteger, PTDAdvertisingMode) {
    /**
     *  4db. Do this to maximize your tranmission strength.
     */
    PTDAdvertisingMode_Standard = 0,
    /**
     *  0db. This is the default value.
     */
    PTDAdvertisingMode_IBeacon
};


/**
   An PTDBean object represents a Light Blue Bean that gives access to setting and retrieving of Arduino attributes, such as the name, temperature, accelerometer, look at Other Methods below for more.

    Example:
    // Set this class as the Bean's delegate to receive messages
    self.bean.delegate = self;
    // ask the Bean for the current ambient temperature
    [self.bean readTemperature];
 
    // This is called when the Bean responds
    -(void)bean:(PTDBean *)bean didUpdateTemperature:(NSNumber *)degrees_celsius {
      NSString *msg = [NSString stringWithFormat:@"received did update temp reading:%@", degrees_celsius];
      NSLog(@"%@",msg);
    }
 
   See [BeanXcodeWorkspace](http://www.punchthrough.com) for more examples.
 */

@interface PTDBean : PTDBleDevice
/// @name Identifying a Bean
/**
*  The UUID of the CoreBluetooth peripheral associated with the Bean. This is not guaranteed to be the same between different devices. If a bluetooth cache is cleared, this UUID is not guaranteed to stay the same.
*  For more info, refer to the [Apple identifier documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/translated_content/CBPeripheral.html#//apple_ref/occ/instp/CBPeripheral/identifier)
*/
@property (nonatomic, readonly) NSUUID* identifier;
/**
 *  The Bean's name.
 *  For more info, refer to the [Apple name documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/translated_content/CBPeripheral.html#//apple_ref/occ/instp/CBPeripheral/name)
 */
@property (nonatomic, readonly) NSString* name;
/**
 *  The <PTDBeanDelegate> delegate object for the Bean. Set your class as the delegate to receive messages and responses from the Bean.
 */
@property (nonatomic, weak) id<PTDBeanDelegate> delegate;
/**
 *  Used to create and manage Beans.
 *
 *  @see PTDBeanManager
 */
@property (nonatomic, readonly) PTDBeanManager* beanManager;
/**
 *  Bluetooth LE advertising data. A dictionary containing [CBAdvertisementDataLocalNameKey](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/translated_content/CBCentralManagerDelegate.html)
 */
@property (nonatomic, readonly) NSDictionary* advertisementData;
/**
 *  The version of the Bean's current firmware.
 */
@property (nonatomic, readonly) NSString* firmwareVersion;
/**
 *  Represents last time this Bean was discovered while scanning.
 */
@property (nonatomic, readonly) NSDate* lastDiscovered;
/**
 Test equality with another Bean. This method returns TRUE if both Beans have the same <identifier>
 @param bean The Bean with which to test equality
 */
- (BOOL)isEqualToBean:(PTDBean *)bean;
/// @name Monitoring a Bean's Connection State
/**
 The current connection state of the Bean. See <BeanState> for more details.
 
     if (self.bean.state == BeanState_Discovered) {
        NSLog(@"Bean discovered, try connecting");
     }
     else if (self.bean.state == BeanState_ConnectedAndValidated) {
        NSLog(@"Bean connected, try calling an API");
     }
 */
@property (nonatomic, readonly) BeanState state;
/// @name Radio Configuration
/**
 Cached data for Bean's Radio Configuration. Should call <readRadioConfig> first to ensure this data is fresh.
 @see [PTDBean readRadioConfig]
 @see [PTDBeanDelegate bean:didUpdateRadioConfig:]
 @see PTDBeanRadioConfig
 */
@property (nonatomic, strong, readonly) PTDBeanRadioConfig * radioConfig;
/**
 Requests the Bean's current Radio Configuration.
 @discussion When you call this method to read the Bean's Radio Configuration, the bean calls the [PTDBeanDelegate bean:didUpdateRadioConfig:] method of its delegate object. If the Bean's Radio Config is successfully retrieved, you can access it through the Bean's <radioConfig> property.
 @see [PTDBeanDelegate bean:didUpdateRadioConfig:]
 @see PTDBeanRadioConfig
 */
-(void)readRadioConfig;
/**
 Sets the Bean's radio configuration.
 @param config see PTDBeanRadioConfig
 */
-(void)setRadioConfig:(PTDBeanRadioConfig*)config;
/// @name Accessing a Bean's Received Signal Strength Indicator (RSSI) Data
/**
 *  Requests the Bean's current RSSI.
 *  @discussion When you call this method to read the Bean's RSSI, the bean calls the [PTDBeanDelegate beanDidUpdateRSSI:error:] method of its delegate object. If the Bean's RSSI is successfully retrieved, you can access it through the Bean's <RSSI> property.
 *  @see [PTDBeanDelegate beanDidUpdateRSSI:error:]
 *  @see RSSI
 */
-(void)readRSSI;
/**
 *  The Bean's RSSI.
 *  For more info, refer to the [Apple RSSI documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/translated_content/CBPeripheral.html#//apple_ref/occ/instp/CBPeripheral/RSSI)
 */
@property (nonatomic, readonly) NSNumber* RSSI;
/// @name Programming and Configuring Arduino
/**
 *  The power state for the Bean's Arduino. Indicates if the Arduino is powered on or off.
 *
 *  @see ArduinoPowerState
 */
@property (nonatomic) ArduinoPowerState arduinoPowerState;
/**
 *  Temporarily turns the Bean's Arduino on or off.
 *
 *  @param "YES" sets the Arduino to a powered-on state and "NO" is a shutdown state.
 */
-(void)setArduinoPowerState:(ArduinoPowerState)state;
/**
 *  Requests the current Arduino power state
 *
 *  @discussion When you call this method to read the Arduino Power State, the bean calls the [PTDBeanDelegate beanDidUpdateArduinoPowerState:] method of its delegate object. If the Arduino's Power State is successfully retrieved, you can access it through the Bean's <arduinoPowerState> property.
 *
 *  @see [PTDBeanDelegate beanDidUpdateArduinoPowerState:]
 *  @see arduinoPowerState
 */
-(void)readArduinoPowerState;
/**
 *  Programs the Arduino with raw binary data. (Not Intel Hex)
 *
 *  @param image The raw binary image used to program the Arduino
 *  @param name The name of the sketch.
 *
 *  @discussion After the Arduino is programmed, the Bean calls the [PTDBeanDelegate bean:didProgramArduinoWithError:] method of its delegate object.
 *
 *  @see [PTDBeanDelegate bean:didProgramArduinoWithError:]
 */
-(void)programArduinoWithRawHexImage:(NSData*)image andImageName:(NSString*)name;
/**
 *  Requests information about the currently programmed Arduino Sketch.
 *
 *  @discussion When you call this method to read the Arduino sketch info, the bean calls the [PTDBeanDelegate beanDid:didUpdateSketchName:dateProgrammed:crc32:] method of its delegate object.
 *
 *  @see [PTDBeanDelegate bean:didUpdateSketchName:dateProgrammed:crc32:]
 */
-(void)readArduinoSketchInfo;
/**
 *  The name of the Arduino Sketch used to program the Bean firmware. Should call <readArduinoSketchinfo> first to ensure this data is fresh.
 */
@property (nonatomic, strong, readonly) NSString *sketchName;
/**
 * The date that the Bean's Arduino sketch was programmed. Should call <readArduinoSketchinfo> first to ensure this data is fresh.
 */
@property (nonatomic, strong, readonly) NSDate *dateProgrammed;

/// @name Accessing Battery Voltage
/**
 *  Requests the current battery or power supply voltage.
 *  @discussion When you call this method to read the battery or power supply voltage, the bean calls the [PTDBeanDelegate bean:didUpdateBattery:] method of its delegate object. If the Bean's supply voltage is successfully retrieved, you can access it through the Bean's <batteryVoltage> property.
 *  @see [PTDBeanDelegate bean:didUpdateBattery:]
 *  @see batteryVoltage
 */
-(void)readBatteryVoltage;
/**
 *  Cached representation of the Bean's battery or power supply voltage. Should call <readBatteryVoltage> first to ensure this data is fresh.
 */
@property (nonatomic, readonly) NSNumber* batteryVoltage;
/// @name Accessing LED colors
/**
 *  Sets the Bean's RGB LED color
 *  @param color Color object which is used to set the Led
 *  @see [PTDBeanDelegate bean:didUpdateLedColor:]
 */
#if TARGET_OS_IPHONE
-(void)setLedColor:(UIColor*)color;
#else
-(void)setLedColor:(NSColor*)color;
#endif
/**
 *  Requests the Bean's current Led Color.
 *  @discussion When you call this method to read the LED values, the bean calls the [PTDBeanDelegate bean:didUpdateLedColor:] method of its delegate object.
 *  @see [PTDBeanDelegate bean:didUpdateLedColor:]
 */
-(void)readLedColor;

/// @name Sending Serial Data
/**
 *  Sends data over serial to the Bean's Arduino
 *  @param data data to send over serial to the Arduino
 *  @see [PTDBeanDelegate bean:serialDataReceived:]
 */
-(void)sendSerialData:(NSData*)data;
/**
 *  Sends human-readable ASCII data over serial to the Bean's Arduino
 *  @param string An NSString which is converted to NSData for sending over serial to the Bean's Arduino
 *  @see [PTDBeanDelegate bean:serialDataReceived:]
 */
-(void)sendSerialString:(NSString*)string;

/// @name Accessing Acceleration Data
/**
 Requests the Bean's current acceleration values
    
 @discussion When you call this method to read the Acceleration, the bean calls the [PTDBeanDelegate bean:didUpdateAccelerationAxes:] method of its delegate object.
 
    Example:
    // let the Bean know we implement PTDBeanDelegate
    self.bean.delegate = self;
    // ask the Bean for the acceleration data
    [self.bean readAccelerationAxis];
    
    // check for the Bean to send it back
    -(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration {
        NSString *msg = [NSString stringWithFormat:@"x:%f y:%f z:%f", acceleration.x,acceleration.y,acceleration.z];
        NSLog(@"%@", msg);
    }

 @see [PTDBeanDelegate bean:didUpdateAccelerationAxes:]
 */
-(void)readAccelerationAxis;
/// @name Accessing "Scratch" Data
/**
   Stores data in one of the Bean's scratch banks.
 
    Example:
    // set the scratch bank, 1-5
    int scratchNumber = 1
    // set the scratch data
    [self.bean setScratchNumber:scratchNumber withValue:[@"scratchdata" dataUsingEncoding:NSUTF8StringEncoding]];
    // after some time, ask for it back
    [self.bean readScratchBank:scratchNumber];
 
    // check the delegate value
    -(void)bean:(PTDBean *)bean didUpdateScratchNumber:(NSNumber *)number withValue:(NSData *)data {
      NSString* str = [NSString stringWithUTF8String:[data bytes]];
      NSString *msg = [NSString stringWithFormat:@"received scratch number:%@ scratch:%@", number, str];
      NSLog(@"%@", msg);
    }
 
 @param bank    The index of the scratch bank to store data, from 1 to 5.
 @param data    Data to be stored in the selected bank. Can be up to 20 bytes.
 @see [PTDBean readScratchBank:];
 */
-(void)setScratchBank:(NSInteger)bank data:(NSData*)data;
/**
 This method is deprecated. Use <[PTDBean setScratchBank:data:]> instead.
 @deprecated v0.3.2
 */
-(void)setScratchNumber:(NSInteger)scratchNumber withValue:(NSData*)value __attribute__((deprecated("use setScratchBank:data:")));
/**
 *  Requests Bean's current scratch bank data.
 *  @discussion When you call this method to read one of the Bean's scratch banks, the bean calls the [PTDBeanDelegate bean:didUpdateScratchNumber:withValue:] method of its delegate object.
 *  @param The index of the scratch bank to request, from 1 to 5.
 *  @see [PTDBeanDelegate bean:didUpdateScratchNumber:withValue:]
 */
-(void)readScratchBank:(NSInteger)bank;

/// @name Accessing Temperature Data
/**
 *  Requests the Bean's current temperature reading in Celsius.
 *  @discussion When you call this method to read the Bean's temperature, the bean calls the [PTDBeanDelegate bean:didUpdateTemperature:] method of its delegate object.
 *  @see [PTDBeanDelegate bean:didUpdateTemperature:]
 */
-(void)readTemperature;

@end

/**
 Delegates of a PTDBean object should implement this protocol. See [BeanXcodeWorkspace](http://www.punchthrough.com) for more examples.
 */
@protocol PTDBeanDelegate <NSObject>

@optional
/**
 Sent when an error occurs
 
    example:
    if (error.code == BeanErrors_InvalidArgument) {
      NSLog(@"Invalid argument - %@", [error localizedDescription]);
    }
    else {
      // do something else
    }
 
 @param bean  the bean that made the request
 @param error refer to BeanErrors for the list of error codes
 
 */
-(void)bean:(PTDBean*)bean error:(NSError*)error;
/**
 Sent when the Arduino has been manually powered on or off
 @param bean  the bean that made the request
 @param poweredOn true if the Arduino is powered, false if it is shut down
 */
-(void)beanDidUpdateArduinoPowerState:(PTDBean*)bean;
/**
 Sent when a Bean has finished programming it's Arduino. The programming process was successful when error is nil.
 @param bean  The Bean whose Arduino has been programmed.
 @param error An NSError with error code representing <BeanErrors>
 */
-(void)bean:(PTDBean*)bean didProgramArduinoWithError:(NSError*)error;
/**
 *  Time remaining until the Arduino is finished programming, and percentage of the process is complete.
 *
 *  @param bean               The Bean being programmed
 *  @param seconds            The remaining number of seconds in the programming process
 *  @param percentageComplete The completion percentage of the programming process, from 0.0 to 1.0.
 */
-(void)bean:(PTDBean*)bean ArduinoProgrammingTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
/**
 *  Serial data received from the Bean
 *
 *  @param bean the Bean sending the serial data
 *  @param data the data sent from the Bean
 */
-(void)bean:(PTDBean*)bean serialDataReceived:(NSData*)data;
/**
 *  Sent in response when a Bean's LED values are requested
 *
 *  @param bean  The Bean whose LED color has been requested
 *  @param color The Bean's LED color. Alpha channel is always 1.
 */
#if TARGET_OS_IPHONE
-(void)bean:(PTDBean*)bean didUpdateLedColor:(UIColor*)color;
#else
-(void)bean:(PTDBean*)bean didUpdateLedColor:(NSColor*)color;
#endif
/**
Sent in response when a Bean's accelerometer readings are requested
 
 @param bean         the Bean being queried
 @param acceleration A <PTDAcceleration> struct containing 3-axis acceleration values, identical to [CMAcceleration](https://developer.apple.com/library/ios/documentation/coremotion/reference/CMAccelerometerData_Class/Reference/Reference.html#//apple_ref/doc/c_ref/CMAcceleration)
 
     typedef struct {
     double x;
     double y;
     double z;
     } PTDAcceleration;
 
 */
-(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration;
/**
 *  The Bean RSSI reading
 *
 *  @param bean            the bean being queried
 *  @param error           error returned during RSSI read
 */
-(void)beanDidUpdateRSSI:(PTDBean*)bean error:(NSError*)error;
/**
 *  The Bean temperature readings
 *
 *  @param bean            the bean being queried
 *  @param degrees_celsius the temperature in celsius
 */
-(void)bean:(PTDBean*)bean didUpdateTemperature:(NSNumber*)degrees_celsius;
/**
 *  The Bean Battery Voltage reading
 *
 *  @param bean            the bean being queried
 *  @param error           error returned during Battery Voltage read
 */
-(void)beanDidUpdateBatteryVoltage:(PTDBean*)bean error:(NSError*)error;
/**
  Sent in response when a Bean's <PTDBeanRadioConfig> is requested.
  @param bean   The Bean whose <PTDBeanRadioConfig> has been requested
  @param config The radio configuration of the bean, see <PTDBeanRadioConfig> for more details.
 */
-(void)bean:(PTDBean*)bean didUpdateRadioConfig:(PTDBeanRadioConfig*)config;
/**
 *  Sent in response when a Bean's scratch bank data is requested.
 *
 *  @param bean   The Bean whose scratch bank data has been requested.
 *  @param bank    The index of the scratch bank to store data, from 1 to 5.
 *  @param data    Data to be stored in the selected bank. Can be up to 20 bytes.
 */
-(void)bean:(PTDBean*)bean didUpdateScratchBank:(NSInteger)bank data:(NSData*)data;
/**
  This method is deprecated. Use <[PTDBeanDelegate bean:didUpdateScratchBank:data:]> instead.
  @deprecated v0.3.2
 */
-(void)bean:(PTDBean*)bean didUpdateScratchNumber:(NSNumber*)number withValue:(NSData*)data __attribute__((deprecated("use setScratchBank:data:")));
/**
 Sent when a Bean's firmware upload is completed.
 @param bean  The Bean thats firmware has been updated.
 @param error An NSError with error code representing <BeanErrors> 
 */
-(void)bean:(PTDBean*)bean completedFirmwareUploadWithError:(NSError*)error;
/**
 *  Time remaining before the firmware has completed uploading
 *
 *  @param bean               the Bean being updated
 *  @param seconds            the remaining seconds for the upload
 *  @param percentageComplete the percentage of the upload complete
 */
-(void)bean:(PTDBean*)bean firmwareUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
/**
 *  Message from the Bean that a sketch has been programmed
 *
 *  @param bean the Bean being programmed
 *  @param name the name of the sketch
 *  @param date the date of the programming
 *  @param crc  the cyclic redundancy check
 */
-(void)bean:(PTDBean*)bean didUpdateSketchName:(NSString*)name dateProgrammed:(NSDate*)date crc32:(UInt32)crc;
@end