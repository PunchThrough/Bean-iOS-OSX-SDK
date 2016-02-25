#import "BeanContainer.h"
#import "PTDBeanManager.h"
#import "StatelessUtils.h"

@interface BeanContainer () <PTDBeanManagerDelegate, PTDBeanDelegate>

@property (nonatomic, strong) XCTestCase *testCase;
@property (nonatomic, strong) PTDBeanManager *beanManager;
@property (nonatomic, strong) NSString *beanNamePrefix;
@property (nonatomic, strong) PTDBean *bean;
@property (nonatomic, strong) XCTestExpectation *beanDiscovered;

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
        if (error) {
            return nil;
        }

        [testCase waitForExpectationsWithTimeout:10 handler:nil];
        if (!_bean) {
            return nil;
        }
    }
    return self;
}

- (void)beanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error {
    if ([bean.name hasPrefix:self.beanNamePrefix]) {
        self.bean = bean;
        [self.beanDiscovered fulfill];
    }
}

@end
