//
//  BeanRadioConfig.m
//  Bean OSX Library
//
//  Created by Matthew Chung on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBeanRadioConfig.h"
#import "PTDBean.h"
#import "BEAN_Helper.h"

@interface PTDBeanRadioConfig()
@end

//intervals are in miliseconds
static CGFloat PTDMinAdInterval = 20;
static CGFloat PTDMaxAdInterval = 1285;
static CGFloat PTDMinConnectionInterval = 20;
static CGFloat PTDMaxConnectionInterval = 1980;

@implementation PTDBeanRadioConfig

- (BOOL)validate:(NSError **)error
{
    // name
    if ( [[self.name dataUsingEncoding:NSUTF8StringEncoding] length] > 20 ) {
        if ( error ) {
            *error = [BEAN_Helper basicError:@"Name length can not exceed 20 bytes" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
    // ad interval
    if ( self.advertisingInterval < PTDMinAdInterval || self.advertisingInterval > PTDMaxAdInterval ) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Advertising interval must be between 20ms and 1.285 seconds" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
   // connection interval
    if ( self.connectionInterval < PTDMinConnectionInterval || self.connectionInterval > PTDMaxConnectionInterval ) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Connection interval must be between 20ms and 2.02 seconds" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
   // power
    if ( self.power < PTDTxPower_neg23dB || self.power > PTDTxPower_4dB ) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Invalid power level" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
   // ad mode
    if ( self.advertisingMode != PTDAdvertisingMode_Standard && self.advertisingMode != PTDAdvertisingMode_IBeacon ) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Invalid Advertising mode" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
    }
    
    return YES;
//todo: validate ibeacon params
}

@end
