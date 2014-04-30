//
//  CBPeripheral+isConnected_iOS567.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 4/30/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "CBPeripheral+isConnected_Universal.h"

@implementation CBPeripheral (isConnected_Universal)

- (BOOL)isConnected_Universal
{
    
#if TARGET_OS_IPHONE
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ([[vComp objectAtIndex:0] intValue] >= 7) {
        return (self.state == CBPeripheralStateConnected);
    } else if ([[vComp objectAtIndex:0] intValue] == 6 || [[vComp objectAtIndex:0] intValue] == 5) {
        return self.isConnected;
    }
#else
    
#ifdef NSAppKitVersionNumber10_9
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
        return (self.state == CBPeripheralStateConnected);
    }else
#else
    {
        return self.isConnected;
    }
#endif
    
#endif
    return FALSE;
}

@end
