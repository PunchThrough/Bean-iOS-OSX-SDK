//
//  BleDevice.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 6/24/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif
#import "BleProfile.h"

/**
 *  Represents the Device's connection state
 */
typedef NS_ENUM(NSInteger, PTDBleDeviceState) {
    /**
     *  Used for initialization and unknown error states
     */
    PTDBleDeviceState_Unknown = 0,
    /**
     *  Device has been discovered by a central
     */
    PTDBleDeviceState_Discovered,
    /**
     *  Device is attempting to connect with a central
     */
    PTDBleDeviceState_AttemptingConnection,
    /**
     *  Device is undergoing setup/validation
     */
    PTDBleDeviceState_AttemptingValidation,
    /**
     *  Device is connected
     */
    PTDBleDeviceState_ConnectedAndValidated,
    /**
     *  Device is disconnecting
     */
    PTDBleDeviceState_AttemptingDisconnection
};


@protocol PTDBleDeviceDelegate;

@interface PTDBleDevice : NSObject <CBPeripheralDelegate>{
    CBPeripheral*               _peripheral;
    NSMutableDictionary*        _profiles;
    NSNumber*                   _RSSI;
    NSDictionary*               _advertisementData;
    NSDate*                     _lastDiscovered;
}


-(id)initWithPeripheral:(CBPeripheral*)peripheral;
-(void)discoverServices;
//-(BOOL)requiredProfilesAreValid;

/// @name Virtual methods

/**
 *  Called when a BLE profile is discovered.
 *  @discussion This method can be overridden to notify a subclass when a new BLE profile is discovered. After a profile is discovered, it should then be validated.
 */
- (void)profileDiscovered:(BleProfile *)profile;

/**
 *  Called when a device's RSSI is updated. Override this in your PTDBleDevice subclass to handle its data.
 */
- (void)rssiDidUpdateWithError:(NSError *)error;

/**
 *  Called when a device's services are modified. Override this in your PTDBleDevice subclass to handle its data.
 */
- (void)servicesHaveBeenModified;

/**
 *  Called when iOS encounters an error when updating a characteristic notification state. Override this in your PTDBleDevice subclass to handle its data.
 */
- (void)notificationStateUpdatedWithError:(NSError *)error;

/// @name Delegate

/**
 *  The <PTDBleDeviceDelegate> delegate object for the device. Set your class as the delegate to receive messages and responses from the device.
 */
@property (nonatomic, weak) id<PTDBleDeviceDelegate> delegate;

/// @name Identifying a Device
/**
 *  The UUID of the CoreBluetooth peripheral associated with the Device. This is not guaranteed to be the same between different devices. If a bluetooth cache is cleared, this UUID is not guaranteed to stay the same.
 *  For more info, refer to the [Apple identifier documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/translated_content/CBPeripheral.html#//apple_ref/occ/instp/CBPeripheral/identifier)
 */
@property (nonatomic, readonly) NSUUID* identifier;
/**
 *  The Device's name.
 *  For more info, refer to the [Apple name documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/translated_content/CBPeripheral.html#//apple_ref/occ/instp/CBPeripheral/name)
 */
@property (nonatomic, readonly) NSString* name;

/**
 *  Represents last time this device was discovered while scanning.
 */
@property (nonatomic, readonly) NSDate* lastDiscovered;

/**
 *  Bluetooth LE advertising data. A dictionary containing [CBAdvertisementDataLocalNameKey](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/translated_content/CBCentralManagerDelegate.html)
 */
@property (nonatomic, readonly) NSDictionary* advertisementData;

/// @name Monitoring a Device's Connection State
/**
 The current connection state of the Device. See <PTDBleDeviceState> for more details.
 
 if (device.state == PTDBleDeviceState_Discovered) {
 NSLog(@"Device discovered, try connecting");
 }
 else if (device.state == PTDBleDeviceState_ConnectedAndValidated) {
 NSLog(@"Device connected, try calling an API");
 }
 */
@property (nonatomic, readonly) PTDBleDeviceState state;

/// @name Accessing a Device's Received Signal Strength Indicator (RSSI) Data
/**
 *  Requests the Device's current RSSI.
 *  @discussion When you call this method to read the Device's RSSI, the device calls the [PTDBleDeviceDelegate deviceDidUpdateRSSI:error:] method of its delegate object. If the Device's RSSI is successfully retrieved, you can access it through the Device's <RSSI> property.
 *  @see [PTDBleDeviceDelegate deviceDidUpdateRSSI:error:]
 *  @see RSSI
 */
-(void)readRSSI;
/**
 *  The Device's RSSI.
 *  For more info, refer to the [Apple RSSI documentation](https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBPeripheral_Class/translated_content/CBPeripheral.html#//apple_ref/occ/instp/CBPeripheral/RSSI)
 */
@property (nonatomic, readonly) NSNumber* RSSI;

@end


@protocol PTDBleDeviceDelegate <NSObject>

@optional
/**
 *  Sent in response when a Device's RSSI is requested
 *
 *  @param device            The Device whose RSSI data has been requested.
 *  @param error           Nil if successful, or an NSError if the reading was unsuccessful.
 *  @see [PTDBleDevice readRSSI];
 */
-(void)deviceDidUpdateRSSI:(PTDBleDevice*)device error:(NSError*)error;

@end
