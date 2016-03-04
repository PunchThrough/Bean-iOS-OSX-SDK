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

/**
 *  Sent when a firmware upload process completes. This is called when all images are successfully uploaded to Bean or
 *  a failure causes the firmware upload process to abort early.
 *  @param device The OadProfile for the Bean whose firmware has been updated
 *  @param error Nil if successful, or an NSError if the upload was unsuccessful. See <BeanErrors>.
 */
- (void)device:(OadProfile *)device completedFirmwareUploadWithError:(NSError *)error;

// Callback for method: -(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;
// Called every time the time left changes
-(void)device:(OadProfile*)device OADUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;

/**
 *  Called when a single firmware image is successfully uploaded to Bean.
 *  Since most firmware updates send more than one image and wait for Bean to disconnect, reboot, and reconnect,
 *  updating a Bean's firmware will most likely result in multiple calls to this delegate - one for each image uploaded.
 *  @param device The OadProfile for the Bean that completed an image upload
 *  @param imagePath The path to the image that was just transferred to Bean
 */
- (void)device:(OadProfile *)device completedFirmwareUploadOfSingleImage:(NSString *)imagePath;

@end


