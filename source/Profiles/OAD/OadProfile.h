//
//  OADDevice.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 8/16/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "DevInfoProfile.h"
#import "BleProfile.h"

@protocol OAD_Delegate;

@interface OadProfile : BleProfile

-(id)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<OAD_Delegate>)delegate;

// Returns FALSE if OAD is not supported on the device. TRUE otherwise
// See callback method: -(void)FirmwareVersion:(NSString*)version isNewer:(BOOL)isNewer;
//-(BOOL)checkForNewFirmware:(NSString*)newFirmwareVersion;

// Returns false if OAD is not supported on the device. Returns true if OAD is supported. Returns false when the breathalyzer is not connected.
// Parameters imageApath and imageBpath are full paths to the images .bin files
// See callback methods:
//-(void)oadDeviceFailedOADUpload:(OAD_BLEDevice*)oadDevice;
//-(void)oadDeviceCompletedOADUpload:(OAD_BLEDevice*)oadDevice;
//-(void)oadDevice:(OAD_BLEDevice*)oadDevice OADUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;
//-(void)oadDeviceOADInvalidImage:(OAD_BLEDevice*)oadDevice;
-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;

// Cancels firmware update
// No callbacks needed
-(void)cancelUpdateFirmware;

@end



@protocol OAD_Delegate <NSObject>

@optional
// Callback for method: -(BOOL)checkForNewFirmware:(NSString*)newFirmwareVersion
// Returns TRUE if the firmware is newer than on the device. FALSE otherwise
-(void)device:(OadProfile*)device firmwareVersion:(NSString*)version isNewer:(BOOL)isNewer;

-(void)device:(OadProfile*)device completedFirmwareUploadWithError:(NSError*)error;

// Callback for method: -(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;
// Called every time the time left changes
-(void)device:(OadProfile*)device OADUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;


@end


