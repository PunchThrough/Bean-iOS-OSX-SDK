//
//  BleProfile.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/8/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


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
-(BOOL)isValid:(NSError**)error;
-(id)initWithService:(CBService*)service;
@end
