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

#import "Bean.h"
#import "BeanManager+Protected.h"

@interface Bean (Protected)

-(id)initWithPeripheral:(CBPeripheral*)peripheral beanManager:(id<BeanManager>)manager;
-(void)interrogateAndValidate;

-(CBPeripheral*)peripheral;

-(void)setState:(BeanState)state;
-(void)setRSSI:(NSNumber*)rssi;
-(void)setAdvertisementData:(NSDictionary*)adData;
-(void)setLastDiscovered:(NSDate*)date;
-(void)setBeanManager:(id<BeanManager>)manager;

@end