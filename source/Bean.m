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
#import "AppMessages.h"
#import "AppMessagingLayer.h"

#define ARDUINO_OAD_MAX_CHUNK_SIZE 64
//#define ARDUINO_OAD_RESET_BEFORE_DL 1

typedef enum { //These occur in sequence
    BeanArduinoOADLocalState_Inactive = 0,
	BeanArduinoOADLocalState_ResettingRemote,
	BeanArduinoOADLocalState_SendingStartCommand,
    BeanArduinoOADLocalState_SendingChunks,
    BeanArduinoOADLocalState_Finished,
} BeanArduinoOADLocalState;

@interface Bean () <CBPeripheralDelegate, ProfileDelegate_Protocol, AppMessagingLayerDelegate, OAD_Delegate>
@end

@implementation Bean
{
	BeanState                   _state;
    NSNumber*                   _RSSI;
	NSDictionary*               _advertisementData;
    NSDate*                     _lastDiscovered;
	BeanManager*                _beanManager;
    CBPeripheral*               _peripheral;
    
    AppMessagingLayer*          appMessageLayer;
    
    NSInteger                   validatedProfileCount;
    NSArray*                    profiles;
    DevInfoProfile*             deviceInfo_profile;
    OadProfile*                 oad_profile;
    GattSerialProfile*          gatt_serial_profile;
    
    NSData*                     arduinoFwImage;
    NSInteger                   arduinoFwImage_chunkIndex;
    BeanArduinoOADLocalState    localArduinoOADState;
    NSTimer*                    arduinoOADStateTimout;
    NSTimer*                    arduinoOADChunkSendTimer;
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
    if(_state == BeanState_ConnectedAndValidated &&
       _peripheral.state == CBPeripheralStateConnected) //This second conditional is an assertion
    {
        [appMessageLayer sendMessageWithID:MSG_ID_DB_LOOPBACK andPayload:[BEAN_Helper dummyData:length]];
    }
}

-(void)sendSerialMessage:(NSData*)data{
    if(_state == BeanState_ConnectedAndValidated &&
       _peripheral.state == CBPeripheralStateConnected) //This second conditional is an assertion
    {
        [appMessageLayer sendMessageWithID:MSG_ID_SERIAL_DATA andPayload:data];
    }
}

-(void)programArduinoWithRawHexImage:(NSData*)hexImage{
    if(_state == BeanState_ConnectedAndValidated &&
       _peripheral.state == CBPeripheralStateConnected) //This second conditional is an assertion
    {
        [self __resetArduinoOADLocals];
        arduinoFwImage = hexImage;
        
        UInt8 commandPayloadBytes[3];
        NSData* commandPayload;
#if defined(ARDUINO_OAD_RESET_BEFORE_DL)
        commandPayloadBytes[0] = BL_CMD_RESET;
        commandPayloadBytes[1] = 0x00;
        commandPayloadBytes[2] = 0x00;
        commandPayload = [[NSData alloc] initWithBytes:commandPayloadBytes length:3];
        [appMessageLayer sendMessageWithID:MSG_ID_BL_CMD andPayload:commandPayload];
        localArduinoOADState = BeanArduinoOADLocalState_ResettingRemote;
#else
        UInt16 imageSize = [arduinoFwImage length];
        commandPayloadBytes[0] = BL_CMD_START_PRG;
        commandPayloadBytes[1] = (UInt8)(imageSize & 0xFF); //FW size LSB
        commandPayloadBytes[2] = (UInt8)((imageSize >> 8) & 0xFF); //FW size MSB
        commandPayload = [[NSData alloc] initWithBytes:commandPayloadBytes length:3];
        [appMessageLayer sendMessageWithID:MSG_ID_BL_CMD andPayload:commandPayload];
        localArduinoOADState = BeanArduinoOADLocalState_SendingStartCommand;
#endif
        [self __setArduinoOADTimeout:ARDUINO_OAD_GENERIC_TIMEOUT_SEC];
    }else{
         NSError* error = [BEAN_Helper basicError:@"Bean isn't connected" domain:NSStringFromClass([self class]) code:100];
        [self __alertDelegateOfArduinoOADCompletion:error];
    }
}

-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath{
    if(!oad_profile)return FALSE;
    return [oad_profile updateFirmwareWithImageAPath:imageApath andImageBPath:imageBpath];
}

#pragma mark - Protected Methods
-(id)initWithPeripheral:(CBPeripheral*)peripheral beanManager:(BeanManager*)manager{
    self = [super init];
    if (self) {
        _beanManager = manager;
        _peripheral = peripheral;
        _peripheral.delegate = self;
        localArduinoOADState = BeanArduinoOADLocalState_Inactive;
    }
    return self;
}

-(void)interrogateAndValidate{
    //Initialize BLE Profiles
    validatedProfileCount = 0;
    deviceInfo_profile = [[DevInfoProfile alloc] initWithPeripheral:_peripheral];
    deviceInfo_profile.profileDelegate = self;
    oad_profile = [[OadProfile alloc] initWithPeripheral:_peripheral  delegate:self];
    oad_profile.profileDelegate = self;
    gatt_serial_profile = [[GattSerialProfile alloc] initWithPeripheral:_peripheral  delegate:nil];
    gatt_serial_profile.profileDelegate = self;
    profiles = [[NSArray alloc] initWithObjects:deviceInfo_profile,
                oad_profile, //TODO: Add this line back in once the CC has OAD prifile
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

-(void)__alertDelegateOfArduinoOADCompletion:(NSError*)error{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(bean:didProgramArduinoWithError:)]){
            [_delegate bean:self didProgramArduinoWithError:error];
        }
    }
}
-(void)__resetArduinoOADLocals{
    arduinoFwImage = nil;
    arduinoFwImage_chunkIndex = 0;
    localArduinoOADState = BeanArduinoOADLocalState_Inactive;
    if (arduinoOADStateTimout) [arduinoOADStateTimout invalidate];
    arduinoOADStateTimout = nil;
    if (arduinoOADChunkSendTimer) [arduinoOADChunkSendTimer invalidate];
    arduinoOADChunkSendTimer = nil;
}
-(void)__setArduinoOADTimeout:(NSTimeInterval)duration{
    if (arduinoOADStateTimout) [arduinoOADStateTimout invalidate];
    arduinoOADStateTimout = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(__arduinoOADTimeout:) userInfo:nil repeats:NO];
}
-(void)__arduinoOADTimeout:(NSTimer*)timer{
    localArduinoOADState = BeanArduinoOADLocalState_Inactive;
    NSError* error = [BEAN_Helper basicError:@"Arduino programming failed" domain:NSStringFromClass([self class]) code:100];
    [self __alertDelegateOfArduinoOADCompletion:error];
}

-(void)__sendArduinoOADChunk{ //Call this once. It will continue until the entire FW has been unloaded
    if(arduinoFwImage_chunkIndex >= arduinoFwImage.length){
        if (arduinoOADChunkSendTimer) [arduinoOADChunkSendTimer invalidate];
        arduinoOADChunkSendTimer = nil;
    }else{
        NSInteger chunksize = (arduinoFwImage_chunkIndex + ARDUINO_OAD_MAX_CHUNK_SIZE > arduinoFwImage.length)? arduinoFwImage.length-arduinoFwImage_chunkIndex:ARDUINO_OAD_MAX_CHUNK_SIZE;
        
        NSData* chunk = [arduinoFwImage subdataWithRange:NSMakeRange(arduinoFwImage_chunkIndex, chunksize)];
        arduinoFwImage_chunkIndex+=chunksize;

        [appMessageLayer sendMessageWithID:MSG_ID_BL_FW_BLOCK andPayload:chunk];
        
        if (arduinoOADChunkSendTimer) [arduinoOADChunkSendTimer invalidate];
        arduinoOADChunkSendTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(__sendArduinoOADChunk) userInfo:nil repeats:NO];
    }
}
-(void)__handleArduinoOADRemoteStateChange:(BL_HL_STATE_T)state{
    UInt8 startBytes[] = {BL_CMD_START_PRG, 0x00, 0x00};
    NSData* data;
    switch (state) {
        case BL_HL_STATE_NULL:
            break;
        case BL_HL_STATE_INIT:
#if defined(ARDUINO_OAD_RESET_BEFORE_DL)
            if(localArduinoOADState == BeanArduinoOADLocalState_ResettingRemote){
                if (arduinoOADStateTimout) [arduinoOADStateTimout invalidate];
                data = [[NSData alloc] initWithBytes:startBytes length:3];
                [appMessageLayer sendMessageWithID:MSG_ID_BL_CMD andPayload:data];
                localArduinoOADState = BeanArduinoOADLocalState_SendingStartCommand;
                [self __setArduinoOADTimeout:ARDUINO_OAD_GENERIC_TIMEOUT_SEC];
            }
#endif
            break;
        case BL_HL_STATE_READY:
            if(localArduinoOADState == BeanArduinoOADLocalState_SendingStartCommand){
                if (arduinoOADStateTimout) [arduinoOADStateTimout invalidate];
                //Send first Chunk
                [self __sendArduinoOADChunk];
                localArduinoOADState = BeanArduinoOADLocalState_SendingChunks;
            }
            break;
        case BL_HL_STATE_PROGRAMMING:
            break;
        case BL_HL_STATE_VERIFY:
            break;
        case BL_HL_STATE_COMPLETE:
            [self __alertDelegateOfArduinoOADCompletion:nil];
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Profile Delegate callbacks
-(void)profileValidated:(id<Profile_Protocol>)profile{
    if(validatedProfileCount >= [profiles count]){
        //Initialize Application Messaging layer
        appMessageLayer = [[AppMessagingLayer alloc] initWithGattSerialProfile:gatt_serial_profile];
        appMessageLayer.delegate = self;
        gatt_serial_profile.delegate = appMessageLayer;
        
        if(_beanManager){
            if([_beanManager respondsToSelector:@selector(bean:hasBeenValidated_error:)]){
                [_beanManager bean:self hasBeenValidated_error:nil];
            }
        }
    }else{
        [self __validateNextProfile];
    }
}

#pragma mark AppMessagingLayerDelegate callbacks
-(void)appMessagingLayer:(AppMessagingLayer*)layer recievedIncomingMessageWithID:(UInt16)identifier andPayload:(NSData*)payload{
    BOOL isReply = identifier & APP_MSG_RESPONSE_BIT;
    UInt16 identifier_type = identifier & ~(APP_MSG_RESPONSE_BIT);
    switch (identifier_type) {
        case MSG_ID_SERIAL_DATA:
            NSLog(@"App Message Received: MSG_ID_SERIAL_DATA: %@", payload);
            break;
        case MSG_ID_BT_SET_ADV:
            NSLog(@"App Message Received: MSG_ID_BT_SET_ADV: %@", payload);
            break;
        case MSG_ID_BT_SET_CONN:
            NSLog(@"App Message Received: MSG_ID_BT_SET_CONN: %@", payload);
            break;
        case MSG_ID_BT_SET_LOCAL_NAME:
            NSLog(@"App Message Received: MSG_ID_BT_SET_LOCAL_NAME: %@", payload);
            break;
        case MSG_ID_BT_SET_PIN:
            NSLog(@"App Message Received: MSG_ID_BT_SET_PIN: %@", payload);
            break;
        case MSG_ID_BT_SET_TX_PWR:
            NSLog(@"App Message Received: MSG_ID_BT_SET_TX_PWR: %@", payload);
            break;
        case MSG_ID_BT_GET_CONFIG:
            NSLog(@"App Message Received: MSG_ID_BT_GET_CONFIG: %@", payload);
            break;
        case MSG_ID_BT_ADV_ONOFF:
            NSLog(@"App Message Received: MSG_ID_BT_ADV_ONOFF: %@", payload);
            break;
        case MSG_ID_BT_SET_SCRATCH:
            NSLog(@"App Message Received: MSG_ID_BT_SET_SCRATCH: %@", payload);
            break;
        case MSG_ID_BT_GET_SCRATCH:
            NSLog(@"App Message Received: MSG_ID_BT_GET_SCRATCH: %@", payload);
            break;
        case MSG_ID_BT_RESTART:
            NSLog(@"App Message Received: MSG_ID_BT_RESTART: %@", payload);
            break;
        case MSG_ID_BL_CMD:
            NSLog(@"App Message Received: MSG_ID_BL_CMD: %@", payload);
            break;
        case MSG_ID_BL_FW_BLOCK:
            NSLog(@"App Message Received: MSG_ID_BL_FW_BLOCK: %@", payload);
            break;
        case MSG_ID_BL_STATUS:
            NSLog(@"App Message Received: MSG_ID_BL_STATUS: %@", payload);
            UInt8 byte;
            [payload getBytes:&byte length:1];
            BL_HL_STATE_T highLevelStatus = byte;
            [self __handleArduinoOADRemoteStateChange:highLevelStatus];
            break;
        case MSG_ID_CC_LED_WRITE:
            NSLog(@"App Message Received: MSG_ID_CC_LED_WRITE: %@", payload);
            break;
        case MSG_ID_CC_LED_WRITE_ALL:
            NSLog(@"App Message Received: MSG_ID_CC_LED_WRITE_ALL: %@", payload);
            break;
        case MSG_ID_CC_LED_READ_ALL:
            NSLog(@"App Message Received: MSG_ID_CC_LED_READ_ALL: %@", payload);
            break;
        case MSG_ID_CC_ACCEL_READ:
            NSLog(@"App Message Received: MSG_ID_CC_ACCEL_READ: %@", payload);
            break;
        case MSG_ID_DB_LOOPBACK:
            NSLog(@"App Message Received: MSG_ID_DB_LOOPBACK: %@", payload);
            break;
        case MSG_ID_DB_COUNTER:
            NSLog(@"App Message Received: MSG_ID_DB_COUNTER: %@", payload);
            break;
            
        default:
            break;
    }
}
-(void)appMessagingLayer:(AppMessagingLayer*)later error:(NSError*)error{
    
}


#pragma mark OAD callbacks
-(void)device:(OadProfile*)device completedFirmwareUploadWithError:(NSError*)error{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(bean:completedFirmwareUploadWithError:)]){
            [_delegate bean:self completedFirmwareUploadWithError:error];
        }
    }
}
-(void)device:(OadProfile*)device OADUploadTimeLeft:(NSNumber*)seconds withPercentage:(NSNumber*)percentageComplete{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(bean:firmwareUploadTimeLeft:withPercentage:)]){
            [_delegate bean:self firmwareUploadTimeLeft:seconds withPercentage:percentageComplete];
        }
    }
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
