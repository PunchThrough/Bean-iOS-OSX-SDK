//
//  BeanDevice.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BeanDevice.h"

@interface BeanDevice () <CBPeripheralDelegate, ProfileDelegate_Protocol, GattSerialDeviceDelegate, OAD_Delegate>
@end

@implementation BeanDevice
{
    CBPeripheral* cbperipheral;
    NSInteger validatedProfileCount;
    NSArray * profiles;
    
    DevInfoProfile * deviceInfo_profile;
    OadProfile * oad_profile;
    GattSerialProfile * gatt_serial_profile;
}

//Enforce that you can't use the "init" function of this class
- (id)init
{
    NSAssert(false, @"Please use the \"initWithPeripheral:\" method to instantiate this class");
    return nil;
}

#pragma mark Public Methods
-(id)initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<BeanDeviceDelegate>)delegate
{
    self = [super init];
    if (self) {
        [self setDelegate:delegate];
        cbperipheral = peripheral;
        [cbperipheral setDelegate:self];
        
        deviceInfo_profile = [[DevInfoProfile alloc] initWithPeripheral:cbperipheral delegate:self];
        oad_profile = [[OadProfile alloc] initWithPeripheral:cbperipheral  delegate:self];
        gatt_serial_profile = [[GattSerialProfile alloc] initWithPeripheral:cbperipheral  delegate:self];
        
        validatedProfileCount = 0;
        profiles = [[NSArray alloc] initWithObjects:deviceInfo_profile,
                                                   oad_profile,
                                                   gatt_serial_profile,
                                                   nil];
        [self __validateNextProfile];
    }
    return self;
}

-(BOOL)isValid:(NSError**)error
{
    BOOL valid = ([deviceInfo_profile isValid:error],
                  [oad_profile isValid:error],
                  [gatt_serial_profile isValid:error]
                  )?TRUE:FALSE;
    return valid;
}

#pragma mark Private Methods
-(void)__validateNextProfile
{
    id<Profile_Protocol> profile = [profiles objectAtIndex:validatedProfileCount];
    [cbperipheral  setDelegate:profile];
    validatedProfileCount++;
}

#pragma mark Profile Delegate callbacks
-(void)profileValidated:(id<Profile_Protocol>)profile
{
    if(validatedProfileCount >= [profiles count])
    {
        if(_delegate)
        {
            if([_delegate respondsToSelector:@selector(beanDeviceIsValid:)])
            {
                [_delegate beanDeviceIsValid:self];
            }
        }
    }else{
        [self __validateNextProfile];
    }
}

#pragma mark gattSerialDevideDelegate callbacks
-(void)gattSerialDevice:(GattSerialProfile*)device recievedIncomingMessage:(GattSerialMessage*)message
{
    //TODO: have some message parsing in here, and break messages out into bean specific callbacks
}

-(void)gattSerialDevice:(GattSerialProfile*)device error:(NSError*)error
{

}

#pragma mark CBPeripheralDelegate callbacks
/* //Example of registering to one of these notifications
 id peripheralNotifier = cbperipheral.delegate;
 if([peripheralNotifier isKindOfClass:[CBPeripheralNotifier class]])
 {
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateValueForCharacteristic:) name:@"didUpdateValueForCharacteristic" object:peripheralNotifier];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateNotificationStateForCharacteristic:) name:@"didUpdateNotificationStateForCharacteristic" object:peripheralNotifier];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didWriteValueForCharacteristic:) name:@"didWriteValueForCharacteristic" object:peripheralNotifier];
 }
 */
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"peripheralDidUpdateRSSI:error:" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheralDidUpdateRSSI:error:)]){
                [profile peripheralDidUpdateRSSI:peripheral error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverServices" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didDiscoverServices:)]){
                [profile peripheral:peripheral didDiscoverServices:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            service ?: [NSNull null], @"service",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverIncludedServicesForService" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)]){
                [profile peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            service ?: [NSNull null], @"service",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverCharacteristicsForService" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)]){
                [profile peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateValueForCharacteristic" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)]){
                [profile peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didWriteValueForCharacteristic" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)]){
                [profile peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didReliablyWriteValuesForCharacteristics:(NSArray *)characteristics error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristics ?: [NSNull null], @"characteristics",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didReliablyWriteValuesForCharacteristics" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didReliablyWriteValuesForCharacteristics:error:)]){
                [profile peripheral:peripheral didReliablyWriteValuesForCharacteristics:characteristics error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateBroadcastStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateBroadcastStateForCharacteristic" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didUpdateBroadcastStateForCharacteristic:error:)]){
                [profile peripheral:peripheral didUpdateBroadcastStateForCharacteristic:characteristic error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateNotificationStateForCharacteristic" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)]){
                [profile peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverDescriptorsForCharacteristic" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)]){
                [profile peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            descriptor ?: [NSNull null], @"descriptor",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateValueForDescriptor" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)]){
                [profile peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            descriptor ?: [NSNull null], @"descriptor",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didWriteValueForDescriptor" object:params];
    for (id<Profile_Protocol> profile in profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)]){
                [profile peripheral:peripheral didWriteValueForDescriptor:descriptor error:error];
            }
        }
    }
}

@end
