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

@implementation PTDBeanRadioConfig

-(BOOL)validate:(NSError**)error {
    if (self.name.length>20) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Name length can not exceed 20 characters" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
    else if (self.connectionInterval <= 0) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Connection interval must be between 20ms and 40ms" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
    else if (self.advertisingInterval <= 0) {
        if (error) {
            *error = [BEAN_Helper basicError:@"Advertising interval must be between 20ms and 40ms" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
        }
        return NO;
    }
    return YES;
}
@end
