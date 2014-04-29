//
//  BeanRadioConfig.h
//  Bean OSX Library
//
//  Created by Matthew Chung on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PTDTxPower_4dB = 0,
    PTDTxPower_0dB,
    PTDTxPower_neg6dB,
    PTDTxPower_neg23dB,
} PTDTxPower_dB;

@interface BeanRadioConfig : NSObject
-(void)setAdvertisingInterval:(NSTimeInterval)advertisingInterval error:(NSError**)error;
-(void)setConnectionInterval:(NSTimeInterval)connectionInterval error:(NSError**)error;
-(void)setPower:(PTDTxPower_dB)power;
-(void)setName:(NSString *)name error:(NSError**)error;
@end
