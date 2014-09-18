//
//  BeanRadioConfig.h
//  Bean OSX Library
//
//  Created by Matthew Chung on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTDBean.h"
/**
 Represents Radio configuration for the Bean
 
    Example:
    // sets a config
    PTDBeanRadioConfig *config = [[PTDBeanRadioConfig alloc] init];
    config.advertisingInterval = 0.1;
    config.connectionInterval = 0.2;
    config.power = PTDTxPower_4dB
    config.name = @"myname";
    [self.bean setRadioConfig:config];
    // reads a config
    [self.bean readRadioConfig];
    // listens for the Bean to tell us the config
    -(void)bean:(PTDBean*)bean didUpdateRadioConfig:(PTDBeanRadioConfig*)config {
        NSString *msg = [NSString stringWithFormat:@"received advertising interval:%f connection interval:%f name:%@ power:%d", config.advertisingInterval, config.connectionInterval, config.name, (int)config.power];
        PTDLog(@"%@",msg);
    }

 */
@interface PTDBeanRadioConfig : NSObject
/// @name Setup
/**
 *  The Bean's bluetooth advertisting interval in ms
 */
@property (nonatomic, readwrite) CGFloat advertisingInterval;
/**
 *  The Bean bluetooth connection interval in ms
 */
@property (nonatomic, readwrite) CGFloat connectionInterval;
/**
 *  The Bean bluetooth transmission power
 */
@property (nonatomic, readwrite) PTDTxPower_dB power;
/**
 *  The Bean advertising mode
 */
@property (nonatomic, readwrite) PTDAdvertisingMode advertisingMode;
/**
 *  The Bean iBeacon 16-bit UUID using the base: "A495xxxx-C5B1-4B44-B512-1370F02D74DE"
 */
@property (nonatomic, readwrite) UInt16 iBeacon_UUID;
/**
 *  The Bean iBeacon Major ID
 */
@property (nonatomic, readwrite) UInt16 iBeacon_majorID;
/**
 *  The Bean iBeacon Minor ID
 */
@property (nonatomic, readwrite) UInt16 iBeacon_minorID;
/**
 *  The Bean name
 */
@property (nonatomic, strong) NSString *name;
/**
 *  A Boolean that indicates if the Bean's pairing pin is enabled.
 *
 *  @discussion This property is ignored when using <[PTDBean setRadioConfig:]>. To enable or disable the pairing pin, use <[PTDBean setPairingPin:]>
 */
@property (nonatomic) BOOL pairingPinEnabled;
/// @name Validation
/**
 *  Validates a config
 *
 *  @param error See BeanErrors
 *
 *  @return YES if valid, NO if not
 */
-(BOOL)validate:(NSError**)error;

@end
