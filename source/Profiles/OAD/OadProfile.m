//
//  OADDevice.m
//  BleArduino
//
//  Created by Raymond Kampmeier on 8/16/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//

#import "OadProfile.h"

// OAD implementation based on http://processors.wiki.ti.com/images/8/82/OAD_for_CC254x.pdf

// TODO:
// Stay 2 packets ahead?

#define SERVICE_OAD                     @"0xF000FFC0-0451-4000-B000-000000000000"
#define CHARACTERISTIC_OAD_IDENTIFY     @"0xF000FFC1-0451-4000-B000-000000000000"
#define CHARACTERISTIC_OAD_BLOCK        @"0xF000FFC2-0451-4000-B000-000000000000"

#define ERROR_DOMAIN                    @"OAD"
#define ERROR_CODE                      100

#define WATCHDOG_TIMER_INTERVAL         (1.5)

typedef NS_ENUM(NSUInteger, OADState) {
    OADStateIdle,
    OADStateEnableNotify,
    OADStateRequestCurrentHeader,
    OADStateSentNewHeader,
    OADStateSendingPackets,
    OADStateWaitForCompletion
};

typedef struct {
    UInt16 crc0;
    UInt16 crc1;       // CRC-shadow must be 0xFFFF.
    UInt16 ver;        // User-defined Image Version Number - default logic uses simple a '<' comparison to start an OAD.
    UInt16 len;        // Image length in 4-byte blocks (i.e. HAL_FLASH_WORD_SIZE blocks).
    UInt8  uid[4];     // User-defined Image Identification bytes.
    UInt8  res[4];     // Reserved space for future use.
} img_hdr_t;

typedef struct {
    UInt16  ver;
    UInt16  len;
    UInt8   uid[4];
    UInt8   res[4];
} request_oad_header_t;

typedef struct {
    UInt16  ver;
    UInt16  len;
    UInt8   uid[4];
} response_oad_header_t;

typedef UInt8 data_block_t[16];

typedef struct {
    UInt16          nbr;
    data_block_t    block;
} oad_packet_t;

@interface OadProfile ()

@property (weak, nonatomic)     id<OAD_Delegate>    delegate;

@property (strong, nonatomic)   CBService           *serviceOAD;
@property (strong, nonatomic)   CBCharacteristic    *characteristicOADBlock;
@property (strong, nonatomic)   CBCharacteristic    *characteristicOADIdentify;

@property (strong, nonatomic)   NSString            *imageAPath;
@property (strong, nonatomic)   NSString            *imageBPath;
@property (strong, nonatomic)   NSData              *imageData;

@property (nonatomic)           OADState            oadState;
@property (nonatomic)           UInt16              nextPacket;
@property (strong, nonatomic)   NSTimer             *watchdogTimer;
@property (nonatomic)           BOOL                watchdogSet;
@property (strong, nonatomic)   NSDate              *downloadStartDate;
@property (nonatomic)           float               leastSeconds;

@end

@implementation OadProfile

#pragma mark - NSObject

- (instancetype)initWithPeripheral:(CBPeripheral*)aPeripheral delegate:(id<OAD_Delegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        peripheral = aPeripheral;
        self.oadState = OADStateIdle;
    }
    return self;
}

#pragma mark - PTDOADProfile

- (BOOL)updateFirmwareWithImageAPath:(NSString*)imageAPath andImageBPath:(NSString*)imageBPath
{
    if (peripheral.state != CBPeripheralStateConnected) {
        
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
            [self.delegate device:self completedFirmwareUploadWithError:[NSError errorWithDomain:ERROR_DOMAIN
                                                                                            code:ERROR_CODE
                                                                                        userInfo:@{NSLocalizedDescriptionKey:@"Device is not connected"}]];
        }
        return NO;
    }
    
    if (self.oadState != OADStateIdle) {
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
            [self.delegate device:self completedFirmwareUploadWithError:[NSError errorWithDomain:ERROR_DOMAIN
                                                                                            code:ERROR_CODE
                                                                                        userInfo:@{NSLocalizedDescriptionKey:@"Download already started"}]];
        }
        return NO;
    }
    
    self.imageAPath = imageAPath;
    self.imageBPath = imageBPath;
    
    self.nextPacket = 0;
    self.watchdogSet = NO;
    self.watchdogTimer = [NSTimer scheduledTimerWithTimeInterval:WATCHDOG_TIMER_INTERVAL
                                                          target:self
                                                        selector:@selector(watchdogTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
    
    self.leastSeconds = FLT_MAX;
    
    [self enableNotify];
    
    return YES;
}

- (void)cancelUpdateFirmware
{
    if (self.oadState != OADStateIdle) {
        self.oadState = OADStateIdle;
        [self.watchdogTimer invalidate];
        self.watchdogTimer = nil;
        self.downloadStartDate = nil;
        self.imageData = nil;
        [peripheral setNotifyValue:NO forCharacteristic:self.characteristicOADBlock];
        [peripheral setNotifyValue:NO forCharacteristic:self.characteristicOADIdentify];
    }
}

#pragma mark - BleProfile

- (void)validate
{
    // Discover services
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_OAD]]];
    }
}

- (BOOL)isValid:(NSError**)error
{
    return (self.characteristicOADIdentify &&
            self.characteristicOADBlock);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    if (!error && !self.serviceOAD && peripheral.services) {
        CBUUID *oadServiceUUID = [CBUUID UUIDWithString:SERVICE_OAD];
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:oadServiceUUID]) {
                self.serviceOAD = service;
                
                if (![self processCharacteristics]) {
                    [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_OAD_IDENTIFY],
                                                          [CBUUID UUIDWithString:CHARACTERISTIC_OAD_BLOCK]]
                                             forService:service];
                }
                break;
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service isEqual:self.serviceOAD]) {
            if (![self processCharacteristics]) {
                PTDLog(@"Did not find all OAD characteristics\n");
            }
        }
    } else {
        PTDLog(@"Error discovering characteristics: %@", [error localizedDescription]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        if (self.oadState == OADStateEnableNotify) {
            if (self.characteristicOADBlock.isNotifying && self.characteristicOADIdentify.isNotifying) {
                [self requestCurrentHeader];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic isEqual:self.characteristicOADBlock]) {
        UInt16 requestedPacket = CFSwapInt16LittleToHost(*((UInt16 *)characteristic.value.bytes));
        switch (self.oadState) {
            case OADStateSentNewHeader:
                PTDLog(@"Device accepts transfer\n");
                self.oadState = OADStateSendingPackets;
                [self sendPackets];
                break;
                
            case OADStateSendingPackets:
                if (requestedPacket == self.nextPacket) {
                    PTDLog(@"Device requested block %6d\n", self.nextPacket);
                    [self sendPackets];
                }
                break;
                
            case OADStateWaitForCompletion:
                if (requestedPacket == (self.nextPacket - 1)) {
                    // Device does not notify when complete. Requested last packet, assume complete.
                    PTDLog(@"Update completed in %f seconds", -[self.downloadStartDate timeIntervalSinceNow]);
                    [self completeWithError:nil];
                    return;
                }
                break;
                
            default:
                PTDLog(@"Unexpected value update for Block characteristic in state %tu\n", self.oadState);
                break;
        }
    } else if ([characteristic isEqual:self.characteristicOADIdentify]) {
        switch (self.oadState) {
                
            case OADStateRequestCurrentHeader:
                [self beginOADForHeaderData:characteristic.value];
                break;
                
            case OADStateSentNewHeader:
                [self completeWithError:[NSError errorWithDomain:ERROR_DOMAIN
                                                            code:ERROR_CODE
                                                        userInfo:@{NSLocalizedDescriptionKey:@"Device rejected firmware version."}]];
                
                PTDLog(@"Device rejected firmware version\n");
                break;
                
            default:
                PTDLog(@"Unexpected value update for Identity characteristic in state %tu\n", self.oadState);
                break;
        }
    }
}

#pragma mark - Internal

- (void)setOadState:(OADState)oadState
{
    _watchdogSet = NO;
    _oadState = oadState;
}

- (void)setNextPacket:(UInt16)nextPacket
{
    _watchdogSet = NO;
    _nextPacket = nextPacket;
}

- (BOOL)processCharacteristics
{
    if (self.serviceOAD.characteristics) {
        CBUUID *oadIdentityUUID = [CBUUID UUIDWithString:CHARACTERISTIC_OAD_IDENTIFY];
        CBUUID *oadBlockUUID =  [CBUUID UUIDWithString:CHARACTERISTIC_OAD_BLOCK];
        for (CBCharacteristic *characteristic in self.serviceOAD.characteristics) {
            if (!self.characteristicOADIdentify && [characteristic.UUID isEqual:oadIdentityUUID]) {
                self.characteristicOADIdentify = characteristic;
            }
            if (!self.characteristicOADBlock && [characteristic.UUID isEqual:oadBlockUUID]) {
                self.characteristicOADBlock = characteristic;
            }
        }
    }
    
    BOOL valid = self.characteristicOADBlock && self.characteristicOADIdentify;
    if (valid) {
        [self __notifyValidity];
    }
    
    return valid;
}

- (void)sendPackets
{
    if (self.oadState != OADStateSendingPackets) {
        return;
    }
    
    UInt16 nextPacket = self.nextPacket;
    UInt16 totalPackets = self.imageData.length / sizeof(data_block_t);
    
    if (self.nextPacket) {
        NSNumber *percentage = [NSNumber numberWithFloat:(nextPacket * 1.0) / totalPackets];
        float secondsSoFar = -[self.downloadStartDate timeIntervalSinceNow];
        self.leastSeconds = MIN(self.leastSeconds, (secondsSoFar / nextPacket) * (totalPackets - nextPacket));
        NSNumber *seconds = [NSNumber numberWithFloat:self.leastSeconds];
        [self.delegate device:self OADUploadTimeLeft:seconds withPercentage:percentage];
    } else {
        self.downloadStartDate = [NSDate date];
    }
    
    data_block_t    *imageBlocks = (data_block_t *)self.imageData.bytes;
    
    for (int i = 0; i < 4 && nextPacket < totalPackets; i++, nextPacket++) {
        NSMutableData *data = [NSMutableData dataWithLength:sizeof(oad_packet_t)];
        oad_packet_t *packet = (oad_packet_t *)data.bytes;
        packet->nbr = CFSwapInt16HostToLittle(nextPacket);
        memcpy(&packet->block, &(imageBlocks[nextPacket]), sizeof(data_block_t));
        [peripheral writeValue:data forCharacteristic:self.characteristicOADBlock type:CBCharacteristicWriteWithoutResponse];
    }
    
    if (nextPacket == totalPackets) {
        self.oadState = OADStateWaitForCompletion;
    }
    
    if (self.nextPacket == (totalPackets - 1)) {
        // Corner case when only a single packet was left to send.
        // Request was for last packet, notify completion here. No additional requests will be made.
        PTDLog(@"Update completed in %f seconds", -[self.downloadStartDate timeIntervalSinceNow]);
        [self completeWithError:nil];
    }
    
    self.nextPacket = nextPacket;
}

- (void)requestCurrentHeader
{
    self.oadState = OADStateRequestCurrentHeader;
    
    [peripheral writeValue:[NSMutableData dataWithLength:sizeof(UInt8)] forCharacteristic:self.characteristicOADIdentify type:CBCharacteristicWriteWithoutResponse];
}

- (void)enableNotify
{
    self.oadState = OADStateEnableNotify;
    
    if (self.characteristicOADBlock.isNotifying && self.characteristicOADIdentify.isNotifying) {
        // Already enabled
        [self requestCurrentHeader];
    } else {
        if (!self.characteristicOADBlock.isNotifying) {
            [peripheral setNotifyValue:YES forCharacteristic:self.characteristicOADBlock];
        }
        if (!self.characteristicOADIdentify.isNotifying) {
            [peripheral setNotifyValue:YES forCharacteristic:self.characteristicOADIdentify];
        }
    }
}

- (void)beginOADForHeaderData:(NSData *)headerData
{
    response_oad_header_t *response = (response_oad_header_t *)headerData.bytes;
    UInt16 version = CFSwapInt16LittleToHost(response->ver);
    if ([self loadImageForVersion:version]) {
        img_hdr_t *imageHeader = (img_hdr_t *)self.imageData.bytes;
        NSMutableData *data = [NSMutableData dataWithLength:sizeof(request_oad_header_t)];
        request_oad_header_t   *request = (request_oad_header_t *)data.bytes;
        request->ver = imageHeader->ver;
        request->len = imageHeader->len;
        memcpy(&request->uid, &imageHeader->uid, sizeof(request->uid));
        UInt16  reserved[] = {CFSwapInt16HostToLittle(12), CFSwapInt16HostToLittle(15)};
        memcpy(&request->res, reserved, sizeof(request->res));
        
        self.oadState = OADStateSentNewHeader;
        
        [peripheral writeValue:data
             forCharacteristic:self.characteristicOADIdentify
                          type:CBCharacteristicWriteWithoutResponse];
    } else {
        [self completeWithError:[NSError errorWithDomain:ERROR_DOMAIN
                                                    code:ERROR_CODE
                                                userInfo:@{NSLocalizedDescriptionKey:@"Unable to find accepted firmware version"}]];
    }
}

- (BOOL)loadImageForVersion:(UInt16)version
{
    for (NSString *filename in @[self.imageAPath, self.imageBPath]) {
        NSData *data = [NSData dataWithContentsOfFile:filename];
        if ( !data ) {
            return NO;
        }
        img_hdr_t *imageHeader = (img_hdr_t *)data.bytes;
        UInt16 imageVersion = CFSwapInt16LittleToHost(imageHeader->ver);
        if ((version & 0x01) != (imageVersion & 0x01)) {
            self.imageData = data;
            return YES;
        }
    }
    self.imageData = nil;
    return NO;
}

- (void)completeWithError:(NSError *)error
{
    self.oadState = OADStateIdle;
    self.downloadStartDate = nil;
    self.imageData = nil;
    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;
    if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadWithError:)]) {
        [self.delegate device:self completedFirmwareUploadWithError:error];
    }
}

- (void)watchdogTimerFired:(NSTimer *)timer
{
    if (self.oadState == OADStateIdle) {
        // watchdog should never be running in idle.
        [timer invalidate];
        self.watchdogTimer = nil;
    }
    
    if (self.watchdogSet) {
        OADState currentState = self.oadState;
        
        [self cancelUpdateFirmware];
        
        NSString *message;
        switch (currentState) {
            case OADStateEnableNotify:
                message = @"Timeout configuring OAD characteristics.";
                break;
                
            case OADStateRequestCurrentHeader:
                message = @"Timeout requesting current firmware version.";
                break;
                
            case OADStateSentNewHeader:
                message = @"Timeout starting download.";
                break;
                
            case OADStateSendingPackets:
            case OADStateWaitForCompletion:
                message = @"Timeout sending firmware.";
                break;
                
            default:
                message = @"Unexpected watchdog timeout.";
                break;
        }
        
        [self completeWithError:[NSError errorWithDomain:ERROR_DOMAIN
                                                    code:ERROR_CODE
                                                userInfo:@{NSLocalizedDescriptionKey:message}]];
    } else {
        self.watchdogSet = YES;
    }
}

@end
