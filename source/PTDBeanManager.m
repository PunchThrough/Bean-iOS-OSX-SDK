//
//  BeanLocator.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBeanManager.h"
#import "BEAN_Helper.h"
#import "GattSerialProfile.h"
#import "PTDBean+Protected.h"

@interface PTDBeanManager () <CBCentralManagerDelegate, PTDBeanDelegate>
@end

@implementation PTDBeanManager{
    CBCentralManager* cbcentralmanager;
    NSMutableDictionary* beanRecords; //Uses NSUUID as key
}

#pragma mark - Public methods

-(id)init{
    self = [super init];
    if (self) {
        beanRecords = [[NSMutableDictionary alloc] init];
        cbcentralmanager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

-(id)initWithDelegate:(id<PTDBeanManagerDelegate>)delegate{
    self.delegate = delegate;
    return [self init];
}

-(BeanManagerState)state{
    return cbcentralmanager?(BeanManagerState)cbcentralmanager.state:0;
}

-(void)startScanningForBeans_error:(NSError**)error{
    // Bluetooth must be ON
    if (cbcentralmanager.state != CBCentralManagerStatePoweredOn){
        if (error) *error = [BEAN_Helper basicError:@"Bluetooth is not on" domain:NSStringFromClass([self class]) code:BeanErrors_BluetoothNotOn];
        return;
    }
    
    //Clear array of previously discovered peripherals.
    [beanRecords removeAllObjects];
    
    //Collect already connected Beans
    NSArray* connectedBeanPeripherals = [cbcentralmanager retrieveConnectedPeripheralsWithServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_SERVICE_UUID], nil]];
    for( CBPeripheral* beanPeripheral in connectedBeanPeripherals){
        PTDBean* bean = [[PTDBean alloc] initWithPeripheral:beanPeripheral beanManager:self];
        if(bean){
            [beanRecords setObject:bean forKey:bean.identifier];
            bean.state = BeanState_Discovered;
            [self connectToBean:bean error:nil];
            if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didDisconnectBean:error:)]){
                [self.delegate BeanManager:self didDiscoverBean:bean error:nil];
            }
        }
    }
    
    // Scan for peripherals
    PTDLog(@"Started scanning...");
    
    // Define array of app service UUID
    NSArray * services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_SERVICE_UUID], nil];
    
    //Begin scanning
    [cbcentralmanager scanForPeripheralsWithServices:services options:0];
}

-(void)stopScanningForBeans_error:(NSError**)error{
    // Bluetooth must be ON
    if (cbcentralmanager.state != CBCentralManagerStatePoweredOn)
    {
        if (error) *error = [BEAN_Helper basicError:@"Bluetooth is not on" domain:@"API:BLE Connection" code:BeanErrors_BluetoothNotOn];
        return;
    }
    
    [cbcentralmanager stopScan];
    
    PTDLog(@"Stopped scanning.");
}

-(void)connectToBean:(PTDBean*)bean_ error:(NSError**)error{
    //Find BeanRecord that corresponds to this UUID
    PTDBean* bean = [beanRecords objectForKey:bean_.identifier];
    //If there is no such peripheral, return error
    if(!bean){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. No peripheral discovered with the corresponding UUID." domain:NSStringFromClass([self class]) code:BeanErrors_NoPeriphealDiscovered];
        return;
    }
    //Check if the device is already connected
    else if(bean.state == BeanState_ConnectedAndValidated){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. A device with this UUID is already connected" domain:NSStringFromClass([self class]) code:BeanErrors_AlreadyConnected];
        return;
    }
    //Check if the device is already in the middle of an attempted connected
    else if(bean.state == BeanState_AttemptingConnection || bean.state == BeanState_AttemptingValidation){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. A device with this UUID is in the process of being connected to." domain:NSStringFromClass([self class]) code:BeanErrors_AlreadyConnecting];
        return;
    }else if(bean.state != BeanState_Discovered){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. The device's current state is not eligible for a connection attempt." domain:NSStringFromClass([self class]) code:BeanErrors_DeviceNotEligible];
        return;
    }
    //Mark this BeanRecord as is in the middle of a connection attempt
    [bean setState:BeanState_AttemptingConnection];
    //Attempt to connect to the corresponding CBPeripheral
    [cbcentralmanager connectPeripheral:bean.peripheral options:nil];
}

-(void)disconnectBean:(PTDBean*)bean_ error:(NSError**)error{
    //Find BeanPeripheral that corresponds to this UUID
    PTDBean* bean = [beanRecords objectForKey:bean_.identifier];
    //Check if the device isn't currently connected
    if(!bean){
        if(error) *error = [BEAN_Helper basicError:@"Failed attemp to disconnect Bean. No device with this UUID is currently connected" domain:NSStringFromClass([self class]) code:BeanErrors_FailedDisconnect];
        return;
    }
    if(bean.state != BeanState_ConnectedAndValidated){
        if(error) *error = [BEAN_Helper basicError:@"No device with this UUID is currently connected" domain:NSStringFromClass([self class]) code:BeanErrors_FailedDisconnect];
    }
    //Mark this BeanRecord as is in the middle of a disconnection attempt
    [bean setState:BeanState_AttemptingDisconnection];
    //Attempt to disconnect from the corresponding CBPeripheral
    [cbcentralmanager cancelPeripheralConnection:bean.peripheral];
}

#pragma mark - Protected methods
-(void)bean:(PTDBean*)device hasBeenValidated_error:(NSError*)error{
    NSError* localError;
    //Find BeanRecord that corresponds to this UUID
    PTDBean* bean = [beanRecords objectForKey:[device identifier]];
    //If there is no such peripheral, return error
    if(!bean){
        localError = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. No peripheral discovered with the corresponding UUID." domain:NSStringFromClass([self class]) code:BeanErrors_NoPeriphealDiscovered];
    }else if (error){
        localError = error;
        bean.state = BeanState_Discovered; // Reset bean state to the default, ready to connect
        [self disconnectBean:bean error:nil];
    }else{
        //Validation is successful
    }
    
    //Notify Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didConnectToBean:error:)]){
        [self.delegate BeanManager:self didConnectToBean:device error:error];
    }
}


#pragma mark - Private methods
-(PTDBean *)__processBeanRecordFromCBPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    PTDBean * bean;
    //This Bean is already discovered and perhaps connected to
    if ((bean = [beanRecords objectForKey:peripheral.identifier])) {
        bean.RSSI = RSSI;
        bean.lastDiscovered = [NSDate date];
        bean.advertisementData = advertisementData;
    }
    else { // A new undiscovered Bean
        PTDLog(@"centralManager:didDiscoverPeripheral %@", peripheral);
        bean = [[PTDBean alloc] initWithPeripheral:peripheral beanManager:self];
        bean.RSSI = RSSI;
        bean.lastDiscovered = [NSDate date];
        bean.advertisementData = advertisementData;
        bean.state = BeanState_Discovered;
        
        [beanRecords setObject:bean forKey:peripheral.identifier];
    }
    return bean;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    //Notify delegate of state
    if (self.delegate && [self.delegate respondsToSelector:@selector(beanManagerDidUpdateState:)]){
        [self.delegate beanManagerDidUpdateState:self];
    }
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            PTDLog(@"%@: Bluetooth ON", self.class.description);
            break;
            
        default:
            PTDLog(@"%@: Bluetooth state error: %d", self.class.description, (int)central.state);
            break;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    PTDBean* bean = [self __processBeanRecordFromCBPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    if(bean){
        //Inform the delegate that we located a Bean
        if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didDisconnectBean:error:)]){
            [self.delegate BeanManager:self didDiscoverBean:bean error:nil];
        }
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    PTDLog(@"centralManager:didConnectPeripheral %@", peripheral);
    //Find BeanRecord that corresponds to this UUID
    PTDBean* bean = [beanRecords objectForKey:[peripheral identifier]];
    //If there is no such peripheral, return
    if(!bean)return;
    //Mark Bean peripheral as no longer being in a connection attempt
    bean.state = BeanState_AttemptingValidation;
    //Wait for Bean validation before responding to delegate
    [bean interrogateAndValidate];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    PTDLog(@"centralManager:didFailToConnectPeripheral %@", peripheral);
    //Find BeanRecord that corresponds to this UUID
    PTDBean* bean = [beanRecords objectForKey:[peripheral identifier]];
    //If there is no such peripheral, return
    if(!bean)return;
    //Mark Bean peripheral as no longer being in a connection attempt
    bean.state = BeanState_Discovered;
    //Make sure that there is an error to pass along
    if(!error)return;
    //Notify delegate of failure
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didConnectToBean:error:)]){
        [self.delegate BeanManager:self didConnectToBean:nil error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    PTDLog(@"centralManager:didDisconnectPeripheral %@", peripheral);
    //Find BeanRecord that corresponds to this UUID
    PTDBean* bean = [beanRecords objectForKey:[peripheral identifier]];
    if(bean){
        //Mark Bean peripheral as no longer being connected
        bean.state = BeanState_Discovered;
    }else if (!error){ //No Record of this Bean and there is no error
        return;
    }
    
    if(!bean) return; //This may not be the best way to handle this case
    //Alert the delegate of the disconnect
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didDisconnectBean:error:)]){
        [self.delegate BeanManager:self didDisconnectBean:bean error:error];
    }
}


@end
