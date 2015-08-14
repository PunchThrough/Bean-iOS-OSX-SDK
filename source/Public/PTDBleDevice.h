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
-(void)profileDiscovered:(BleProfile*)profile;

/**
 *  The <PTDBeanDelegate> delegate object for the Bean. Set your class as the delegate to receive messages and responses from the Bean.
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

/// @name Accessing a Device's Received Signal Strength Indicator (RSSI) Data
/**
 *  Requests the Device's current RSSI.
 *  @discussion When you call this method to read the Device's RSSI, the bean calls the [PTDBleDeviceDelegate deviceDidUpdateRSSI:error:] method of its delegate object. If the Device's RSSI is successfully retrieved, you can access it through the Device's <RSSI> property.
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
 *  @param bean            The Device whose RSSI data has been requested.
 *  @param error           Nil if successful, or an NSError if the reading was unsuccessful.
 *  @see [PTDBleDevice readRSSI];
 */
-(void)deviceDidUpdateRSSI:(PTDBleDevice*)device error:(NSError*)error;

@end
