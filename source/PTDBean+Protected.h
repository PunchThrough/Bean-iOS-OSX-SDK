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
-(void)sendLoopbackDebugMessage:(NSInteger)length;
-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath;
-(void)setPairingPin:(UInt16)pinCode;

@end