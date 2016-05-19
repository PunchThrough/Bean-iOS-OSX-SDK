//
//  BleDevice.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 6/24/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBleDevice.h"
#import "CBPeripheral+RSSI_Universal.h"

@implementation PTDBleDevice

#pragma mark - Public Methods
-(id)initWithPeripheral:(CBPeripheral*)peripheral{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
            }
    return self;
}

-(void)discoverServices{
    _profiles = [[NSMutableDictionary alloc] init];
    [_peripheral discoverServices:[BleProfile registeredProfiles]];
}

- (BOOL)isEqual:(id)object {
    if( ![object isKindOfClass:[PTDBleDevice class]] ) { return NO; }
    return [self.identifier isEqual:((PTDBleDevice*)object).identifier];
}

- (NSUInteger)hash {
    return self.identifier.hash;
}

-(NSUUID*)identifier{
    if(_peripheral && _peripheral.identifier){
        return [_peripheral identifier];
    }
    return nil;
}

-(NSString*)name{
    if(_peripheral.name){
        return _peripheral.name;
    }
    NSString* localName = [_advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    return localName ? localName : @"Unknown";
}

-(void)readRSSI {
    if(_peripheral.state != CBPeripheralStateConnected) {
        return;
    }
    [_peripheral readRSSI];
}
-(NSNumber*)RSSI{
    NSNumber* returnedRSSI;
    if(_peripheral.state == CBPeripheralStateConnected
       && [_peripheral RSSI_Universal]){
        returnedRSSI = [_peripheral RSSI_Universal];
    }else{
        returnedRSSI = _RSSI;
    }
    // If RSSI == 127, that means it's unavailable. Return nil in this case
    return (returnedRSSI.integerValue!=127)?returnedRSSI:nil;
}

#pragma mark - Protected methods
-(CBPeripheral*)peripheral{
    return _peripheral;
}
-(void)setState:(PTDBleDeviceState)state{
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

#pragma mark Virtual methods

- (void)profileDiscovered:(BleProfile *)profile
{
    // This method should be overridden by a child class that wants to implement its behavior
}

- (void)rssiDidUpdateWithError:(NSError *)error
{
    // This method should be overridden by a child class that wants to implement its behavior
}

- (void)servicesHaveBeenModified
{
    // This method should be overridden by a child class that wants to implement its behavior
}

- (void)notificationStateUpdatedWithError:(NSError *)error
{
    // This method should be overridden by a child class that wants to implement its behavior
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
#if TARGET_OS_IPHONE // This is used in iOS 8
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didReadRSSI: %@ error: %@", peripheral, RSSI, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            RSSI ?: [NSNull null], @"rssi",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"peripheral:didReadRSSI:error:" object:params];
    for (BleProfile *profile in _profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheral:didReadRSSI:error:)]){
                [profile peripheral:peripheral didReadRSSI:RSSI error:error];
            }
        }
    }
    _RSSI = RSSI;
    [self rssiDidUpdateWithError:error];
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceDidUpdateRSSI:error:)]) {
        [self.delegate deviceDidUpdateRSSI:self error:error];
    }
}
#endif
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheralDidUpdateRSSI: %@ error: %@", peripheral, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"peripheralDidUpdateRSSI:error:" object:params];
    for (BleProfile *profile in _profiles) {
        if(profile){
            if([profile respondsToSelector:@selector(peripheralDidUpdateRSSI:error:)]){
                [profile peripheralDidUpdateRSSI:peripheral error:error];
            }
        }
    }
    // This callback is deprecated for iOS8. The logic below prevents a nil RSSI from potentially overwriting the actual RSSI in iOS8 in the event that both callbacks are invoked.
    _RSSI = [_peripheral RSSI_Universal]?[_peripheral RSSI_Universal]:_RSSI;
    [self rssiDidUpdateWithError:error];
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceDidUpdateRSSI:error:)]) {
        [self.delegate deviceDidUpdateRSSI:self error:error];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didDiscoverServices: error:%@", peripheral, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverServices" object:params];
    
    for ( CBService *service in peripheral.services ) {
        if ( service && service.UUID && !_profiles[service.UUID] ) {
 
            BleProfile *profile = [BleProfile createBleProfileWithService:service];
            if (profile) {
                _profiles[service.UUID] = profile;
                profile.delegate = self;
                [self profileDiscovered:profile];
            } else
                PTDLog(@"Unknown service profile UUID: %@", service.UUID);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didDiscoverIncludedServicesForService:%@ error:%@", peripheral, service, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            service ?: [NSNull null], @"service",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverIncludedServicesForService" object:params];
    
    BleProfile* profile = _profiles[service.UUID];
    if (profile)
        if ([profile respondsToSelector:@selector(peripheral:didDiscoverIncludedServicesForService:error:)])
            [profile peripheral:peripheral didDiscoverIncludedServicesForService:service error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didDiscoverCharacteristicsForService:%@ error:%@", peripheral, service, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            service ?: [NSNull null], @"service",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverCharacteristicsForService" object:params];

    BleProfile* profile = _profiles[service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didDiscoverCharacteristicsForService:error:)])
            [profile peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didUpdateValueForCharacteristic:%@ error:%@", peripheral, characteristic, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateValueForCharacteristic" object:params];
    
    //PTDLog(@"didUpdateValueForCharacteristic: %@", characteristic);
    BleProfile* profile = _profiles[characteristic.service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristic:error:)])
            [profile peripheral:peripheral didUpdateValueForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didWriteValueForCharacteristic:%@ error:%@", peripheral, characteristic, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didWriteValueForCharacteristic" object:params];
    
    BleProfile* profile = _profiles[characteristic.service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didWriteValueForCharacteristic:error:)])
            [profile peripheral:peripheral didWriteValueForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didUpdateNotificationStateForCharacteristic:%@ error:%@", peripheral, characteristic, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateNotificationStateForCharacteristic" object:params];

    if (error) {
        [self notificationStateUpdatedWithError:error];
    }
    
    BleProfile* profile = _profiles[characteristic.service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didUpdateNotificationStateForCharacteristic:error:)])
            [profile peripheral:peripheral didUpdateNotificationStateForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didDiscoverDescriptorsForCharacteristic:%@ error:%@", peripheral, characteristic, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            characteristic ?: [NSNull null], @"characteristic",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didDiscoverDescriptorsForCharacteristic" object:params];
    
    BleProfile* profile = _profiles[characteristic.service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didDiscoverDescriptorsForCharacteristic:error:)])
            [profile peripheral:peripheral didDiscoverDescriptorsForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didUpdateValueForDescriptor:%@ error:%@", peripheral, descriptor, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            descriptor ?: [NSNull null], @"descriptor",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didUpdateValueForDescriptor" object:params];
    
    BleProfile* profile = _profiles[descriptor.characteristic.service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didUpdateValueForDescriptor:error:)])
            [profile peripheral:peripheral didUpdateValueForDescriptor:descriptor error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    if (error) PTDLog(@"PTDBleDevice error: peripheral:%@ didWriteValueForDescriptor:%@ error:%@", peripheral, descriptor, error);
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            descriptor ?: [NSNull null], @"descriptor",
                            error ?: [NSNull null], @"error",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didWriteValueForDescriptor" object:params];
    
    BleProfile* profile = _profiles[descriptor.characteristic.service.UUID];
    if(profile)
        if([profile respondsToSelector:@selector(peripheral:didWriteValueForDescriptor:error:)])
            [profile peripheral:peripheral didWriteValueForDescriptor:descriptor error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices{
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            peripheral ?: [NSNull null], @"peripheral",
                            invalidatedServices ?: [NSNull null], @"invalidatedServices",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didModifyServices" object:params];
    [self servicesHaveBeenModified];
}

@end
