//
//  BeanRadioConfig.m
//  Bean OSX Library
//
//  Created by Matthew Chung on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BeanRadioConfig.h"

@interface BeanRadioConfig()

@property (nonatomic, readwrite) NSTimeInterval advertisingInterval;
@property (nonatomic, readwrite) NSTimeInterval connectionInterval;
@property (nonatomic, readwrite) PTDTxPower_dB power;
@property (nonatomic, strong) NSString *name;

@end

@implementation BeanRadioConfig

-(void)setAdvertisingInterval:(NSTimeInterval)advertisingInterval error:(NSError**)error {
    _advertisingInterval = advertisingInterval;
}
-(void)setConnectionInterval:(NSTimeInterval)connectionInterval error:(NSError**)error {
    _connectionInterval = connectionInterval;
}
-(void)setPower:(PTDTxPower_dB)power {
    _power = power;
}
-(void)setName:(NSString *)name error:(NSError**)error {
    if (name.length>20) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Name length can not exceed 20 characters", @"")};
            *error = [NSError errorWithDomain:BeanInvalidArgurment code:0 userInfo:userInfo];
        }
    }
    _name = name;
}
@end
