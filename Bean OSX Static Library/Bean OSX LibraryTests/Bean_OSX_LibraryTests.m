//
//  Bean_OSX_LibraryTests.m
//  Bean OSX LibraryTests
//
//  Created by Raymond Kampmeier on 2/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PTDBeanManager.h"

@interface Bean_OSX_LibraryTests : XCTestCase <PTDBeanManagerDelegate, PTDBeanDelegate>

#pragma mark Local variables

@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSString *beanName;
@property (nonatomic, strong) __block PTDBean *testBean;

#pragma mark Delegate callbacks

@property (nonatomic, strong) void (^beanDiscovered)(PTDBean *bean);
@property (nonatomic, strong) void (^beanConnected)(PTDBean *bean);
@property (nonatomic, strong) void (^beanLedUpdated)(PTDBean *bean, NSColor *color);
@property (nonatomic, strong) void (^beanSketchUpdated)(PTDBean *bean, NSString *name);

@end

@implementation Bean_OSX_LibraryTests

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

- (void)testDiscoverBean
{
    [self discoverBean];
}

- (void)testConnectBean
{
    [self discoverBean];
    [self connectBean];
    [self disconnectBean];
}

- (void)testBlinkBean
{
    [self discoverBean];
    [self connectBean];
    [self blinkBean];
    [self disconnectBean];
}

- (void)testSketchUpload
{
    [self discoverBean];
    [self connectBean];
    [self sketchUpload];
    [self disconnectBean];
}

/**
 * Verify that the hexDataFromResource helper is properly reading the example sketch.
 */
- (void)testReadHex
{
    NSInteger len = [self hexDataFromResource:@"blink"].length;
    XCTAssertEqual(len, 14414);
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

- (void)bean:(PTDBean *)bean didUpdateSketchName:(NSString *)name dateProgrammed:(NSDate *)date crc32:(UInt32)crc
{
    NSLog(@"Uploaded sketch to Bean: %@", bean);
    if (self.beanSketchUpdated) {
        self.beanSketchUpdated(bean, name);
    }
}

#pragma mark - Test helpers

- (void)delayForSeconds:(NSInteger)seconds
{
    XCTestExpectation *waitedForXSeconds = [self expectationWithDescription:@"Waited for some specific time"];
    
    // Delay for some time (??) so that CBCentralManager connection state becomes PoweredOn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [waitedForXSeconds fulfill];
    });
    
    [self waitForExpectationsWithTimeout:seconds + 1 handler:nil];
}

- (void)cleanup
{
    // reset blocks so no test interference occurs, since blocks are triggered by BeanManager delegates
    self.beanDiscovered = nil;
    self.beanConnected = nil;
    self.beanLedUpdated = nil;
}

/**
 * Get the data from a .hex file in the test resources folder.
 * @param hexFileName The name of the hex file. For example, to read from mysketch.hex, hexFileName should be "mysketch"
 * @return An NSData object with the contents of the file, or nil if the file couldn't be opened
 */
- (NSData *)hexDataFromResource:(NSString *)hexFileName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:hexFileName ofType:@"hex"];
    return [NSData dataWithContentsOfFile:path];
}

- (void)discoverBean
{
    // given
    NSError *error;
    self.testBean = nil;
    
    // when
    XCTestExpectation *beanDiscover = [self expectationWithDescription:@"Target Bean found"];
    self.beanDiscovered = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Discovered target Bean: %@", bean);
            self.testBean = bean;
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

- (void)connectBean
{
    // given
    NSError *error;
    
    // when
    XCTestExpectation *beanConnect = [self expectationWithDescription:@"Target Bean connected"];
    self.beanConnected = ^void(PTDBean *bean) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Connected target Bean: %@", bean);
            bean.delegate = self;
            self.testBean = bean;
            [beanConnect fulfill];
        }
    };
    
    // connect
    NSError *connectError;
    [self.beanManager connectToBean:self.testBean error:&connectError];
    // connectError always throws a "connection in progress" error, so don't assert that it is not nil
    // TODO: Isolate, reproduce error, figure out why this happens

    // then
    [self waitForExpectationsWithTimeout:20 handler:nil];
    XCTAssertTrue(self.testBean.state == BeanState_ConnectedAndValidated);
}

- (void)disconnectBean
{
    NSError *disconnectError;
    [self.beanManager disconnectBean:self.testBean error:&disconnectError];
    XCTAssertNil(disconnectError);
}

- (void)blinkBean
{
    // given
    NSColor *lightBlue = [NSColor colorWithRed:0 green:1 blue:1 alpha:1];
    XCTestExpectation *beanBlink = [self expectationWithDescription:@"Target Bean blinked"];
    self.beanLedUpdated = ^void(PTDBean *bean, NSColor *color) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Read color from target Bean: %@", bean);
            XCTAssertTrue([color isEqual:lightBlue], @"Bean LED color should be light blue");
            [beanBlink fulfill];
        }
    };
    
    // when
    [self.testBean setLedColor: lightBlue];
    [self.testBean readLedColor];
    
    // then
    [self waitForExpectationsWithTimeout:10 handler:nil];
    [self.testBean setLedColor: [NSColor colorWithRed:0 green:0 blue:0 alpha:0]];
    [self delayForSeconds:1];
}

- (void)sketchUpload
{
    // given
    NSString *imageName = @"TestSketch";
    NSData *imageHex = [NSData dataWithContentsOfFile:@"/Resources/blink.hex"];
    XCTestExpectation *uploadSketch = [self expectationWithDescription:@"Target Bean uploaded sketch"];
    self.beanSketchUpdated = ^void(PTDBean *bean, NSString *name) {
        if ([bean.name isEqualToString:self.beanName]) {
            NSLog(@"Read color from target Bean: %@", bean);
            XCTAssertTrue([name isEqual:imageName], @"Bean sketch should be TestSketch");
            [uploadSketch fulfill];
        }
    };
    
    // when
    [self.testBean programArduinoWithRawHexImage:imageHex andImageName:imageName];
    
    // then
    [self waitForExpectationsWithTimeout:60 handler:nil];

}


@end
