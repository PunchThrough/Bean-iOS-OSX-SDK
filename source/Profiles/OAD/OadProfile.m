//
//  OADDevice.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 8/16/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//

#import "OadProfile.h"
#import "oad.h"
#import "CBPeripheral+isConnected_Universal.h"

@interface OadProfile ()
@end

@implementation OadProfile{
    CBService* service_oad;
    CBCharacteristic * characteristic_oad_notify;
    CBCharacteristic * characteristic_oad_block;
    
    NSString * pathA;
    NSString * pathB;
    NSString* firmwareVersionCompare;
    bool readyToInitiateImageTransfer;
}

#pragma mark Public Methods
-(id)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<OAD_Delegate>)delegate
{
    self = [super init];
    if (self) {
        //Init Code
        peripheral = aPeripheral;
        _delegate = delegate;
        readyToInitiateImageTransfer = FALSE;
    }
    return self;
}
-(void)validate
{
    // Discover services
    PTDLog(@"Searching for OAD service: %@", SERVICE_OAD);
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:SERVICE_OAD]
                                      , nil]];
    }
}
-(BOOL)isValid:(NSError**)error
{
    return (service_oad &&
            characteristic_oad_notify &&
            characteristic_oad_block &&
            characteristic_oad_notify.isNotifying);
}

#pragma mark Private Functions
-(void)__processCharacteristics
{
    if(service_oad){
        if(service_oad.characteristics){
            for(CBCharacteristic* characteristic in service_oad.characteristics){
                if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OAD_NOTIFY]]){
                    characteristic_oad_notify = characteristic;
                }else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_OAD_BLOCK]]){
                    characteristic_oad_block = characteristic;
                }
            }
        }
    }
}

#pragma mark main functionality
-(BOOL)checkForNewFirmware:(NSString*)newFirmwareVersion currentFirmware:(NSString*)currentFirmwareVersion error:(NSError**)error
{
    if (service_oad) {
        firmwareVersionCompare = [newFirmwareVersion stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        //NSString * version = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
        BOOL newFirmware = NO;
        
        //If a firmware check has been initiated
        if(firmwareVersionCompare)
        {
            // Check if firmware is newer
            if ([currentFirmwareVersion compare:firmwareVersionCompare] == NSOrderedAscending) {
                // Newer firmware
                newFirmware = YES;
            }
            firmwareVersionCompare = nil;
            return newFirmware;
        }
        
        *error = [BEAN_Helper basicError:@"Problem comparing FW versions" domain:NSStringFromClass([self class]) code:100];
        return NO;
    }
    else {
        PTDLog(@"%@: checkForNewFirmware. OAD is not supported on this device", self.class.description);
        *error = [BEAN_Helper basicError:@"OAD is not supported on this device" domain:NSStringFromClass([self class]) code:100];
        return NO;
    }
}


-(BOOL)updateFirmwareWithImageAPath:(NSString*)imageApath andImageBPath:(NSString*)imageBpath
{
    if (![peripheral isConnected_Universal]) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Device is not connected" forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:@"OAD" code:100 userInfo:errorDetail];
        
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
            [self.delegate device:self completedFirmwareUploadWithError:error];
        }
        return FALSE; //Not connected
    }
    else if (service_oad) {
        PTDLog(@"%@: updateFirmware. Updating Firmware...", self.class.description);
        // Update the firmware
        
        pathA = imageApath;
        pathB = imageBpath;
        
        self.canceled = FALSE;
        self.inProgramming = FALSE;
  
        //Sert characteristic to notify
        [peripheral setNotifyValue:YES forCharacteristic:characteristic_oad_notify];
        unsigned char byte = 0x00;
        NSData* data = [NSData dataWithBytes:&byte length:1];
        [peripheral writeValue:data forCharacteristic:characteristic_oad_notify type:CBCharacteristicWriteWithResponse];
        self.imageDetectTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(imageDetectTimerTick:) userInfo:nil repeats:NO];
        self.imgVersion = 0xFFFF;
        
        return TRUE;
    }
    else {
        PTDLog(@"%@: updateFirmware. OAD is not supported ", self.class.description);
        return FALSE; //Device doesn't support OAD
    }

}

-(void)cancelUpdateFirmware
{
    self.canceled = YES;
    self.inProgramming = NO;
}


-(void)firmwareReadyToUpdate
{
    if ([self validateImage:pathA]) {
        // Image A is valid and uploading
    }
    else if ([self validateImage:pathB]) {
        // Image B is valid and uploading
    }
    else {
        // Both images are invalid!
        
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Both OAD images are invalid" forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:@"OAD" code:100 userInfo:errorDetail];
        
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
            [self.delegate device:self completedFirmwareUploadWithError:error];
        }
    }
}


// IMPORTANT:
// This is the time delay between sending packets. If it is dropping packets increase the DELAY value
#define OAD_PACKET_TX_DELAY 0.13

-(void) uploadImage:(NSString *)filename {
    self.inProgramming = YES;
    self.canceled = NO;
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    uint8_t requestData[OAD_IMG_HDR_SIZE + 2 + 2]; // 12Bytes
    
    for(int ii = 0; ii < 20; ii++) {
        PTDLog(@"%02hhx",imageFileData[ii]);
    }
    
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    
    requestData[0] = LO_UINT16(imgHeader.ver);
    requestData[1] = HI_UINT16(imgHeader.ver);
    
    requestData[2] = LO_UINT16(imgHeader.len);
    requestData[3] = HI_UINT16(imgHeader.len);
    
    PTDLog(@"Image version = %04hx, len = %04hx",imgHeader.ver,imgHeader.len);
    
    memcpy(requestData + 4, &imgHeader.uid, sizeof(imgHeader.uid));
    
    requestData[OAD_IMG_HDR_SIZE + 0] = LO_UINT16(12);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(12);
    
    requestData[OAD_IMG_HDR_SIZE + 2] = LO_UINT16(15);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(15);
    
    [peripheral writeValue:[NSData dataWithBytes:requestData length:(OAD_IMG_HDR_SIZE + 2 + 2)] forCharacteristic:characteristic_oad_notify type:CBCharacteristicWriteWithResponse];
    
    self.nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
    self.nBytes = imgHeader.len * HAL_FLASH_WORD_SIZE;
    self.iBlocks = 0;
    self.iBytes = 0;
    
    
    NSTimer* timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

-(void) programmingTimerTick:(NSTimer *)timer {
    if (self.canceled) {
        self.canceled = FALSE;
        return;
    }
    
    if(!peripheral.isConnected_Universal){
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
            NSError* error = [BEAN_Helper basicError:@"Peripheral has disconnected during OAD" domain:@"BEAN API:OAD Profile" code:100];
            [self.delegate device:self completedFirmwareUploadWithError:error];
        }
        return;
    }
    
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    //Prepare Block
    uint8_t requestData[2 + OAD_BLOCK_SIZE];
    
    // This block is run 4 times, this is needed to get CoreBluetooth to send consequetive packets in the same connection interval.
    for (int ii = 0; ii < 4; ii++) {
        
        requestData[0] = LO_UINT16(self.iBlocks);
        requestData[1] = HI_UINT16(self.iBlocks);
        
        memcpy(&requestData[2] , &imageFileData[self.iBytes], OAD_BLOCK_SIZE);
        
        [peripheral writeValue:[NSData dataWithBytes:requestData length:(2 + OAD_BLOCK_SIZE)] forCharacteristic:characteristic_oad_block type:CBCharacteristicWriteWithoutResponse];
        
        self.iBlocks++;
        self.iBytes += OAD_BLOCK_SIZE;
        
        if(self.iBlocks == self.nBlocks) {
            self.inProgramming = NO;
            if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
                [self.delegate device:self completedFirmwareUploadWithError:nil];
            }
            return;
        }
        else {
            if (ii == 3){
                NSTimer* timer = [NSTimer timerWithTimeInterval:OAD_PACKET_TX_DELAY target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            }
        }
    }
    
    // Tell delegate how long it will take to complete
    float secondsPerBlock = OAD_PACKET_TX_DELAY / 4;
    float secondsLeft = (float)(self.nBlocks - self.iBlocks) * secondsPerBlock;
    float percentageLeft = (float)((float)self.iBlocks / (float)self.nBlocks);
    NSNumber * seconds = [NSNumber numberWithFloat:secondsLeft];
    NSNumber * percentage = [NSNumber numberWithFloat:percentageLeft];
    if ([self.delegate respondsToSelector:@selector(device:OADUploadTimeLeft:withPercentage:)]) {
        [self.delegate device:self OADUploadTimeLeft:seconds withPercentage:percentage];
    }
    
    PTDLog(@".");
}


/*
-(void)deviceDisconnected:(CBPeripheral *)aPeripheral {
    if ([peripheral isEqual:self.d.p] && self.inProgramming) {
        // Cancel firmware upload
        self.canceled = YES;
        self.inProgramming = NO;
    }
}
 */


-(BOOL)validateImage:(NSString *)filename {
    self.imageFile = [NSData dataWithContentsOfFile:filename];
    PTDLog(@"Loaded firmware \"%@\"of size : %lu",filename,(unsigned long)self.imageFile.length);
    if ([self isCorrectImage]) {
        [self uploadImage:filename];
        return YES;
    }
    else {
        // Invalid image
        return NO;
    }
}

-(BOOL) isCorrectImage {
    unsigned char imageFileData[self.imageFile.length];
    [self.imageFile getBytes:imageFileData];
    
    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));
    
    if ((imgHeader.ver & 0x01) != (self.imgVersion & 0x01)) return YES;
    return NO;
}

-(void) imageDetectTimerTick:(NSTimer *)timer {
    //IF we have come here, the image userID is B.
    PTDLog(@"imageDetectTimerTick:");

    unsigned char data = 0x01;
    
    readyToInitiateImageTransfer = TRUE;
    [peripheral writeValue:[NSData dataWithBytes:&data length:1] forCharacteristic:characteristic_oad_notify type:CBCharacteristicWriteWithResponse];
}


#pragma mark CBPeripheralDelegate callbacks
////////////////  CBPeripheralDeligate Callbacks ////////////////////////////
-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        if(!(service_oad))
        {
            if(peripheral.services)
            {
                for (CBService * service in peripheral.services) {
                    if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_OAD]]) {
                        PTDLog(@"%@: OAD service  found", self.class.description);
                        
                        // Save oad service
                        service_oad = service;
                        
                        //Check if characterisics are already found.
                        [self __processCharacteristics];
                        
                        //If all characteristics are found
                        if(characteristic_oad_notify &&
                           characteristic_oad_block)
                        {
                            PTDLog(@"%@: OAD Characteristics of peripheral found", self.class.description);
                            if(characteristic_oad_notify.isNotifying){
                                [self __notifyValidity];
                            }else{
                                //Set characteristic to notify
                                [peripheral setNotifyValue:YES forCharacteristic:characteristic_oad_notify];
                                //Wait until the notification characteristic is registered successfully as "notify" and then alert delegate that device is valid
                            }
                        }else{
                            // Find characteristics of service
                            NSArray * characteristics = [NSArray arrayWithObjects:
                                                         [CBUUID UUIDWithString:CHARACTERISTIC_OAD_NOTIFY],
                                                         [CBUUID UUIDWithString:CHARACTERISTIC_OAD_BLOCK],
                                                         nil];
                            [peripheral discoverCharacteristics:characteristics forService:service];
                        }
                    }
                }
            }
        }
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service isEqual:service_oad]) {
            [self __processCharacteristics];
            
            NSError* verificationerror;
            if ((
                 characteristic_oad_notify &&
                 characteristic_oad_block
                 ))
            {
                PTDLog(@"%@: Found all OAD characteristics", self.class.description);
                
                if(characteristic_oad_notify.isNotifying){
                    [self __notifyValidity];
                }else{
                    //Set characteristic to notify
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic_oad_notify];
                    //Wait until the notification characteristic is registered successfully as "notify" and then alert delegate that device is valid
                }
            }else {
                // Could not find all characteristics!
                PTDLog(@"%@: Could not find all OAD characteristics!", self.class.description);
                
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Could not find all OAD characteristics" forKey:NSLocalizedDescriptionKey];
                verificationerror = [NSError errorWithDomain:@"Bluetooth" code:100 userInfo:errorDetail];
            }
            //Alert Delegate
        }
    }else {
        PTDLog(@"%@: Characteristics discovery was unsuccessful", self.class.description);
        //Alert Delegate
    }
}

-(void)peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        if ([characteristic isEqual:characteristic_oad_notify]) {
            if (self.imgVersion == 0xFFFF) {
                unsigned char data[characteristic.value.length];
                [characteristic.value getBytes:&data];
                self.imgVersion = ((uint16_t)data[1] << 8 & 0xff00) | ((uint16_t)data[0] & 0xff);
                PTDLog(@"self.imgVersion : %04hx",self.imgVersion);
            }
            PTDLog(@"OAD Image notify : %@",characteristic.value);
        }
    }

}

-(void)peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    //Is the notify oad characteristic
    if([characteristic isEqual:characteristic_oad_notify])
    {
        if (error) {
            // Dropping writeWithoutReponse packets. Stop the firmware upload and notify the delegate
            self.canceled = YES;
            
            if (self.inProgramming) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Dropping writeWithoutReponse packets" forKey:NSLocalizedDescriptionKey];
                NSError* error = [NSError errorWithDomain:@"OAD" code:100 userInfo:errorDetail];
                
                if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
                    [self.delegate device:self completedFirmwareUploadWithError:error];
                }
            }
            self.inProgramming = NO;
        }else{
            PTDLog(@"wrote characteristic length:%lu data:%@",(unsigned long)characteristic.value.length, characteristic.value);
            if(readyToInitiateImageTransfer ==TRUE)
            {
                readyToInitiateImageTransfer = FALSE;
                // Ready to send firmware packets
                [self firmwareReadyToUpdate];
            }
            /*
            if (characteristic.value.length == 1) {
                Byte number;
                [characteristic.value getBytes:&number length:1];
                if (number == 0x01) {
                    // Ready to send firmware packets
                    [self firmwareReadyToUpdate];
                }
            }
             */
            PTDLog(@"didWriteValueForProfile : %@",characteristic);
        }
    }
}

- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(!error)
    {
        if([characteristic isEqual:characteristic_oad_notify])
        {
            PTDLog(@"%@: OAD Characteristic set to \"Notify\"", self.class.description);
            //Alert Delegate that device is connected. At this point, the device should be added to the list of connected devices
           
            [self __notifyValidity];
        }
    }else{
        
    }
}


@end
