#import <XCTest/XCTest.h>
#import "PTDBeanManager.h"
#import "PTDIntelHex.h"

@interface TestBeanFeatures : XCTestCase <PTDBeanManagerDelegate, PTDBeanDelegate>

#pragma mark Local variables

@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSString *beanName;
@property (nonatomic, strong) __block PTDBean *testBean;

#pragma mark Delegate callbacks

@property (nonatomic, strong) void (^beanDiscovered)(PTDBean *bean);
@property (nonatomic, strong) void (^beanConnected)(PTDBean *bean);
@property (nonatomic, strong) void (^beanLedUpdated)(PTDBean *bean, NSColor *color);
@property (nonatomic, strong) void (^beanSketchUploaded)(PTDBean *bean, NSError *error);

@end

@implementation TestBeanFeatures

#pragma mark - Test prep

- (void)setUp
{
    [super setUp];

    // Prepare BeanManager and make sure it's happy with Bluetooth powered on
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    [self delayForSeconds:1];
    
    self.beanName = @"NEO";
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // clear blocks
    [self cleanup];
}

#pragma mark - Tests

/**
 *  Verify that the LED on our test Bean can be blinked.
 */
- (void)testBlinkBean
{
    NSColor *magenta = [NSColor colorWithRed:1 green:0 blue:1 alpha:1];
    [self discoverBean];
    [self connectBean];
    [self blinkBeanWithColor:magenta];
    [self disconnectBean];
}

/**
 *  Verify that we can upload a sketch to our test Bean.
 */
- (void)testSketchUpload
{
    [self discoverBean];
    [self connectBean];
    [self uploadBinarySketchToBean:@"blink"];
    [self disconnectBean];
}

/**
 *  Verify that the hexDataFromResource helper is properly reading the example sketch.
 */
- (void)testReadHex
{
    NSInteger len = [self bytesFromIntelHexResource:@"blink"].length;
    XCTAssertEqual(len, 5114);  // Verified by hand - blink.hex represents 5114 bytes of raw data
}

#pragma mark - BeanManager delegate

- (void)BeanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    NSLog(@"Discovered Bean: %@", bean);
    if (self.beanDiscovered) {
        self.beanDiscovered(bean);
    }
}

- (void)BeanManager:(PTDBeanManager *)beanManager didConnectToBean:(PTDBean *)bean error:(NSError *)error
{
    NSLog(@"Connected Bean: %@", bean);
    if (self.beanConnected) {
        self.beanConnected(bean);
    }
}

#pragma mark - Bean delegate

- (void)bean:(PTDBean *)bean didUpdateLedColor:(NSColor *)color
{
    NSLog(@"Read color from Bean: %@", bean);
    if (self.beanLedUpdated) {
        self.beanLedUpdated(bean, color);
    }
}

- (void)bean:(PTDBean *)bean didProgramArduinoWithError:(NSError *)error
{
    NSLog(@"Uploaded sketch to Bean: %@", bean);
    if (self.beanSketchUploaded) {
        self.beanSketchUploaded(bean, error);
    }
}

- (void)bean:(PTDBean *)bean ArduinoProgrammingTimeLeft:(NSNumber *)seconds withPercentage:(NSNumber *)percentageComplete
{
    NSLog(@"Upload progress: %ld%%, %ld seconds remaining",
          (NSInteger)([percentageComplete floatValue] * 100),
          [seconds integerValue]);
}

#pragma mark - Test helpers

/**
 *  Delay for a specified period of time.
 *  @param seconds The amount of time to delay, in seconds
 */
- (void)delayForSeconds:(NSTimeInterval)seconds
{
    XCTestExpectation *waitedForXSeconds = [self expectationWithDescription:@"Waited for some specific time"];
    
    // Delay for some time (??) so that CBCentralManager connection state becomes PoweredOn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [waitedForXSeconds fulfill];
    });
    
    [self waitForExpectationsWithTimeout:seconds + 1 handler:nil];
}

/**
 *  Clear our callback blocks so no test interference occurs. This is necessary because blocks are triggered by
 *  BeanManagerDelegate and BeanDelegate.
 */
- (void)cleanup
{
    self.beanDiscovered = nil;
    self.beanConnected = nil;
    self.beanLedUpdated = nil;
    self.beanSketchUploaded = nil;
}

/**
 *  Parse an Intel HEX file with the extension .hex into raw bytes.
 *  @param intelHexFileName The name of the Intel HEX file. For example, to read from mysketch.hex,
 *      intelHexFileName should be "mysketch"
 *  @return An NSData object with the contents of the file, or nil if the file couldn't be opened
 */
- (NSData *)bytesFromIntelHexResource:(NSString *)intelHexFilename
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:intelHexFilename withExtension:@"hex"];
    PTDIntelHex *intelHex = [PTDIntelHex intelHexFromFileURL:url];
    return [intelHex bytes];
}

/**
 *  Discover the Bean with name `beanName` and store it in `testBean`.
 */
- (void)discoverBean
{
    // given
    __weak TestBeanFeatures *self_ = self;
    NSError *error;
    self.testBean = nil;
    
    // when
    XCTestExpectation *beanDiscover = [self expectationWithDescription:@"Target Bean found"];
    self.beanDiscovered = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self_.beanName]) {
            NSLog(@"Discovered target Bean: %@", bean);
            self_.testBean = bean;
            [beanDiscover fulfill];
        }
    };
    
    // scan
    [self.beanManager startScanningForBeans_error:&error];
    if (error) {
        XCTFail(@"startScanningForBeans should not fail");
        return;
    }
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    // stop scan
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        XCTFail(@"stopScanningForBeans should not fail");
        return;
    }
    
    // then
    XCTAssertNotNil(self.testBean, @"targetBean should not be nil");
}

/**
 *  Connect to `testBean`.
 */
- (void)connectBean
{
    // given
    __weak TestBeanFeatures *self_ = self;

    XCTestExpectation *beanConnect = [self expectationWithDescription:@"Target Bean connected"];
    self.beanConnected = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self_.beanName]) {
            NSLog(@"Connected target Bean: %@", bean);
            bean.delegate = self_;
            self_.testBean = bean;
            [beanConnect fulfill];
        }
    };
    
    // when
    NSError *connectError;
    [self.beanManager connectToBean:self.testBean error:&connectError];
    // connectError always throws a "connection in progress" error, so don't assert that it is not nil
    // TODO: Isolate, reproduce error, figure out why this happens

    // then
    [self waitForExpectationsWithTimeout:20 handler:nil];
    XCTAssertTrue(self.testBean.state == BeanState_ConnectedAndValidated);
}

/**
 *  Disconnect from `testBean`.
 */
- (void)disconnectBean
{
    NSError *disconnectError;
    [self.beanManager disconnectBean:self.testBean error:&disconnectError];
    XCTAssertNil(disconnectError);
}

/**
 *  Set the LED on `testBean` to a color and verify its color is set properly, then turn it off.
 *  @param goalColor The color to set Bean's LED to and verify
 */
- (void)blinkBeanWithColor:(NSColor *)goalColor
{
    // given
    __weak TestBeanFeatures *self_ = self;
    XCTestExpectation *beanBlink = [self expectationWithDescription:@"Target Bean blinked"];
    __block NSColor *colorReadFromBean;

    self.beanLedUpdated = ^void(PTDBean *bean, NSColor *colorReceived) {
        if ([bean.name isEqualToString:self_.beanName]) {
            NSLog(@"Read color from target Bean: %@", bean);
            colorReadFromBean = colorReceived;
            [beanBlink fulfill];
        }
    };
    
    // when
    [self.testBean setLedColor:goalColor];
    [self.testBean readLedColor];
    
    // then
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([colorReadFromBean isEqual:goalColor], @"Bean LED color should be %@", goalColor);
    [self.testBean setLedColor:[NSColor colorWithRed:0 green:0 blue:0 alpha:0]];
    [self delayForSeconds:1];
}

/**
 *  Upload a sketch compiled as a raw binary hex file to `testBean`.
 *  @param hexName The name of the hex file to upload.
 *      This name will be used for the Bean's programmed sketch name as well.
 *      This resource must be present in the test bundle.
 *      For example, to upload <code>mysketch.hex</code>, <code>hexName</code> should be <code>mysketch</code>.
 *      The name of Bean's sketch will be set to <code>mysketch</code>.
 */
- (void)uploadBinarySketchToBean:(NSString *)hexName
{
    // given
    __weak TestBeanFeatures *self_ = self;
    NSString *imageName = hexName;
    NSData *imageHex = [self bytesFromIntelHexResource:hexName];
    __block NSError *uploadError;

    XCTestExpectation *uploadSketch = [self expectationWithDescription:@"Target Bean uploaded sketch"];
    self.beanSketchUploaded = ^void(PTDBean *bean, NSError *error) {
        if ([bean.name isEqualToString:self_.beanName]) {
            NSLog(@"Uploaded sketch to target Bean: %@", bean);
            uploadError = error;
            [uploadSketch fulfill];
        }
    };
    
    // when
    [self.testBean programArduinoWithRawHexImage:imageHex andImageName:imageName];
    
    // then
    [self waitForExpectationsWithTimeout:120 handler:nil];
    XCTAssertNil(uploadError, @"Bean sketch should upload successfully");
}


@end
