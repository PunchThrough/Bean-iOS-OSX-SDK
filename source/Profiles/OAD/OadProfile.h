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

@interface OadProfile : BleProfile  <BleProfile>

@property (nonatomic, weak) id<OAD_Delegate> delegate;

-(BOOL)updateFirmwareWithImagePaths:(NSArray*)firmwareImages;

// Cancels firmware update
// No callbacks needed
-(void)cancel;

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


