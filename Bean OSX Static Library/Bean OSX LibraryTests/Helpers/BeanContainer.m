#import "BeanContainer.h"
#import "PTDBeanManager.h"
#import "StatelessUtils.h"

@interface BeanContainer () <PTDBeanManagerDelegate, PTDBeanDelegate>

@property (nonatomic, strong) XCTestCase *testCase;
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSString *beanNamePrefix;
@property (nonatomic, strong) PTDBean *bean;

@property (nonatomic, strong) XCTestExpectation *beanDiscovered;
@property (nonatomic, strong) XCTestExpectation *beanConnected;
@property (nonatomic, strong) XCTestExpectation *beanDisconnected;

@end

@implementation BeanContainer

+ (BeanContainer *)containerWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix
{
    return [[BeanContainer alloc] initWithTestCase:testCase andBeanNamePrefix:prefix];
}

- (instancetype)initWithTestCase:(XCTestCase *)testCase andBeanNamePrefix:(NSString *)prefix
{
    self = [super init];
    if (self) {
        _testCase = testCase;
        _beanNamePrefix = prefix;

        // Set up BeanManager and give it one second to power Bluetooth on
        _beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
        [StatelessUtils delayTestCase:testCase forSeconds:1];

        _beanDiscovered = [testCase expectationWithDescription:@"Bean with prefix found"];

        NSError *error;
        [_beanManager startScanningForBeans_error:&error];
        if (error) return nil;

        [testCase waitForExpectationsWithTimeout:10 handler:nil];
        self.beanDiscovered = nil;
        if (!_bean) return nil;
    }
    return self;
}

- (BOOL)connect
{
    self.beanConnected = [self.testCase expectationWithDescription:@"Bean connected"];

    NSError *error;
    [self.beanManager connectToBean:self.bean error:&error];
    if (error) return NO;

    [self.testCase waitForExpectationsWithTimeout:30 handler:nil];
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
    return YES;
}

- (void)beanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    if ([bean.name hasPrefix:self.beanNamePrefix]) {
        self.bean = bean;
        if (self.beanDiscovered) [self.beanDiscovered fulfill];
    }
}

- (void)beanManager:(PTDBeanManager *)beanManager didConnectBean:(PTDBean *)bean error:(NSError *)error
{
    if ([bean isEqualToBean:self.bean]) {
        if (self.beanConnected) [self.beanConnected fulfill];
    }
}

- (void)beanManager:(PTDBeanManager *)beanManager didDisconnectBean:(PTDBean *)bean error:(NSError *)error
{
    if ([bean isEqualToBean:self.bean]) {
        if (self.beanDisconnected) [self.beanDisconnected fulfill];
    }
}

@end
