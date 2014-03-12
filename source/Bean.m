//
//  BeanDevice.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "Bean.h"
#import "BeanManager+Protected.h"
#import "GattSerialProfile.h"

@interface Bean () <CBPeripheralDelegate, ProfileDelegate_Protocol, GattSerialDeviceDelegate, OAD_Delegate>
@end

@implementation Bean
{
	BeanState                   _state;
    NSNumber*                   _RSSI;
	NSDictionary*               _advertisementData;
    NSDate*                     _lastDiscovered;
	BeanManager*                _beanManager;
    CBPeripheral*               _peripheral;
    
    NSInteger                   validatedProfileCount;
    NSArray*                    profiles;
    DevInfoProfile*             deviceInfo_profile;
    OadProfile*                 oad_profile;
    GattSerialProfile*          gatt_serial_profile;
}

//Enforce that you can't use the "init" function of this class
- (id)init{
    NSAssert(false, @"Please use the \"initWithPeripheral:\" method to instantiate this class");
    return nil;
}

#pragma mark - Public Methods
-(void)sendMessage:(GattSerialMessage*)message{
    [gatt_serial_profile sendMessage:message];
}

-(NSUUID*)identifier{
    if(_peripheral && _peripheral.identifier){
        return [_peripheral identifier];
    }
    return nil;
}
-(NSString*)name{
    if(_peripheral.state == CBPeripheralStateConnected){
        return _peripheral.name;
    }
    return [_advertisementData objectForKey:CBAdvertisementDataLocalNameKey]?[_advertisementData objectForKey:CBAdvertisementDataLocalNameKey]:@"Unknown";//Local Name
}
-(NSNumber*)RSSI{
    if(_peripheral.state == CBPeripheralStateConnected
    && [_peripheral RSSI]){
        return [_peripheral RSSI];
    }
    return _RSSI;
}
-(BeanState)state{
    return _state;
}
-(NSDictionary*)advertisementData{
    return _advertisementData;
}
-(NSDate*)lastDiscovered{
    return _lastDiscovered;
}
-(BeanManager*)beanManager{
    return _beanManager;
}

-(void)sendLoopbackDebugMessage:(NSInteger)length{
    NSMutableData* data = [[NSMutableData alloc] init];
    UInt8 messageID[]= {0xFE, 0x00}; //Major, Minor
    [data appendBytes:messageID length:2];
    [data appendData:[BEAN_Helper dummyData:length]];
    if(_state == BeanState_ConnectedAndValidated &&
       _peripheral.state == CBPeripheralStateConnected) //This second conditional is an assertion
    {
        GattSerialMessage* message = [[GattSerialMessage alloc] initWithPayload:data error:nil];
        [gatt_serial_profile sendMessage:message];
    }
}

#pragma mark - Protected Methods
-(id)initWithPeripheral:(CBPeripheral*)peripheral beanManager:(BeanManager*)manager{
    self = [super init];
    if (self) {
        _beanManager = manager;
        _peripheral = peripheral;
        _peripheral.delegate = self;
    }
    return self;
}

-(void)interrogateAndValidate{
    //Initialize BLE Profiles
    validatedProfileCount = 0;
    deviceInfo_profile = [[DevInfoProfile alloc] initWithPeripheral:_peripheral delegate:self];
    oad_profile = [[OadProfile alloc] initWithPeripheral:_peripheral  delegate:self];
    gatt_serial_profile = [[GattSerialProfile alloc] initWithPeripheral:_peripheral  delegate:self];
    profiles = [[NSArray alloc] initWithObjects:deviceInfo_profile,
                oad_profile,
                gatt_serial_profile,
                nil];

    [self __validateNextProfile];
}
-(CBPeripheral*)peripheral{
    return _peripheral;
}
-(void)setState:(BeanState)state{
    _state = state;
}
-(void)setRSSI:(NSNumber*)rssi{
    _RSSI = rssi;
}
-(void)setAdvertisementData:(NSDictionary*)adData{
    _advertisementData = adData;
}
-(void)setLastDiscovered:(NSDate*)date{
    _lastDiscovered = date;
}
-(void)setBeanManager:(BeanManager*)manager{
    _beanManager = manager;
}

#pragma mark - Private Methods
-(void)__validateNextProfile{
    id<Profile_Protocol> profile = [profiles objectAtIndex:validatedProfileCount];
    //[cbperipheral  setDelegate:profile];
    [profile validate];
    validatedProfileCount++;
}

#pragma mark -
#pragma mark Profile Delegate callbacks
-(void)profileValidated:(id<Profile_Protocol>)profile{
    if(validatedProfileCount >= [profiles count]){
        if(_beanManager){
            if([_beanManager respondsToSelector:@selector(bean:hasBeenValidated_error:)]){
                [_beanManager bean:self hasBeenValidated_error:nil];
            }
        }
    }else{
        [self __validateNextProfile];
    }
}

#pragma mark gattSerialDevideDelegate callbacks
-(void)gattSerialDevice:(GattSerialProfile*)device recievedIncomingMessage:(GattSerialMessage*)message{
    //TODO: have some message parsing in here, and break messages out into bean specific callbacks
    NSLog(@"Gatt Serial Message Received: %@",[message bytes]);
}

-(void)gattSerialDevice:(GattSerialProfile*)device error:(NSError*)error{
    
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
