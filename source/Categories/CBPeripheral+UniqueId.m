////
////  CBPeripheral+UniqueId.m
////  BleArduino
////
////  Created by Raymond Kampmeier on 1/2/14.
////  Copyright (c) 2014 Punch Through Design. All rights reserved.
////
//

#import "CBPeripheral+UniqueId.h"

@implementation CBPeripheral (UniqueId)

- (NSUUID *)uniqueID
{
    
    NSUUID* uuid;
    
#if TARGET_OS_IPHONE
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    if ([[vComp objectAtIndex:0] intValue] >= 7) {
        if(self.identifier) uuid = self.identifier;
    } else if ([[vComp objectAtIndex:0] intValue] == 6  || [[vComp objectAtIndex:0] intValue] == 5) {
        if(self.UUID) uuid = [[NSUUID alloc] initWithUUIDBytes:[[[CBUUID UUIDWithCFUUID:self.UUID] data] bytes]];
    }
#else
    
#ifdef NSAppKitVersionNumber10_9
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
        if(self.identifier) uuid = self.identifier;
    }else
#else
    {
        if(self.UUID) uuid = [[NSUUID alloc] initWithUUIDBytes:[[[CBUUID UUIDWithCFUUID:self.UUID] data] bytes]];
    }
#endif
    
#endif
    
    if (!uuid) uuid = [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
    
    return uuid;
}

+(NSUUID *)blankID
{
    return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}

@end

