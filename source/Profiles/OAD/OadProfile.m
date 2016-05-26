#import "OadProfile.h"

// OAD implementation based on http://processors.wiki.ti.com/images/8/82/OAD_for_CC254x.pdf

#define SERVICE_OAD                     @"0xF000FFC0-0451-4000-B000-000000000000"
#define CHARACTERISTIC_OAD_IDENTIFY     @"0xF000FFC1-0451-4000-B000-000000000000"
#define CHARACTERISTIC_OAD_BLOCK        @"0xF000FFC2-0451-4000-B000-000000000000"

#define ERROR_DOMAIN                    @"OAD"
#define ERROR_CODE                      100
#define WATCHDOG_TIMER_INTERVAL         (2)

typedef NS_ENUM(NSUInteger, OADState) {
    OADStateIdle,
    OADStateEnableNotify,
    OADStateSentNewHeader,
    OADStateSendingPackets,
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

const static NSUInteger OAD_DATA_BLOCK_SIZE = 16;
typedef UInt8 data_block_t[OAD_DATA_BLOCK_SIZE];

typedef struct {
    UInt16          nbr;
    data_block_t    block;
} oad_packet_t;

#pragma mark - OadFirmwareImage object definition

@interface OadFirmwareImage : NSObject

@property (nonatomic, strong)  NSString             *path;
@property (nonatomic, strong)  NSData               *data;

@end

@implementation OadFirmwareImage

@end

#pragma mark - OadProfile

@interface OadProfile ()

@property (strong, nonatomic)   CBService           *serviceOAD;
@property (strong, nonatomic)   CBCharacteristic    *characteristicOADBlock;
@property (strong, nonatomic)   CBCharacteristic    *characteristicOADIdentify;

/**
 *  An array of OadFirmwareImage objects containing binary data for firmware images to be offered to Bean
 */
@property (nonatomic, strong)   NSArray             *firmwareImages;
/**
 *  The firmwareImages array index of the last image offered to Bean
 */
@property (nonatomic, assign)   NSUInteger          lastImageOffered;

@property (nonatomic)           OADState            oadState;
@property (strong, nonatomic)   NSTimer             *watchdogTimer;
@property (nonatomic)           BOOL                watchdogSet;
@property (strong, nonatomic)   NSDate              *downloadStartDate;
@property (nonatomic)           float               leastSeconds;

@property (nonatomic)           int16_t              nextBlock;
@property (nonatomic)           int16_t              nextBlockRequest;
@property (nonatomic)           int16_t              totalBlocks;

@end

@implementation OadProfile
@dynamic delegate; // Delegate is already synthesized by BleProfile subclass

+(void)load
{
    [super registerProfile:self serviceUUID:SERVICE_OAD];
}

#pragma mark - NSObject

- (instancetype)initWithService:(CBService*)service
{
    self = [super init];
    if (self) {
        peripheral = service.peripheral;
        self.oadState = OADStateIdle;
        self.serviceOAD = service;
    }
    return self;
}

#pragma mark - PTDOADProfile

- (BOOL)updateFirmwareWithImagePaths:(NSArray*)firmwareImagePaths
{
    
    PTDLog(@"OAD updating firmware with image paths: %@", firmwareImagePaths);
    
    if (peripheral.state != CBPeripheralStateConnected) {
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadOfSingleImage:imageIndex:totalImages:withError:)]) {
            [self.delegate device:self completedFirmwareUploadOfSingleImage:nil
                       imageIndex:0
                      totalImages:0
                        withError:[OadProfile errorWithDesc:@"Device is not connected"]];
        }
        return NO;
    }
    
    if (self.oadState != OADStateIdle) {
        if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadOfSingleImage:imageIndex:totalImages:withError:)]) {
            [self.delegate device:self completedFirmwareUploadOfSingleImage:nil
                       imageIndex:0
                      totalImages:0
                        withError:[OadProfile errorWithDesc:@"Download already started"]];
        }
        return NO;
    }
    
    // Load data for all firmware images

    NSError *error;
    NSMutableArray *firmwareImages = [[NSMutableArray alloc] init];
    for (NSString *path in firmwareImagePaths) {
        NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
        if (error) {
            NSString *desc = @"Couldn't load firmware image";
            PTDLog(@"%@: %@", desc, error);
            [self completeWithError:[OadProfile errorWithDesc:desc]];
            return NO;
        }

        OadFirmwareImage *image = [[OadFirmwareImage alloc] init];
        image.path = path;
        image.data = data;
        [firmwareImages addObject:image];
    }

    self.firmwareImages = firmwareImages;

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



#pragma mark - BleProfile
-(void)validate
{
    [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_OAD_IDENTIFY],
                                          [CBUUID UUIDWithString:CHARACTERISTIC_OAD_BLOCK]]
                             forService:self.serviceOAD];
}
- (BOOL)isValid:(NSError**)error
{
    return (self.characteristicOADIdentify &&
            self.characteristicOADBlock);
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    self.watchdogSet = NO;
    if (!error) {
        if (![self processCharacteristics]) {
            PTDLog(@"Did not find all OAD characteristics\n");
        }
    } else {
        PTDLog(@"Error discovering characteristics: %@", [error localizedDescription]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    self.watchdogSet = NO;

    if (error) return;
    if (self.oadState != OADStateEnableNotify) return;
    if (!self.characteristicOADBlock.isNotifying) return;
    if (!self.characteristicOADIdentify.isNotifying) return;

    [self offerOneImageUsingFirstImage:YES];
}

- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    self.watchdogSet = NO;
    if ([characteristic isEqual:self.characteristicOADBlock]) {
        UInt16 requestedBlock = CFSwapInt16LittleToHost(*((UInt16 *)characteristic.value.bytes));
        switch (self.oadState) {
            case OADStateSentNewHeader:
                PTDLog(@"Device accepted image transfer: %lu of %lu: %@",
                       self.lastImageOffered + 1,
                       self.firmwareImages.count,
                       [[self currentImage].path lastPathComponent]);
                self.oadState = OADStateSendingPackets;
                self.nextBlock = 0;
                self.nextBlockRequest = 0;
                // Fall through
                
            case OADStateSendingPackets:
                [self sendBlocks:requestedBlock];
                break;
                
            case OADStateIdle:
                // this is probably a notification confirming a packet we sent earlier, we can safely ignore this
                break;

            default:
                PTDLog(@"Unexpected value update for Block characteristic in state %tu\n", self.oadState);
                break;
        }
    } else if ([characteristic isEqual:self.characteristicOADIdentify]) {
        switch (self.oadState) {
                
            case OADStateSentNewHeader:
                [self offerOneImageUsingFirstImage:NO];  // Offer the next unoffered image
                break;
                
            default:
                PTDLog(@"Unexpected value update for Identity characteristic in state %tu\n", self.oadState);
                break;
        }
    }
}

#pragma mark - Internal


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
        PTDLog(@"%@: OAD found", self.class.description);
        [self __notifyValidity];
    }
    
    return valid;
}

// Send the requested block number to the OAD Target
-(void)sendOneBlock:(UInt16)block
{
    OadFirmwareImage *image = [self currentImage];
    data_block_t *imageBlocks = (data_block_t *)image.data.bytes;
    NSMutableData *data = [NSMutableData dataWithLength:sizeof(oad_packet_t)];
    oad_packet_t *packet = (oad_packet_t *)data.bytes;
    packet->nbr = CFSwapInt16HostToLittle(block);
    memcpy(&packet->block, &(imageBlocks[block]), sizeof(data_block_t));
    [peripheral writeValue:data forCharacteristic:self.characteristicOADBlock type:CBCharacteristicWriteWithoutResponse];
}

// Every time we receive a block request from the OAD Target, add more blocks to the queue if there is room
// Check for re-requests that indicate a block was missed. Send the missed block and re-fill the queue with the
// subsequent blocks.
#define BLOCKS_INFLIGHT 18
- (void)sendBlocks:(UInt16)requestedBlock
{
    // A block was re-requested, it must have been lost
    // Expect to see a re-request for every block that was already in flight, attempt to ignore
    if (requestedBlock < self.nextBlockRequest) {
        PTDLog(@"OAD block %d lost in transit! Resending.", requestedBlock);
        self.nextBlockRequest -= self.nextBlock - requestedBlock - 1; // Compensate for in flight blocks
        self.nextBlock = requestedBlock;
        self.oadState = OADStateSendingPackets;
    }
    self.nextBlockRequest++;
    
    // Batch together the sending of up to 18 blocks, but not after every request
    if( self.nextBlock - requestedBlock < BLOCKS_INFLIGHT/4 ) {

        // Update the delegate on our progress
        if (self.nextBlock) {
            OadFirmwareImage *currentImage = [self currentImage];
            NSUInteger currentImageProgress = self.nextBlock * OAD_DATA_BLOCK_SIZE;
            NSUInteger currentImageTotal = currentImage.data.length;
            if ([self.delegate respondsToSelector:@selector(device:currentImage:totalImages:imageProgress:imageSize:)]) {
                [self.delegate device:self
                         currentImage:self.lastImageOffered
                          totalImages:self.firmwareImages.count
                        imageProgress:currentImageProgress
                            imageSize:currentImageTotal];
            }
        } else {
            self.downloadStartDate = [NSDate date];
        }
        
        // Send the blocks
        while( self.nextBlock - requestedBlock < BLOCKS_INFLIGHT && self.nextBlock < self.totalBlocks ){
            [self sendOneBlock:self.nextBlock];
            self.nextBlock++;
        }
        
    }

    // Watch for last block
    if ( self.nextBlock == self.totalBlocks) {
        [self imageUploaded];
    }
}

- (void)enableNotify
{
    self.oadState = OADStateEnableNotify;
    
    if (self.characteristicOADBlock.isNotifying && self.characteristicOADIdentify.isNotifying) {
        // Already enabled
        [self offerOneImageUsingFirstImage:YES];
    } else {
        if (!self.characteristicOADBlock.isNotifying) {
            [peripheral setNotifyValue:YES forCharacteristic:self.characteristicOADBlock];
        }
        if (!self.characteristicOADIdentify.isNotifying) {
            [peripheral setNotifyValue:YES forCharacteristic:self.characteristicOADIdentify];
        }
    }
}

/**
 *  Offer one OAD image to Bean.
 *
 *  @param firstImage YES to offer the first image to Bean, NO to offer the next unoffered image
 */
- (void)offerOneImageUsingFirstImage:(BOOL)offerFirstImage
{
    // Pick the next firmware image in the list
    NSUInteger imageToOffer;
    if (offerFirstImage) {
        imageToOffer = 0;
    } else {
        imageToOffer = self.lastImageOffered + 1;
    }

    // No images left to offer Bean? We can't send an update to Bean.
    if (self.firmwareImages.count == imageToOffer) {
        NSString *desc = @"Device rejected all available firmware versions.";
        PTDLog(@"%@", desc);
        [self completeWithError:[OadProfile errorWithDesc:desc]];
        return;
    }

    OadFirmwareImage *image = self.firmwareImages[imageToOffer];
    PTDLog(@"Offering firmware image %lu of %lu: %@",
           imageToOffer + 1,
           self.firmwareImages.count,
           [image.path lastPathComponent]);

    // Get the image header bytes
    self.totalBlocks = image.data.length / sizeof(data_block_t);
    img_hdr_t *imageHeader = (img_hdr_t *)image.data.bytes;

    NSMutableData *data = [NSMutableData dataWithLength:sizeof(request_oad_header_t)];
    request_oad_header_t *request = (request_oad_header_t *)data.bytes;
    request->ver = imageHeader->ver;
    request->len = imageHeader->len;
    memcpy(&request->uid, &imageHeader->uid, sizeof(request->uid));
    UInt16 reserved[] = {CFSwapInt16HostToLittle(12), CFSwapInt16HostToLittle(15)};
    memcpy(&request->res, reserved, sizeof(request->res));

    // Send image header data to Bean to offer this image to Bean
    self.oadState = OADStateSentNewHeader;
    [peripheral writeValue:data
         forCharacteristic:self.characteristicOADIdentify
                      type:CBCharacteristicWriteWithoutResponse];

    self.lastImageOffered = imageToOffer;
}

- (void)cancel
{
    [self completeWithError:nil];
}

- (void)imageUploaded
{
    NSUInteger bytes = [self currentImage].data.length;
    float duration = - [self.downloadStartDate timeIntervalSinceNow] - WATCHDOG_TIMER_INTERVAL;
    float rate = bytes / duration;
    PTDLog(@"Image %lu of %lu uploaded successfully. %lu bytes, %0.2f seconds, %0.1f bytes/sec",
           self.lastImageOffered + 1,
           self.firmwareImages.count,
           bytes,
           duration,
           rate);
    [self completeWithError:nil];
}

- (void)completeWithError:(NSError *)error
{
    if (error) PTDLog(@"OAD completed with error: %@", error);

    self.oadState = OADStateIdle;
    self.downloadStartDate = nil;

    [self.watchdogTimer invalidate];
    self.watchdogTimer = nil;

    [peripheral setNotifyValue:NO forCharacteristic:self.characteristicOADBlock];
    [peripheral setNotifyValue:NO forCharacteristic:self.characteristicOADIdentify];
    
    if ([self.delegate respondsToSelector:@selector(device:completedFirmwareUploadOfSingleImage:imageIndex:totalImages:withError:)]) {
        OadFirmwareImage *image = [self currentImage];
        [self.delegate device:self completedFirmwareUploadOfSingleImage:image.path
                   imageIndex:self.lastImageOffered
                  totalImages:self.firmwareImages.count
                    withError:error];
    }
    
    // NOTE: Bean delegate method completedFirmwareUploadWithError is called by PTDBean, NOT OadProfile.
    // PTDBean is responsible for handling the recomplete/continue logic.
}

- (void)watchdogTimerFired:(NSTimer *)timer
{
    if (self.oadState == OADStateIdle) {
        // watchdog should never be running in idle
        [timer invalidate];
        self.watchdogTimer = nil;
    }

    // If the watchdog flag isn't set, set it and return.
    if (!self.watchdogSet) {
        self.watchdogSet = YES;
        return;
    }

    // The watchdog flag is set. That means the flag was not reset since the watchdog fired last time.
    // This might mean Bean rebooted as expected, or the firmware upload process timed out unexpectedly.

    NSError *error;

    if (self.oadState == OADStateEnableNotify) {
        error = [OadProfile errorWithDesc:@"Timeout configuring OAD characteristics."];

    } else if (self.oadState == OADStateSendingPackets) {
        if (self.nextBlockRequest == 1) {
            PTDLog(@"Bean is resetting to small OAD-only image.");
        } else {
            error = [OadProfile errorWithDesc:@"Timeout sending firmware."];
        }

    } else {
        error = [OadProfile errorWithDesc:@"Unexpected watchdog timeout."];
    }

    [self completeWithError:error];
}

/**
 *  @return the current FirmwareImage being uploaded to Bean
 */
- (OadFirmwareImage *)currentImage
{
    return self.firmwareImages[self.lastImageOffered];
}

/**
 *  Returns an NSError for OadProfile.
 *
 *  @param description a description of the error that occurred
 *
 *  @return an NSError configured with the error domain and code for this class
 */
+ (NSError *)errorWithDesc:(NSString *)description
{
    return [NSError errorWithDomain:ERROR_DOMAIN code:ERROR_CODE userInfo:@{NSLocalizedDescriptionKey:description}];
}

@end
