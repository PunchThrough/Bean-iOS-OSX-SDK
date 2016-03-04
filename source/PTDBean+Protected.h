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
-(BOOL)updateFirmwareWithImagePaths:(NSArray*)firmwareImages;
-(void)setProfilesRequiredToConnect:(NSArray*)classes;

@end


@protocol PTDBeanExtendedDelegate <PTDBeanDelegate>
@optional
/**
 *  Time remaining before the firmware has completed uploading
 *
 *  @param bean               The Bean being updated
 *  @param seconds            The remaining seconds for the upload
 *  @param percentageComplete The percentage of the upload complete
 */
-(void)bean:(PTDBean*)bean firmwareUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete;

/**
 *  Called when a single firmware image is successfully uploaded to Bean.
 *  Since most firmware updates send more than one image and wait for Bean to disconnect, reboot, and reconnect,
 *  updating a Bean's firmware will most likely result in multiple calls to this delegate - one for each image uploaded.
 *  @param device The OadProfile for the Bean that completed an image upload
 *  @param imagePath The path to the image that was just transferred to Bean
 */
- (void)bean:(PTDBean *)bean completedUploadOfSingleFirmwareImage:(NSString *)imagePath;

/**
 *  Sent when a Bean's firmware upload is completed.
 *  @param bean         The Bean thats firmware has been updated.
 *  @param error        Nil if successful, or an NSError if the upload was unsuccessful. See <BeanErrors>.
 */
-(void)bean:(PTDBean*)bean completedFirmwareUploadWithError:(NSError*)error;

@end