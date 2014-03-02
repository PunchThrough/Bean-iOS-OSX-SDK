//
//  BeanLocator.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BeanManager.h"
//#import "BeanRecord.h"

typedef enum { //These occur in sequence
    discovered,
    attemptingConnection,
    attemptingValidation,
    connected,
    attemptingDisconnection
} BeanRecordConnectionState;

@interface BeanRecord : NSObject
@property (strong, nonatomic) NSDate       * last_seen;
@property (strong, nonatomic) CBPeripheral * peripheral;
@property (strong, nonatomic) NSNumber     * rssi;
@property (strong, nonatomic) NSDictionary * advertisementData;
@property (strong, nonatomic) Bean         * bean;
@property (nonatomic) BeanRecordConnectionState        state;
@end
@implementation BeanRecord
@end


@interface BeanManager () <CBCentralManagerDelegate, BeanDelegate>
@end

@implementation BeanManager{
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

-(id)initWithDelegate:(id<BeanManagerDelegate>)delegate{
    self.delegate = delegate;
    return [self init];
}

-(BeanManagerState)state{
    return cbcentralmanager?(BeanManagerState)cbcentralmanager.state:0;
}

-(void)startScanningForBeans_error:(NSError**)error{
    // Bluetooth must be ON
    if (cbcentralmanager.state != CBCentralManagerStatePoweredOn)
    {
        if (error) *error = [BEAN_Helper basicError:@"Bluetooth is not on" domain:NSStringFromClass([self class]) code:100];
        return;
    }
    
    // Scan for peripherals
    NSLog(@"Started scanning...");
    
    //Clear array of previously discovered peripherals.
    [beanRecords removeAllObjects];
    
    // Define array of app service UUID
    NSArray * services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:GLOBAL_SERIAL_PASS_SERVICE_UUID], nil];
    
    //Begin scanning
    [cbcentralmanager scanForPeripheralsWithServices:services options:0];

}

-(void)stopScanningForBeans_error:(NSError**)error{
    // Bluetooth must be ON
    if (cbcentralmanager.state != CBCentralManagerStatePoweredOn)
    {
        if (error) *error = [BEAN_Helper basicError:@"Bluetooth is not on" domain:@"API:BLE Connection" code:100];
        return;
    }
    
    [cbcentralmanager stopScan];
    
    NSLog(@"Stopped scanning.");
}

-(void)connectToBeanWithUUID:(NSUUID*)uuid error:(NSError**)error{
    //Find BeanRecord that corresponds to this UUID
    BeanRecord* beanRecord = [beanRecords objectForKey:uuid];
    //If there is no such peripheral, return error
    if(!beanRecord){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. No peripheral discovered with the corresponding UUID." domain:NSStringFromClass([self class]) code:100];
        return;
    }
    //Check if the device is already connected
    else if(beanRecord.state == connected){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. A device with this UUID is already connected" domain:NSStringFromClass([self class]) code:100];
        return;
    }
    //Check if the device is already in the middle of an attempted connected
    else if(beanRecord.state == attemptingValidation || beanRecord.state == attemptingConnection){
        if(error) *error = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. A device with this UUID is in the process of being connected to." domain:NSStringFromClass([self class]) code:100];
        return;
    }
    //Mark this BeanRecord as is in the middle of a connection attempt
    [beanRecord setState:attemptingConnection];
    //Attempt to connect to the corresponding CBPeripheral
    [cbcentralmanager connectPeripheral:[beanRecord peripheral] options:nil];
}

-(void)disconnectBeanWithUUID:(NSUUID*)uuid error:(NSError**)error{
    //Find BeanPeripheral that corresponds to this UUID
    BeanRecord* beanRecord = [beanRecords objectForKey:uuid];
    //Check if the device isn't currently connected
    if(!beanRecord || beanRecord.state != connected){
        if(error) *error = [BEAN_Helper basicError:@"Failed attemp to disconnect Bean. No device with this UUID is currently connected" domain:NSStringFromClass([self class]) code:100];
        return;
    }
    //Mark this BeanRecord as is in the middle of a disconnection attempt
    [beanRecord setState:attemptingDisconnection];
    //Attempt to disconnect from the corresponding CBPeripheral
    [cbcentralmanager cancelPeripheralConnection:[beanRecord peripheral]];
}


#pragma mark - Private methods


#pragma mark - BeanDelegate methods

-(void)beanIsValid:(Bean*)device error:(NSError*)error{
    NSError* localError;
    //Find BeanRecord that corresponds to this UUID
    BeanRecord* beanRecord = [beanRecords objectForKey:[device identifier]];
    //If there is no such peripheral, return error
    if(!beanRecord){
        localError = [BEAN_Helper basicError:@"Attemp to connect to Bean failed. No peripheral discovered with the corresponding UUID." domain:NSStringFromClass([self class]) code:100];
    }
    else if (error){
        localError = error;
        beanRecord.state = discovered;
    }else{
        beanRecord.state = connected;
    }
    //Notify Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didConnectToBean:error:)]){
        [self.delegate BeanManager:self didConnectToBean:device error:error];
    }
}


#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    //Notify delegate of state
    if (self.delegate && [self.delegate respondsToSelector:@selector(beanManagerDidUpdateState:)]){
        [self.delegate beanManagerDidUpdateState:self];
    }
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"%@: Bluetooth ON", self.class.description);
            break;
            
        default:
            NSLog(@"%@: Bluetooth state error: %ld", self.class.description, central.state);
            break;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    BeanRecord * beanRecord;
    //This Bean is already discovered and perhaps connected to
    if ((beanRecord = [beanRecords objectForKey:peripheral.identifier])) {
        beanRecord.rssi = RSSI;
        beanRecord.last_seen = [NSDate date];
    }
    else { // A new undiscovered Bean
        NSLog(@"centralManager:didDiscoverPeripheral %@", peripheral);
        beanRecord = [BeanRecord new];
        beanRecord.peripheral = peripheral;
        beanRecord.rssi = RSSI;
        beanRecord.last_seen = [NSDate date];
        beanRecord.advertisementData = advertisementData;
        beanRecord.state = discovered;
        [beanRecords setObject:beanRecord forKey:peripheral.identifier];
    }
    //Inform the delegate that we located a Bean
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didDiscoverBean:uuid:error:)]){
        NSDictionary *beanData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [advertisementData objectForKey:CBAdvertisementDataLocalNameKey]?[advertisementData objectForKey:CBAdvertisementDataLocalNameKey]:@"No Name", @"Name",
                                  RSSI?RSSI:[NSNumber numberWithInt:0], @"RSSI",
                                  peripheral.identifier?peripheral.identifier:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"], @"UUID", 
                                     nil];
        
        [self.delegate BeanManager:self didDiscoverBean:beanData uuid:peripheral.identifier error:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //Find BeanRecord that corresponds to this UUID
    BeanRecord* beanRecord = [beanRecords objectForKey:[peripheral identifier]];
    //If there is no such peripheral, return
    if(!beanRecord)return;
    //Mark Bean peripheral as no longer being in a connection attempt
    beanRecord.state = attemptingValidation;
    //Instantiate bean object
    Bean* bean = [[Bean alloc] initWithPeripheral:peripheral delegate:self];
    //Add Bean to corresponding record
    beanRecord.bean = bean;
    //Wait for Bean validation before responding to delegate
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //Find BeanRecord that corresponds to this UUID
    BeanRecord* beanRecord = [beanRecords objectForKey:[peripheral identifier]];
    //If there is no such peripheral, return
    if(!beanRecord)return;
    //Mark Bean peripheral as no longer being in a connection attempt
    beanRecord.state = discovered;
    //Make sure that there is an error to pass along
    if(!error)return;
    //Notify delegate of failure
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didConnectToBean:error:)]){
        [self.delegate BeanManager:self didConnectToBean:nil error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //Find BeanRecord that corresponds to this UUID
    BeanRecord* beanRecord = [beanRecords objectForKey:[peripheral identifier]];
    if(beanRecord){
        //Mark Bean peripheral as no longer being connected
        beanRecord.state = discovered;
        beanRecord.bean = nil;
    }else if (!error){ //No Record of this Bean and there is no error
        return;
    }
    
    if(!beanRecord.bean) return; //This may not be the best way to handle this case
    //Alert the delegate of the disconnect
    if (self.delegate && [self.delegate respondsToSelector:@selector(BeanManager:didDisconnectBean:error:)]){
        [self.delegate BeanManager:self didDisconnectBean:(beanRecord.bean) error:error];
    }
}


@end
