#import "BeanContainer.h"
#import "StatelessUtils.h"
#import "PTDBean+Protected.h"
#import "PTDUtils.h"

@interface BeanContainer () <PTDBeanManagerDelegate, PTDBeanExtendedDelegate>

#pragma mark Local state set in constructor

@property (nonatomic, strong) XCTestCase *testCase;
@property (nonatomic, strong) BOOL (^beanFilter)(PTDBean *);
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) XCTestExpectation *beanManagerPoweredOn;
@property (nonatomic, strong) PTDBean *bean;
@property (nonatomic, assign) NSInteger beanRssi;

#pragma mark Test expectations and delegate callback values

@property (nonatomic, strong) XCTestExpectation *beanConnected;
@property (nonatomic, strong) XCTestExpectation *beanDisconnected;
@property (nonatomic, strong) XCTestExpectation *beanDidUpdateLedColor;
@property (nonatomic, strong) NSColor *ledColor;
@property (nonatomic, strong) XCTestExpectation *beanDidProgramArduino;
@property (nonatomic, strong) NSError *programArduinoError;
@property (nonatomic, strong) XCTestExpectation *beanCompletedFirmwareUploadOfSingleImage;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) XCTestExpectation *beanCompletedFirmwareUpload;
@property (nonatomic, strong) NSError *firmwareUploadError;

#pragma mark Helpers to prevent spamming the debug log

@property (nonatomic, assign) NSInteger lastPercentagePrinted;

@end

NSString * const firmwareImagesFolder = @"Firmware Images";

@implementation BeanContainer

#pragma mark - Constructors

+ (BeanContainer *)containerWithTestCase:(XCTestCase *)testCase andBeanFilter:(BOOL (^)(PTDBean *bean))filter andOptions:(NSDictionary *)options
{
    return [[BeanContainer alloc] initWithTestCase:testCase andBeanFilter:filter andOptions:options];
}

+ (BeanContainer *)containerWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix andOptions:(NSDictionary *)options
{
    return [[BeanContainer alloc] initWithTestCase:testCase andBeanFilter:^BOOL(PTDBean *bean) {
        return [bean.name hasPrefix:prefix];
    } andOptions:options];
}

- (instancetype)initWithTestCase:(XCTestCase *)testCase andBeanFilter:(BOOL (^)(PTDBean *bean))filter andOptions:(NSDictionary *)options
{
    self = [super init];
    if (!self) return nil;

    _lastPercentagePrinted = -1;
    _beanRssi = -999;  // very small inital value; any RSSI is > -999

    _testCase = testCase;
    _beanFilter = filter;
    _options = options;
    
    _beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    if (_beanManager.state != BeanManagerState_PoweredOn) {
        _beanManagerPoweredOn = [testCase expectationWithDescription:@"Bean Manager powered on"];
        [testCase waitForExpectationsWithTimeout:5 handler:nil];
        _beanManagerPoweredOn = nil;
    }
    
    
    NSError *error;
    [_beanManager startScanningForBeans_error:&error];
    if (error) return nil;

    // Scan for 10 seconds for a Bean that fits our filter with the highest RSSI
    [StatelessUtils delayTestCase:testCase forSeconds:10];
    if (!_bean) return nil;
    
    NSLog(@"Bean selected for testing: %@ (RSSI: %ld)", _bean.name, (long)_beanRssi);

    [_beanManager stopScanningForBeans_error:&error];
    if (error) return nil;
    
    return self;
}

#pragma mark - Interact with Bean

- (BOOL)connect
{
    self.beanConnected = [self.testCase expectationWithDescription:@"Bean connected"];

    NSError *error;
    self.bean.delegate = self;
    [self.beanManager connectToBean:self.bean error:&error];
    if (error) return NO;

    NSTimeInterval defaultTimeout = 20;
    NSTimeInterval override = [(NSNumber *)self.options[@"connectTimeout"] integerValue];
    NSTimeInterval timeout = override ? override : defaultTimeout;
    [self.testCase waitForExpectationsWithTimeout:timeout handler:nil];
    self.beanConnected = nil;

    return (self.bean.state == BeanState_ConnectedAndValidated);
}

- (BOOL)disconnect
{
    self.beanDisconnected = [self.testCase expectationWithDescription:@"Bean connected"];

    NSError *error;
    [self.beanManager disconnectBean:self.bean error:&error];
    if (error) return NO;

    [self.testCase waitForExpectationsWithTimeout:10 handler:nil];
    self.beanDisconnected = nil;
    return (self.bean.state != BeanState_ConnectedAndValidated);
}

- (BOOL)blinkWithColor:(NSColor *)color
{
    self.beanDidUpdateLedColor = [self.testCase expectationWithDescription:@"Bean LED blinked"];
    [self.bean setLedColor:color];

    [self.bean readLedColor];
    [self.testCase waitForExpectationsWithTimeout:10 handler:nil];
    self.beanDidUpdateLedColor = nil;

    NSColor *black = [NSColor colorWithRed:0 green:0 blue:0 alpha:1];
    [self.bean setLedColor:black];
    [StatelessUtils delayTestCase:self.testCase forSeconds:1];

    return [self.ledColor isEqualTo:color];
}

- (BOOL)uploadSketch:(NSString *)hexName
{
    NSData *imageHex = [StatelessUtils bytesFromIntelHexResource:hexName usingBundleForClass:[self class]];
    self.beanDidProgramArduino = [self.testCase expectationWithDescription:@"Sketch uploaded to Bean"];

    NSDate *start = [NSDate date];
    [self.bean programArduinoWithRawHexImage:imageHex andImageName:hexName];
    [self.testCase waitForExpectationsWithTimeout:120 handler:nil];
    self.beanDidProgramArduino = nil;
    NSDate *finish = [NSDate date];

    NSUInteger bytes = [imageHex length];
    NSTimeInterval duration = [finish timeIntervalSinceDate:start];
    float rate = bytes / duration;
    NSLog(@"Sketch upload complete. %lu bytes, %0.2f seconds, %0.1f bytes/sec", bytes, duration, rate);

    return !self.programArduinoError;
}

- (BOOL)updateFirmware
{
    NSArray *imagePaths = [StatelessUtils firmwareImagesFromResource:firmwareImagesFolder];
    NSInteger targetVersion = [StatelessUtils firmwareVersionFromResource:firmwareImagesFolder];
    self.beanCompletedFirmwareUpload = [self.testCase expectationWithDescription:@"Firmware updated for Bean"];

    [self.bean updateFirmwareWithImages:imagePaths andTargetVersion:targetVersion];
    [self.testCase waitForExpectationsWithTimeout:480 handler:nil];
    self.beanCompletedFirmwareUpload = nil;
    
    return !self.firmwareUploadError;
}

- (BOOL)updateFirmwareOnce
{
    NSArray *imagePaths = [StatelessUtils firmwareImagesFromResource:firmwareImagesFolder];
    NSInteger targetVersion = [StatelessUtils firmwareVersionFromResource:firmwareImagesFolder];
    NSString *desc = @"Single firmware image uploaded to Bean";
    self.beanCompletedFirmwareUploadOfSingleImage = [self.testCase expectationWithDescription:desc];
    
    [self.bean updateFirmwareWithImages:imagePaths andTargetVersion:targetVersion];
    [self.testCase waitForExpectationsWithTimeout:120 handler:nil];
    self.beanCompletedFirmwareUploadOfSingleImage = nil;
    
    return !self.firmwareUploadError;
}

- (BOOL)cancelFirmwareUpdate
{
    NSString *desc = @"Firmware update cancelled without error";
    self.beanCompletedFirmwareUpload = [self.testCase expectationWithDescription:desc];

    [self.bean cancelFirmwareUpdate];
    [self.testCase waitForExpectationsWithTimeout:10 handler:nil];
    self.beanCompletedFirmwareUpload = nil;
    
    return !self.firmwareUploadError;
}

- (NSDictionary *)deviceInfo
{
    __block NSString *hardwareVersion;
    __block NSString *firmwareVersion;
    
    XCTestExpectation *hwExpect = [self.testCase expectationWithDescription:@"Bean hardware version retrieved"];
    XCTestExpectation *fwExpect = [self.testCase expectationWithDescription:@"Bean firmware version retrieved"];

    [self.bean checkHardwareVersionAvailableWithHandler:^(BOOL hardwareAvailable, NSError *error) {
        hardwareVersion = self.bean.hardwareVersion;
        [hwExpect fulfill];
    }];
    [self.bean checkFirmwareVersionAvailableWithHandler:^(BOOL firmwareAvailable, NSError *error) {
        firmwareVersion = self.bean.firmwareVersion;
        [fwExpect fulfill];
    }];
    
    [self.testCase waitForExpectationsWithTimeout:10 handler:nil];
    
    if (!hardwareVersion) return nil;
    if (!firmwareVersion) return nil;
    
    return @{@"hardwareVersion": hardwareVersion, @"firmwareVersion": firmwareVersion};
}

#pragma mark - Helpers that depend on BeanContainer state

- (void)printProgressTimeLeft:(NSNumber *)seconds withPercentage:(NSNumber *)percentageComplete
{
    NSInteger percentage = [percentageComplete floatValue] * 100;
    if (percentage != self.lastPercentagePrinted) {
        self.lastPercentagePrinted = percentage;
        NSLog(@"Upload progress: %ld%%, %ld seconds remaining", percentage, [seconds integerValue]);
    }
}

- (void)printProgressIndexSent:(NSUInteger)index
                   totalImages:(NSUInteger)total
                 imageProgress:(NSUInteger)bytesSent
                     imageSize:(NSUInteger)bytesTotal
{
    NSInteger percentage = (float) bytesSent / bytesTotal * 100;
    if (percentage != self.lastPercentagePrinted) {
        self.lastPercentagePrinted = percentage;
        NSLog(@"Upload progress: %ld%% (image %ld/%ld, %ld/%ld bytes)",
              percentage, index + 1, total, bytesSent, bytesTotal);
    }
}

#pragma mark - PTDBeanManagerDelegate

- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager
{
    if (beanManager.state != BeanManagerState_PoweredOn) return;
    [self.beanManagerPoweredOn fulfill];
}

- (void)beanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    if (!self.beanFilter(bean)) return;
    if ([bean.RSSI integerValue] <= self.beanRssi) return;
    self.beanRssi = [bean.RSSI integerValue];

    if ([self.bean isEqualToBean:bean]) return;

    self.bean = bean;
    NSLog(@"New test candidate selected: %@ (RSSI: %@)", bean.name, bean.RSSI);
}

- (void)beanManager:(PTDBeanManager *)beanManager didConnectBean:(PTDBean *)bean error:(NSError *)error
{
    if (![bean isEqualToBean:self.bean]) return;
    if (!self.beanConnected) return;

    [self.beanConnected fulfill];
}

- (void)beanManager:(PTDBeanManager *)beanManager didDisconnectBean:(PTDBean *)bean error:(NSError *)error
{
    if (![bean isEqualToBean:self.bean]) return;
    if (!self.beanDisconnected) return;

    [self.beanDisconnected fulfill];
}

#pragma mark - PTDBeanDelegate

- (void)bean:(PTDBean *)bean didUpdateLedColor:(NSColor *)color
{
    if (![bean isEqualToBean:self.bean]) return;
    if (!self.beanDidUpdateLedColor) return;

    self.ledColor = color;
    [self.beanDidUpdateLedColor fulfill];
}

- (void)bean:(PTDBean *)bean ArduinoProgrammingTimeLeft:(NSNumber *)seconds withPercentage:(NSNumber *)percentageComplete
{
    [self printProgressTimeLeft:seconds withPercentage:percentageComplete];
}

- (void)bean:(PTDBean *)bean
currentImage:(NSUInteger)index
 totalImages:(NSUInteger)total
imageProgress:(NSUInteger)bytesSent
   imageSize:(NSUInteger)bytesTotal
{
    [self printProgressIndexSent:index totalImages:total imageProgress:bytesSent imageSize:bytesTotal];
}

- (void)bean:(PTDBean *)bean didProgramArduinoWithError:(NSError *)error
{
    if (![bean isEqualToBean:self.bean]) return;
    if (!self.beanDidProgramArduino) return;

    self.programArduinoError = error;
    [self.beanDidProgramArduino fulfill];
}

- (void)bean:(PTDBean *)bean completedFirmwareUploadOfSingleImage:(NSString *)imagePath
{
    if (![bean isEqualToBean:self.bean]) return;
    if (!self.beanCompletedFirmwareUploadOfSingleImage) return;

    self.imagePath = imagePath;
    [self.beanCompletedFirmwareUploadOfSingleImage fulfill];
}

- (void)bean:(PTDBean *)bean completedFirmwareUploadWithError:(NSError *)error
{
    if (![bean isEqualToBean:self.bean]) return;
    if (!self.beanCompletedFirmwareUpload) return;
    
    self.firmwareUploadError = error;
    [self.beanCompletedFirmwareUpload fulfill];
}

- (void)beanFoundWithIncompleteFirmware:(PTDBean *)bean
{
    NSLog(@"Refetching firmware images and restarting update process");
    NSArray *imagePaths = [StatelessUtils firmwareImagesFromResource:firmwareImagesFolder];
    NSInteger targetVersion = [StatelessUtils firmwareVersionFromResource:firmwareImagesFolder];
    [self.bean updateFirmwareWithImages:imagePaths andTargetVersion:targetVersion];
}

@end
