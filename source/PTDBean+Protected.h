//
//  Bean+Protected.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 3/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "PTDBean.h"
#import "PTDBeanManager+Protected.h"
#import "PTDBleDevice+Protected.h"

@interface PTDBean (Protected)

-(id)initWithPeripheral:(CBPeripheral*)peripheral beanManager:(id<PTDBeanManager>)manager;

-(void)setBeanManager:(id<PTDBeanManager>)manager;
-(void)setProfilesRequiredToConnect:(NSArray*)classes;

@end


@protocol PTDBeanExtendedDelegate <PTDBeanDelegate>

@optional

/**
 *  Upload progress for the firmware image currently being sent to Bean.
 *
 *  @param bean         The Bean whose firmware is being updated
 *  @param index        The index of the current image being sent to Bean
 *  @param total        The total number of images being offered to Bean
 *  @param bytesSent    The number of bytes in the current image that have been sent to Bean
 *  @param bytesTotal   The number of bytes in the current image
 */
- (void)bean:(PTDBean*)bean currentImage:(NSUInteger)index totalImages:(NSUInteger)total imageProgress:(NSUInteger)bytesSent imageSize:(NSUInteger)bytesTotal;

/**
 *  Called when a single firmware image is successfully uploaded to Bean.
 *  Since most firmware updates send more than one image and wait for Bean to disconnect, reboot, and reconnect,
 *  updating a Bean's firmware will most likely result in multiple calls to this delegate - one for each image uploaded.
 *
 *  @param bean      The Bean that has just finished receiving a single image
 *  @param imagePath The file path to the image that was successfully uploaded to Bean
 *  @param index     The index of the image that was successfully uploaded to Bean
 *  @param images    The number of images that are currently being offered to Bean
 *  @param error     Nil if successful, or an NSError if the upload was unsuccessful. See BeanErrors.
 */
- (void)bean:(PTDBean *)bean completedFirmwareUploadOfSingleImage:(NSString *)imagePath imageIndex:(NSUInteger)index totalImages:(NSUInteger)images withError:(NSError *)error;

/**
 *  Sent when a firmware upload process completes. This is called when all images are successfully uploaded to Bean or
 *  a failure causes the firmware upload process to abort early.
 *  @param bean         The Bean whose firmware has been updated
 *  @param error        Nil if successful, or an NSError if the upload was unsuccessful. See BeanErrors.
 */
-(void)bean:(PTDBean *)bean completedFirmwareUploadWithError:(NSError*)error;

@end
