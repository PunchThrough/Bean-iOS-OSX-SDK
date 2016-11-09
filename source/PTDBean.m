#import "PTDBean.h"
#import "PTDBean+Protected.h"
#import "PTDBeanManager+Protected.h"
#import "GattSerialProfile.h"
#import "AppMessages.h"
#import "AppMessagingLayer.h"
#import "NSData+CRC.h"
#import "PTDBeanRadioConfig.h"
#import "CBPeripheral+RSSI_Universal.h"
#import "PTDBeanRemoteFirmwareVersionManager.h"
#import "PTDFirmwareHelper.h"

#define ARDUINO_OAD_MAX_CHUNK_SIZE 64

typedef enum { //These occur in sequence
    BeanArduinoOADLocalState_Inactive = 0,
	BeanArduinoOADLocalState_ResettingRemote,
	BeanArduinoOADLocalState_SendingStartCommand,
    BeanArduinoOADLocalState_SendingChunks,
    BeanArduinoOADLocalState_Finished,
} BeanArduinoOADLocalState;

@interface PTDBean () <CBPeripheralDelegate, AppMessagingLayerDelegate, OAD_Delegate, BatteryProfileDelegate,
                       DevInfoProfileDelegate>

#pragma mark - Header readonly overrides

@property (nonatomic, readwrite) BOOL updateInProgress;
@property (nonatomic, readwrite) BOOL uploadInProgress;
@property (nonatomic, readwrite) NSString *sketchName;
@property (nonatomic, readwrite) NSString *targetFirmwareVersion;
@property (nonatomic, copy) void (^firmwareVersionAvailableHandler)(BOOL firmwareAvailable, NSError *error);
@property (nonatomic, copy) void (^hardwareVersionAvailableHandler)(BOOL hardwareAvailable, NSError *error);

@end

@implementation PTDBean
{
	id<PTDBeanManager>          _beanManager;
    
    AppMessagingLayer*          appMessageLayer;
    
    NSSet*                      profilesRequiredForConnection;
    NSMutableSet*               profilesValidated;

    DevInfoProfile*             deviceInfo_profile;
    OadProfile*                 oad_profile;
    GattSerialProfile*          gatt_serial_profile;
    BatteryProfile*             battery_profile;
    
    NSData*                     arduinoFwImage;
    NSInteger                   arduinoFwImage_chunkIndex;
    BeanArduinoOADLocalState    localArduinoOADState;
    NSTimer*                    arduinoOADStateTimout;
    NSTimer*                    arduinoOADChunkSendTimer;
    NSDate*                     firmwareUpdateStartTime;
        
}
// Adding the "dynamic" directive tells the compiler that It doesn't need to create the getter, setter, and ivar.
// This is assumed to have already been done in a superclass, or will be done during runtime.
// In this case, getter, setter, and ivar are already up by the superclass, PTDBleDevice
@dynamic delegate, name, state, identifier, lastDiscovered, advertisementData;

//Enforce that you can't use the "init" function of this class
- (id)init{
    NSAssert(false, @"Please use the \"initWithPeripheral:\" method to instantiate this class");
    return nil;
}

#pragma mark - Public Methods

- (BOOL)isEqualToBean:(PTDBean *)bean {
    return [self isEqual:bean];
}

#pragma mark - SDK
-(NSNumber*)batteryVoltage{
    if([self connected]
       && battery_profile
       && [battery_profile batteryVoltage]){
        return [battery_profile batteryVoltage];
    }
    return nil;
}
-(NSString*)firmwareVersion{
    if(deviceInfo_profile){
        return deviceInfo_profile.firmwareVersion;
    }
    return nil;
}
-(NSString*)hardwareVersion{
    if(deviceInfo_profile){
        return deviceInfo_profile.hardwareVersion;
    }
    return nil;
}

-(PTDBeanManager*)beanManager{
    if(_beanManager){
        if([_beanManager isKindOfClass:[PTDBeanManager class]]){
            return _beanManager;
        }
    }
    return nil;
}

- (void)releaseSerialGate {
  [appMessageLayer sendMessageWithID:MSG_ID_BT_END_GATE andPayload:nil];
}

- (BOOL)setPairingPin:(NSUInteger*)pinCode{
    if(![self connected]) {
        return FALSE;
    }
    
    if(pinCode){
        NSInteger pin = (UInt32)(*pinCode);
        if(pin < 0 || pin > 999999){
            //Pairing pin is not a positive integer with 6 digits or less
            return FALSE;
        }
    }
    BT_SET_PIN_T payload;
    payload.pinCode = pinCode?(UInt32)(*pinCode):(UInt32)0;
    payload.pincodeActive = pinCode?TRUE:FALSE;
    NSData *data = [NSData dataWithBytes:&payload length: sizeof(BT_SET_PIN_T)];
    [appMessageLayer sendMessageWithID:MSG_ID_BT_SET_PIN andPayload:data];
    return TRUE;
}
-(void)readArduinoSketchInfo{
    if(![self connected]) {
        return;
    }
    [appMessageLayer sendMessageWithID:MSG_ID_BL_GET_META andPayload:nil];
}
-(void)setArduinoPowerState:(ArduinoPowerState)state{
    if(![self connected])return;
    if(!(state == ArduinoPowerState_Off || state == ArduinoPowerState_On)) return;
    UInt8 byte = (state==ArduinoPowerState_On)?0x01:0x00;
    [appMessageLayer sendMessageWithID:MSG_ID_CC_POWER_ARDUINO andPayload:[NSData dataWithBytes:&byte length:1]];
    _arduinoPowerState = state;
}
-(void)readArduinoPowerState{
    if(![self connected])return;
    [appMessageLayer sendMessageWithID:MSG_ID_CC_GET_AR_POWER andPayload:nil];
}
-(void)programArduinoWithRawHexImage:(NSData*)hexImage andImageName:(NSString*)name{
    if(self.state == BeanState_ConnectedAndValidated &&
       self.peripheral.state == CBPeripheralStateConnected) //This second conditional is an assertion
    {
        [self __resetArduinoOADLocals];
        arduinoFwImage = hexImage?hexImage:[[NSData alloc] init];
        
        BL_SKETCH_META_DATA_T startPayload;
        NSData* commandPayload;
        UInt32 imageSize = (UInt32)[arduinoFwImage length];
        startPayload.hexSize = imageSize;
        startPayload.timestamp = [[NSDate date] timeIntervalSince1970];
        startPayload.hexCrc = [arduinoFwImage crc32];
        
        NSInteger maxNameLength = member_size(BL_SKETCH_META_DATA_T,hexName);
        if([name length] > maxNameLength){
            startPayload.hexNameSize = maxNameLength;
            const UInt8* nameBytes = [[[name substringWithRange:NSMakeRange(0,maxNameLength)] dataUsingEncoding:NSUTF8StringEncoding] bytes];
            memcpy(&(startPayload.hexName), nameBytes, maxNameLength);
        }else{
            startPayload.hexNameSize = [name length];
            const UInt8* nameBytes = [[name dataUsingEncoding:NSUTF8StringEncoding] bytes];
            memset(&(startPayload.hexName), ' ', maxNameLength);
            memcpy(&(startPayload.hexName), nameBytes, maxNameLength);
        }
        
        commandPayload = [[NSData alloc] initWithBytes:&startPayload length:sizeof(BL_SKETCH_META_DATA_T)];
        [appMessageLayer sendMessageWithID:MSG_ID_BL_CMD_START andPayload:commandPayload];

        localArduinoOADState = BeanArduinoOADLocalState_SendingStartCommand;
        if(imageSize!=0){
            self.uploadInProgress = YES;
            [self __setArduinoOADTimeout:ARDUINO_OAD_GENERIC_TIMEOUT_SEC];
        }else{
            [self __resetArduinoOADLocals];
        }
    }else{
        NSError* error = [BEAN_Helper basicError:@"Bean isn't connected" domain:NSStringFromClass([self class]) code:100];
        if (self.uploadInProgress) {
            [self __alertDelegateOfArduinoOADCompletion:error];
        }
    }
}
-(void)sendSerialData:(NSData*)data{
    if(![self connected]) {
        return;
    }
    [appMessageLayer sendMessageWithID:MSG_ID_SERIAL_DATA andPayload:data];
}
-(void)sendSerialString:(NSString*)string{
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self sendSerialData:data];
}
- (void)readRadioConfig {
    if(![self connected]) {
        PTDLog(@"Can't read radio config, not connect.");
        return;
    }
    PTDLog(@"Sending command to read radio config.");
    [appMessageLayer sendMessageWithID:MSG_ID_BT_GET_CONFIG andPayload:nil];
}
-(void)setRadioConfig:(PTDBeanRadioConfig*)config {
    if(![self connected]) {
        return;
    }
    BT_RADIOCONFIG_T raw;
    raw.adv_int = config.advertisingInterval;
    raw.conn_int = config.connectionInterval;
    raw.adv_mode = config.advertisingMode;
    raw.ibeacon_uuid = config.iBeacon_UUID;
    raw.ibeacon_major = config.iBeacon_majorID;
    raw.ibeacon_minor = config.iBeacon_minorID;
    
    const UInt8* nameBytes = [[config.name dataUsingEncoding:NSUTF8StringEncoding] bytes];
    UInt8 nameBytesLength = [[config.name dataUsingEncoding:NSUTF8StringEncoding] length];
    memset(&(raw.local_name), ' ', nameBytesLength);
    memcpy(&(raw.local_name), nameBytes, nameBytesLength);
    
    raw.local_name_size = nameBytesLength;
    raw.power = config.power;
    NSData *data = [NSData dataWithBytes:&raw length: sizeof(BT_RADIOCONFIG_T)];
    if ( config.configSave )
        [appMessageLayer sendMessageWithID:MSG_ID_BT_SET_CONFIG andPayload:data];
    else
        [appMessageLayer sendMessageWithID:MSG_ID_BT_SET_CONFIG_NOSAVE andPayload:data];

}
-(void)readAccelerationAxes {
    if(![self connected]) {
        return;
    }
    [appMessageLayer sendMessageWithID:MSG_ID_CC_ACCEL_READ andPayload:nil];
}
-(void)readBatteryVoltage{
    if(battery_profile){
        [battery_profile readBattery];
    }
}
-(void)readTemperature {
    if(![self connected]) {
        return;
    }
    [appMessageLayer sendMessageWithID:MSG_ID_CC_TEMP_READ andPayload:nil];
}
#if TARGET_OS_IPHONE
-(void)setLedColor:(UIColor*)color
#else
-(void)setLedColor:(NSColor*)color
#endif
{
    if(![self connected]) {
        return;
    }
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    UInt8 redComponent = (alpha)*(red)*255.0;
    UInt8 greenComponent = (alpha)*(green)*255.0;
    UInt8 blueComponent = (alpha)*(blue)*255.0;
    UInt8 bytes[] = {redComponent,greenComponent,blueComponent};
    NSData *data = [NSData dataWithBytes:bytes length:3];
    
    [appMessageLayer sendMessageWithID:MSG_ID_CC_LED_WRITE_ALL andPayload:data];
}
-(void)readLedColor {
    if(![self connected]) {
        return;
    }
    [appMessageLayer sendMessageWithID:MSG_ID_CC_LED_READ_ALL andPayload:nil];
}
    
-(void)setScratchBank:(NSInteger)bank data:(NSData*)data{
    if(![self connected]) {
        return;
    }
    if(![self validScratchNumber:bank]) {
        return;
    }
    if (data.length>20) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(bean:error:)]) {
            NSError *error = [BEAN_Helper basicError:@"Scratch value exceeds 20 character limit" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
            [self.delegate bean:self error:error];
        }
        data = [data subdataWithRange:NSMakeRange(0, 20)];
    }
    UInt8 bankNum = bank;
    NSMutableData *payload = [NSMutableData dataWithBytes:&bankNum length:1];
    [payload appendData:data];
    [appMessageLayer sendMessageWithID:MSG_ID_BT_SET_SCRATCH andPayload:payload];
}
- (void)readScratchBank:(NSInteger)bank {
    if(![self connected]) {
        return;
    }
    if(![self validScratchNumber:bank]) {
        return;
    }
    NSData *data = [NSData dataWithBytes:&bank length: sizeof(UInt8)];
    [appMessageLayer sendMessageWithID:MSG_ID_BT_GET_SCRATCH andPayload:data];
}
-(void)getConfig {
    if(![self connected]) {
        return;
    }
    [appMessageLayer sendMessageWithID:MSG_ID_BT_GET_CONFIG andPayload:nil];
}
    
- (void)checkFirmwareVersionAvailableWithHandler:(void (^)(BOOL firmwareAvailable, NSError *error))handler{
    
    if ( [self firmwareVersion] ) {
        handler( YES, nil );
    } else {
        self.firmwareVersionAvailableHandler = handler;   // Wait until device info is valid
    }
}

- (void)checkHardwareVersionAvailableWithHandler:(void (^)(BOOL hardwareAvailable, NSError *error))handler{
    
    if ( [self hardwareVersion] ) {
        handler( YES, nil );
    } else {
        self.hardwareVersionAvailableHandler = handler;   // Wait until device info is valid
    }
}

- (FirmwareStatus)firmwareUpdateAvailable:(NSString *)bakedFirmwareVersion error:(NSError * __autoreleasing *)error
{
    return [PTDFirmwareHelper firmwareUpdateRequiredForBean:self availableFirmware:bakedFirmwareVersion withError:error];
}

- (void)updateFirmwareWithImages:(NSArray *)images andTargetVersion:(NSString *)version
{
    self.targetFirmwareVersion = version;

    if(!oad_profile && self.delegate && [self.delegate respondsToSelector:@selector(bean:completedFirmwareUploadWithError:)]) {
        NSError* error = [BEAN_Helper basicError:@"OAD profile not present!" domain:NSStringFromClass([self class]) code:0];
        [(id<PTDBeanExtendedDelegate>)self.delegate bean:self completedFirmwareUploadWithError:error];
        return;
    }
    
    _updateInProgress = TRUE;
    _updateStepNumber++;
    if (!firmwareUpdateStartTime) firmwareUpdateStartTime = [NSDate date];

    [oad_profile updateFirmwareWithImagePaths:images];
}

- (void)cancelFirmwareUpdate{
    if (self.updateInProgress) {
        _updateInProgress = FALSE;
        if (oad_profile)
            [oad_profile cancel];
    }
}

#pragma mark - Protected Methods
-(id)initWithPeripheral:(CBPeripheral*)peripheral beanManager:(id<PTDBeanManager>)manager{
    self = [super initWithPeripheral:peripheral];
    if (self) {
        _beanManager = manager;
        localArduinoOADState = BeanArduinoOADLocalState_Inactive;
        _arduinoPowerState = ArduinoPowerState_Unknown;
        
        // Default functionality. Can be overridden with the options parameter in [PTDBeanManager connectToBean:withOptions:error:]
        [self setProfilesRequiredToConnect:@[[BatteryProfile class],
                                                     [DevInfoProfile class],
                                                     [GattSerialProfile class],
                                                     [OadProfile class]
                                                     ]];
    }
    return self;
}

-(void)discoverServices{
    
    oad_profile = nil;
    deviceInfo_profile = nil;
    gatt_serial_profile = nil;
    battery_profile = nil;
    
    [super discoverServices];
    [self __checkIfRequiredProfilesAreValidated];
}
    
-(void)setBeanManager:(id<PTDBeanManager>)manager{
    _beanManager = manager;
}
-(void)setProfilesRequiredToConnect:(NSArray*)classes{
    profilesRequiredForConnection = [NSSet setWithArray:classes];
    profilesValidated = [[NSMutableSet alloc] init];
}
-(void)sendMessage:(GattSerialMessage*)message{
    [gatt_serial_profile sendMessage:message];
}

#pragma mark - Private Methods

-(void)__alertDelegateOfArduinoOADCompletion:(NSError*)error{
    [self __resetArduinoOADLocals];
    self.uploadInProgress = NO;
    if(self.delegate){
        if([self.delegate respondsToSelector:@selector(bean:didProgramArduinoWithError:)]){
            [self.delegate bean:self didProgramArduinoWithError:error];
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
    NSError* error = [BEAN_Helper basicError:@"Sketch upload failed: Arduino communication timed out" domain:NSStringFromClass([self class]) code:0];
    if (self.uploadInProgress) {
        [self __alertDelegateOfArduinoOADCompletion:error];
    }
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
        
        if(self.delegate){
            if([self.delegate respondsToSelector:@selector(bean:ArduinoProgrammingTimeLeft:withPercentage:)]){
                NSNumber* percentComplete = @(arduinoFwImage_chunkIndex * 1.0f / arduinoFwImage.length);
                NSNumber* timeRemaining = @(0.2 * ((arduinoFwImage.length - arduinoFwImage_chunkIndex)/ARDUINO_OAD_MAX_CHUNK_SIZE));
                [self.delegate bean:self ArduinoProgrammingTimeLeft:timeRemaining withPercentage:percentComplete];
            }
        }
    }
}
-(void)__handleArduinoOADRemoteStateChange:(BL_HL_STATE_T)state{
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
                [self __setArduinoOADTimeout:ARDUINO_OAD_GENERIC_TIMEOUT_SEC];
                //Send first Chunk
                [self __sendArduinoOADChunk];
                localArduinoOADState = BeanArduinoOADLocalState_SendingChunks;
            }else{
                [self __setArduinoOADTimeout:ARDUINO_OAD_GENERIC_TIMEOUT_SEC];
            }
            break;
        case BL_HL_STATE_PROGRAMMING:
            [self __setArduinoOADTimeout:ARDUINO_OAD_GENERIC_TIMEOUT_SEC];
            break;
        case BL_HL_STATE_VERIFY:
            break;
        case BL_HL_STATE_COMPLETE:
            [self __alertDelegateOfArduinoOADCompletion:nil];
            
            break;
        case BL_HL_STATE_ERROR:
        {
            NSError *error = [BEAN_Helper basicError:@"Sketch upload failed: Bootloader error" domain:NSStringFromClass([self class]) code:0];
            if (self.uploadInProgress) {
                [self __alertDelegateOfArduinoOADCompletion:error];
            }
            break;
        }
        default:
            break;
    }
}
-(void)__profileHasBeenValidated:(BleProfile*)profile{
    if([profilesRequiredForConnection containsObject:[profile class]]
       && ![profilesValidated containsObject:[profile class]]){
        [profilesValidated addObject:[profile class]];
        
        [self __checkIfRequiredProfilesAreValidated];
    }
}
-(void)__checkIfRequiredProfilesAreValidated{
    
    if([profilesRequiredForConnection isEqualToSet:profilesValidated])
    {
        self.uploadInProgress = NO;
        if( _beanManager
           && [_beanManager respondsToSelector:@selector(bean:hasBeenValidated_error:)])
        {
            [_beanManager bean:self hasBeenValidated_error:nil];
        }
    }
}
-(BOOL)connected {
    if(self.state != BeanState_ConnectedAndValidated ||
       self.peripheral.state != CBPeripheralStateConnected) //This second conditional is an assertion
    {
        return NO;
    }
    return YES;
}
-(BOOL)validScratchNumber:(NSInteger)scratchNumber {
    if (scratchNumber<1 || scratchNumber>5) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(bean:error:)]) {
            NSError *error = [BEAN_Helper basicError:@"Scratch numbers need to be 1-5" domain:NSStringFromClass([self class]) code:BeanErrors_InvalidArgument];
            [self.delegate bean:self error:error];
        }
        return NO;
    }
    return YES;
}

#pragma mark OAD firmware logic and state management

/**
 *  Called whenever the firmware version profile is read to ensure Bean's firmware update process continues.
 */
- (void)manageFirmwareUpdateStatus
{
    if ([PTDFirmwareHelper oadImageRunningOnBean:self]) {
        NSLog(@"Bean is running OAD image. Update required.");
        if (self.delegate && [self.delegate respondsToSelector:@selector(beanFoundWithIncompleteFirmware:)])
            [self.delegate beanFoundWithIncompleteFirmware:self];
        return;
    }

    if (!self.updateInProgress) {
        NSLog(@"Bean isn't running OAD image and no update is in progress. No update required.");
        return;
    }

    if (!self.targetFirmwareVersion) {
        NSLog(@"Error: Bean requires update but target firmware version is unknown.");
        return;
    }

    // Update in progress. See what the status of Bean is.
    NSError *error;
    FirmwareStatus updateStatus = [PTDFirmwareHelper firmwareUpdateRequiredForBean:self
                                                                 availableFirmware:self.targetFirmwareVersion
                                                                         withError:&error];
    if (error) {
        NSLog(@"Error fetching Bean update status: %@", error);
        return;
    }

    if (updateStatus == FirmwareStatusBeanNeedsUpdate) {
        // Bean is not fully up-to-date, and an update is in progress right now.
        // This means Bean just reconnected and needs the next image in the update process.
        if (self.delegate && [self.delegate respondsToSelector:@selector(beanFoundWithIncompleteFirmware:)])
            [self.delegate beanFoundWithIncompleteFirmware:self];

    } else if (updateStatus == FirmwareStatusUpToDate) {
        // Update was in progress last time Bean disconnected, and the image is no longer an OAD update image.
        // That means the update was successful and Bean is running a fully functional image.
        [self completeFirmwareUpdateWithError:nil];

    } else {
        // Bean has more current firmware than Loader, or Bean firmware update status couldn't be determined
        NSLog(@"Unexpected Bean update status: FirmwareStatus = %lu", updateStatus);
        NSError *myError = nil;
        [self completeFirmwareUpdateWithError:myError];
    }
}

/**
 *  Called when a Bean that was in the middle of a firmware update process has just reconnected, and it's now running
 *  up to date firmware.
 *
 *  @param error nil if everything went OK, an NSError if something went wrong
 */
- (void)completeFirmwareUpdateWithError:(NSError *)error
{
    firmwareUpdateStartTime = NULL;
    _updateInProgress = FALSE;
    _updateStepNumber = 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(bean:completedFirmwareUploadWithError:)]) {
        [(id<PTDBeanExtendedDelegate>)self.delegate bean:self completedFirmwareUploadWithError:error];
    }
}
    
#pragma mark BleDevice Overridden Methods
-(void)rssiDidUpdateWithError:(NSError*)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(beanDidUpdateRSSI:error:)]) {
        [self.delegate beanDidUpdateRSSI:self error:error];
    }
}

-(void)notificationStateUpdatedWithError:(NSError *)error
{
    if (error.domain == CBATTErrorDomain && error.code == 1 && self.delegate
            && [self.delegate respondsToSelector:@selector(bean:bluetoothError:)]){
        // alert user that bluetooth error occurred where GATT table handles invalid
        [self.delegate bean:self bluetoothError:BeanBluetoothError_InvalidHandle];
    }
}

-(void)servicesHaveBeenModified{
    // TODO: Re-Instantiate the Bean object
}
    
#pragma mark Profile Delegate callbacks
-(void)profileDiscovered:(BleProfile*)profile
{
    if ([profile isMemberOfClass:[OadProfile class]]) {
        oad_profile = (OadProfile*)profile;
        __weak typeof(self) weakSelf = self;
        [oad_profile validateWithCompletion: ^(NSError* error) {
            if ( !error && [oad_profile isValid:nil] ) {
                [weakSelf __profileHasBeenValidated:profile];
            }
        }];

    } else if ([profile isMemberOfClass:[DevInfoProfile class]]) {
        
        deviceInfo_profile = (DevInfoProfile*)profile;
        profile.delegate = self;
        __weak typeof(self) weakSelf = self;
        [deviceInfo_profile validateWithCompletion: ^(NSError* error) {
            if ( !error)
            {
                [weakSelf __profileHasBeenValidated:profile];
            }
        }];

    } else if ([profile isMemberOfClass:[GattSerialProfile class]]) {
        gatt_serial_profile = (GattSerialProfile*)profile;
        appMessageLayer = [[AppMessagingLayer alloc] initWithGattSerialProfile:gatt_serial_profile];
        appMessageLayer.delegate = self;
        gatt_serial_profile.delegate = appMessageLayer;
        __weak typeof(self) weakSelf = self;
        [gatt_serial_profile validateWithCompletion: ^(NSError* error) {
            if ( !error && [gatt_serial_profile isValid:nil] ) {
                [weakSelf __profileHasBeenValidated:profile];
            }
        }];
    } else if ([profile isMemberOfClass:[BatteryProfile class]]) {
        battery_profile = (BatteryProfile*)profile;
        __weak typeof(self) weakSelf = self;
        [battery_profile validateWithCompletion: ^(NSError *error) {
            if ( !error && [battery_profile isValid:nil] ) {
                [weakSelf batteryProfileDidUpdate];
                [weakSelf __profileHasBeenValidated:profile];
            }
        }];
    }
}

#pragma mark -
#pragma mark AppMessagingLayerDelegate callbacks
-(void)appMessagingLayer:(AppMessagingLayer*)layer recievedIncomingMessageWithID:(UInt16)identifier andPayload:(NSData*)payload{
    UInt16 identifier_type = identifier & ~(APP_MSG_RESPONSE_BIT);
    switch (identifier_type) {
        case MSG_ID_SERIAL_DATA:
            PTDLog(@"App Message Received: MSG_ID_SERIAL_DATA: %@", payload);
            if (self.delegate && [self.delegate respondsToSelector:@selector(bean:serialDataReceived:)]) {
                [self.delegate bean:self serialDataReceived:payload];
            }
            break;
        case MSG_ID_BT_SET_ADV:
            PTDLog(@"App Message Received: MSG_ID_BT_SET_ADV: %@", payload);
            break;
        case MSG_ID_BT_SET_TX_PWR:
            PTDLog(@"App Message Received: MSG_ID_BT_SET_TX_PWR: %@", payload);
            break;
        case MSG_ID_BT_GET_CONFIG: {
            PTDLog(@"App Message Received: MSG_ID_BT_GET_CONFIG: %@", payload);
            if(payload.length != sizeof(BT_RADIOCONFIG_T)){
                PTDLog(@"Invalid length of MSG_ID_BT_GET_CONFIG. Most likely an outdated version of FW");
                break;
            }

            BT_RADIOCONFIG_T rawData;
            [payload getBytes:&rawData range:NSMakeRange(0, sizeof(BT_RADIOCONFIG_T))];
            PTDBeanRadioConfig *config = [[PTDBeanRadioConfig alloc] init];
            config.advertisingInterval = rawData.adv_int;
            config.connectionInterval = rawData.conn_int;
            // The (rawData.adv_mode != 0xFF) check is to catch a FW bug!
            config.pairingPinEnabled = ((rawData.adv_mode & 0x80) && (rawData.adv_mode != 0xFF) )?TRUE:FALSE;
            config.advertisingMode = rawData.adv_mode & (~0x80);
            config.iBeacon_UUID = rawData.ibeacon_uuid;
            config.iBeacon_majorID = rawData.ibeacon_major;
            config.iBeacon_minorID = rawData.ibeacon_minor;
            
            config.name = [NSString stringWithUTF8String:(char*)rawData.local_name];
            config.power = rawData.power;
            _radioConfig = config;
            
            PTDLog(@"Radio config - Name: '%@' Advertising interval: %d Connection interval: %d", config.name, rawData.adv_int, rawData.conn_int );
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(bean:didUpdateRadioConfig:)]) {
                [self.delegate bean:self didUpdateRadioConfig:config];
            }
            break;
        }
        case MSG_ID_BT_ADV_ONOFF:
            PTDLog(@"App Message Received: MSG_ID_BT_ADV_ONOFF: %@", payload);
            break;
        case MSG_ID_BT_SET_SCRATCH:
            PTDLog(@"App Message Received: MSG_ID_BT_SET_SCRATCH: %@", payload);
            break;
        case MSG_ID_BT_GET_SCRATCH:
            PTDLog(@"App Message Received: MSG_ID_BT_GET_SCRATCH: %@", payload);
            if (self.delegate) {
                BT_SCRATCH_T rawData;
                [payload getBytes:&rawData range:NSMakeRange(0, payload.length)];
                NSData *scratch = [NSData dataWithBytes:rawData.scratch length:payload.length];
                if([self.delegate respondsToSelector:@selector(bean:didUpdateScratchBank:data:)]){
                    [self.delegate bean:self didUpdateScratchBank:rawData.number data:scratch];
                }
            }
            break;
        case MSG_ID_BT_RESTART:
            PTDLog(@"App Message Received: MSG_ID_BT_RESTART: %@", payload);
            break;
        case MSG_ID_BL_CMD_START:
            PTDLog(@"App Message Received: MSG_ID_BL_CMD_START: %@", payload);
            break;
        case MSG_ID_BL_FW_BLOCK:
            PTDLog(@"App Message Received: MSG_ID_BL_FW_BLOCK: %@", payload);
            break;
        case MSG_ID_BL_STATUS:
            PTDLog(@"App Message Received: MSG_ID_BL_STATUS: %@", payload);
            BL_MSG_STATUS_T stateMsg;
            [payload getBytes:&stateMsg range:NSMakeRange(0, sizeof(BL_MSG_STATUS_T))];
            BL_HL_STATE_T highLevelState = stateMsg.hlState;
            [self __handleArduinoOADRemoteStateChange:highLevelState];
            break;
        case MSG_ID_CC_GET_AR_POWER:
            PTDLog(@"App Message Received: MSG_ID_CC_GET_AR_POWER: %@", payload);
            UInt8 powerState;
            [payload getBytes:&powerState range:NSMakeRange(0, 1)];
            _arduinoPowerState = powerState?ArduinoPowerState_On:ArduinoPowerState_Off;
            if (self.delegate && [self.delegate respondsToSelector:@selector(beanDidUpdateArduinoPowerState:)]) {
                [self.delegate beanDidUpdateArduinoPowerState:self];
            }
            break;
        case MSG_ID_BL_GET_META:
        {
            PTDLog(@"App Message Received: MSG_ID_BL_GET_META: %@", payload);
            BL_SKETCH_META_DATA_T meta;
            [payload getBytes:&meta range:NSMakeRange(0, sizeof(BL_SKETCH_META_DATA_T))];
            UInt8 nameSize = (meta.hexNameSize < member_size(BL_SKETCH_META_DATA_T, hexName))? meta.hexNameSize:member_size(BL_SKETCH_META_DATA_T, hexName);
            NSData* nameBytes = [[NSData alloc] initWithBytes:meta.hexName length:nameSize];
            NSString* name = [[NSString alloc] initWithData:nameBytes encoding:NSUTF8StringEncoding];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:meta.timestamp];
            self.sketchName = name;
            _dateProgrammed = date;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(bean:didUpdateSketchName:dateProgrammed:crc32:)]) {
                [self.delegate bean:self didUpdateSketchName:name dateProgrammed:date crc32:meta.hexCrc];
            }
        }
            break;
        case MSG_ID_CC_LED_WRITE:
            PTDLog(@"App Message Received: MSG_ID_CC_LED_WRITE: %@", payload);
            break;
        case MSG_ID_CC_LED_WRITE_ALL:
            PTDLog(@"App Message Received: MSG_ID_CC_LED_WRITE_ALL: %@", payload);
            break;
        case MSG_ID_CC_LED_READ_ALL:
            PTDLog(@"App Message Received: MSG_ID_CC_LED_READ_ALL: %@", payload);
            if (self.delegate && [self.delegate respondsToSelector:@selector(bean:didUpdateLedColor:)]) {
                LED_SETTING_T rawData;
                [payload getBytes:&rawData range:NSMakeRange(0, sizeof(LED_SETTING_T))];
#if TARGET_OS_IPHONE
                UIColor *color = [UIColor colorWithRed:rawData.red/255.0f green:rawData.green/255.0f blue:rawData.blue/255.0f alpha:1];
                [self.delegate bean:self didUpdateLedColor:color];
#else
                NSColor *color = [NSColor colorWithRed:rawData.red/255.0f green:rawData.green/255.0f blue:rawData.blue/255.0f alpha:1];
                [self.delegate bean:self didUpdateLedColor:color];
#endif
            }
            break;
        case MSG_ID_CC_ACCEL_READ:
        {
            PTDLog(@"App Message Received: MSG_ID_CC_ACCEL_READ: %@", payload);
            if (self.delegate && [self.delegate respondsToSelector:@selector(bean:didUpdateAccelerationAxes:)]) {
                ACC_READING_T rawData;
                UInt8 sensitivity; //sensitivity is in units of g/512LSB
                if(payload.length == sizeof(ACC_READING_T)){ //This is the latest and greatest Accelerometer message
                    [payload getBytes:&rawData range:NSMakeRange(0, sizeof(ACC_READING_T))];
                    sensitivity = rawData.sensitivity;
                }else if(payload.length == 6){ //Legacy Accelerometer message
                    [payload getBytes:&rawData range:NSMakeRange(0, 6)];
                    sensitivity = 2;
                }else{ // unknown payload
                    break;
                }
                float lsbGConversionFactor = sensitivity/512.0;
                PTDAcceleration acceleration;
                acceleration.x = rawData.xAxis * lsbGConversionFactor;
                acceleration.y = rawData.yAxis * lsbGConversionFactor;
                acceleration.z = rawData.zAxis * lsbGConversionFactor;
                [self.delegate bean:self didUpdateAccelerationAxes:acceleration];
            }
            break;
        }
        case MSG_ID_CC_TEMP_READ:
        {
            PTDLog(@"App Message Received: MSG_ID_CC_TEMP_READ: %@", payload);
            if (self.delegate && [self.delegate respondsToSelector:@selector(bean:didUpdateTemperature:)]) {
                SInt8 temp;
                [payload getBytes:&temp range:NSMakeRange(0, sizeof(SInt8))];
                [self.delegate bean:self didUpdateTemperature:@(temp)];
            }
            break;
        }
        case MSG_ID_DB_COUNTER:
            PTDLog(@"App Message Received: MSG_ID_DB_COUNTER: %@", payload);
            break;
            
        default:
            break;
    }
}
-(void)appMessagingLayer:(AppMessagingLayer*)layer error:(NSError*)error{
    //TODO: Add some more error handling in here
}


#pragma mark OAD callbacks

- (void)device:(OadProfile *)device currentImage:(NSUInteger)index totalImages:(NSUInteger)images imageProgress:(NSUInteger)bytesSent imageSize:(NSUInteger)bytesTotal
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bean:currentImage:totalImages:imageProgress:imageSize:)]) {
        [(id<PTDBeanExtendedDelegate>)self.delegate bean:self currentImage:index totalImages:images imageProgress:bytesSent imageSize:bytesTotal];
    }
}

- (void)device:(OadProfile *)device completedFirmwareUploadOfSingleImage:(NSString *)path imageIndex:(NSUInteger)index totalImages:(NSUInteger)images withError:(NSError *)error
{
    if (error) {
        PTDLog(@"Error during OAD process: %@", error);
        self.updateInProgress = NO;

        // At this point, the firmware update has failed. Pass this error up the chain.
        [self device:device completedFirmwareUploadWithError:error];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(bean:completedFirmwareUploadOfSingleImage:imageIndex:totalImages:withError:)])
        [(id<PTDBeanExtendedDelegate>)self.delegate bean:self completedFirmwareUploadOfSingleImage:path imageIndex:index totalImages:images withError:error];
}

- (void)device:(OadProfile*)device completedFirmwareUploadWithError:(NSError*)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bean:completedFirmwareUploadWithError:)])
        [(id<PTDBeanExtendedDelegate>)self.delegate bean:self completedFirmwareUploadWithError:error];
}

#pragma mark Battery Monitoring Delegate callbacks
-(void)batteryProfileDidUpdate
{
    if(self.delegate){
        if([self.delegate respondsToSelector:@selector(beanDidUpdateBatteryVoltage:error:)]){
            [self.delegate beanDidUpdateBatteryVoltage:self error:nil];
        }
    }
}

#pragma mark Device Info Profile callbacks

- (void)hardwareVersionDidUpdate
{
    if (self.hardwareVersionAvailableHandler){
        [self checkHardwareVersionAvailableWithHandler:self.hardwareVersionAvailableHandler];
        self.hardwareVersionAvailableHandler = nil;
    }
}

- (void)firmwareVersionDidUpdate
{
    // Continue or complete any firmware update in progress
    [self manageFirmwareUpdateStatus];
    
    // Don't send firmware version back to handler when firmware update is still in progress
    if (self.updateInProgress) return;

    if (self.firmwareVersionAvailableHandler) {
        [self checkFirmwareVersionAvailableWithHandler:self.firmwareVersionAvailableHandler];
        self.firmwareVersionAvailableHandler = nil;
    }
}

@end
