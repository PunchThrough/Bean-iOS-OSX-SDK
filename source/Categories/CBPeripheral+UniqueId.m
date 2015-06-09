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
    return self.identifier ?: [[self class] blankID];
}

+(NSUUID *)blankID
{
    return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}

@end

