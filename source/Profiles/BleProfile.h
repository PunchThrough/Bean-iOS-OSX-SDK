//
//  BleProfile.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/8/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

#import "Profile_Protocol.h"
#import "ProfileDelegate_Protocol.h"

@interface BleProfile : NSObject <CBPeripheralDelegate>
{
@protected CBPeripheral* peripheral;
@protected BOOL profileHasReportedValidity;
}

@property (nonatomic, copy) void (^validationCompletetion)(NSError *error);
@property (nonatomic, weak) id delegate;


-(void)validate __attribute__((unavailable("You should always override this")));
-(BOOL)isValid:(NSError**)error; // __attribute__((unavailable("You should always override this")));
-(void)__notifyValidity;


+(void)registerProfile:(Class)subclass serviceUUID:(NSString*)uuid;
+(BleProfile*)createBleProfileWithService:(CBService*)service;
+(NSArray *)registeredProfiles;

@end
