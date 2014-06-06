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
 *  The Bean bluetooth advertisting interval in ms
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
 *  The Bean name
 */
@property (nonatomic, strong) NSString *name;
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
