//
//  CBPeripheral+RSSI_Universal.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/26/15.
//  Copyright (c) 2015 Punch Through Design. All rights reserved.
//

#import "CBPeripheral+RSSI_Universal.h"

@implementation CBPeripheral (RSSI_Universal)

- (NSNumber*)RSSI_Universal
{
    if ([self respondsToSelector:@selector(RSSI)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return self.RSSI;
#pragma clang diagnostic pop
    } else {
        return nil;
    }
}

@end
