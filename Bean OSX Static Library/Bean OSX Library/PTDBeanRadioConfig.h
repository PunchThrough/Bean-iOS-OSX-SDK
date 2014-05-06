//
//  BeanRadioConfig.h
//  Bean OSX Library
//
//  Created by Matthew Chung on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PTDBean.h"

@interface PTDBeanRadioConfig : NSObject
-(BOOL)validate:(NSError**)error;
@property (nonatomic, readwrite) NSTimeInterval advertisingInterval;
@property (nonatomic, readwrite) NSTimeInterval connectionInterval;
@property (nonatomic, readwrite) PTDTxPower_dB power;
@property (nonatomic, strong) NSString *name;

@end
