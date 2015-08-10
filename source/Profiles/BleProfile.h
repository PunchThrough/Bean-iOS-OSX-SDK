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

<<<<<<< 7bd1b3ccc614487f3a659fb06e0ad552723a456c
#import "Profile_Protocol.h"
#import "ProfileDelegate_Protocol.h"
=======
#import "CBPeripheral+isConnected_Universal.h"
>>>>>>> - Added a pure virtual "validate" method to BleProfile class. Validation is now kicked off with this method, rather that beginning in the "init" method. This was done for readability and to prevent a possible race condition if the profile reports it's validity before its own completion handler is set.


// This is an abstract class and should only be used when subclassed.
@interface BleProfile : NSObject <CBPeripheralDelegate>
{
@protected CBPeripheral* peripheral;
@protected BOOL profileHasReportedValidity;
}

@property (nonatomic, weak) id delegate;

// Virtual methods that must be overridden in a subclass
-(void)validate; // Virtual method
-(BOOL)isValid:(NSError**)error; // Virtual method


-(void)validateWithCompletion:(void (^)(NSError *error))completion;

// Protected methods that should only be called from a BleProfile subclass
-(void)__notifyValidity;


// Class factory methods
+(void)registerProfile:(Class)subclass serviceUUID:(NSString*)uuid;
+(BleProfile*)createBleProfileWithService:(CBService*)service;
+(NSArray *)registeredProfiles;

@end



// These methods must be implemented in any BleProfile subclasses
@protocol BleProfile
@required
-(void)validate;
-(BOOL)isValid:(NSError**)error;
-(id)initWithService:(CBService*)service;
@end
