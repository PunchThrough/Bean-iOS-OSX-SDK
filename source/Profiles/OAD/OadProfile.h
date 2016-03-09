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

@interface OadProfile : BleProfile <BleProfile>

@property(nonatomic, weak) id<OAD_Delegate> delegate;

/**
 *  Starts the OAD firmware update process for a Bean.
 *
 *  @param firmwareImages An NSArray of paths to firmware image binaries
 *
 *  @return YES if firmware update process was initialized successfully. NO if an error occurred. A return value of NO
 *      is accompanied by a call to device:completedFirmwareUploadWithError: with an error parametern present.
 */
- (BOOL)updateFirmwareWithImagePaths:(NSArray *)firmwareImages;

/**
 *  Cancels a firmware update in progress.
 */
- (void)cancel;

@end

@protocol OAD_Delegate <NSObject>

#warning WTF is this method actually
/**
 *  Sent when a firmware upload process completes. This is called when all images are successfully uploaded to Bean or
 *  a failure causes the firmware upload process to abort early.
 *
 *  @param device The OadProfile for the Bean whose firmware has been updated
 *  @param error Nil if successful, or an NSError if the upload was unsuccessful. See <BeanErrors>.
 */
- (void)device:(OadProfile *)device completedFirmwareUploadWithError:(NSError *)error;

/**
 *  Indicates time remaining in the upload of a single OAD firmware image.
 *
 *  @param device             the device receiving the update
 *  @param seconds            estimated time left, in seconds
 *  @param percentageComplete upload progress, from 0.0 to 1.0
 */
- (void)device:(OadProfile *)device OADUploadTimeLeft:(NSNumber *)seconds withPercentage:(NSNumber *)percentageComplete;

/**
 *  Called when a single firmware image is successfully uploaded to Bean.
 *  Since most firmware updates send more than one image and wait for Bean to disconnect, reboot, and reconnect,
 *  updating a Bean's firmware will most likely result in multiple calls to this delegate - one for each image uploaded.
 *
 *  @param device The OadProfile for the Bean that completed an image upload
 *  @param imagePath The path to the image that was just transferred to Bean
 */
- (void)device:(OadProfile *)device completedFirmwareUploadOfSingleImage:(NSString *)imagePath;

@end
