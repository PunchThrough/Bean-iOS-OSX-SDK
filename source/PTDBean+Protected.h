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

@interface PTDBean (Protected)

-(id)initWithPeripheral:(CBPeripheral*)peripheral beanManager:(id<PTDBeanManager>)manager;
-(void)interrogateAndValidate;

-(CBPeripheral*)peripheral;

-(void)setState:(BeanState)state;
-(void)setRSSI:(NSNumber*)rssi;
-(void)setAdvertisementData:(NSDictionary*)adData;
-(void)setLastDiscovered:(NSDate*)date;
-(void)setBeanManager:(id<PTDBeanManager>)manager;
-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;

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
 *  Sent when a Bean's firmware upload is completed.
 *  @param bean         The Bean thats firmware has been updated.
 *  @param error        Nil if successful, or an NSError if the upload was unsuccessful. See <BeanErrors>.
 */
-(void)bean:(PTDBean*)bean completedFirmwareUploadWithError:(NSError*)error;

@end