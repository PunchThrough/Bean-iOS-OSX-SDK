#import "StatelessUtils.h"
#import "PTDIntelHex.h"


@implementation StatelessUtils

+ (void)delayTestCase:(XCTestCase *)testCase forSeconds:(NSTimeInterval)seconds
{
    XCTestExpectation *waitedForXSeconds = [testCase expectationWithDescription:@"Waited for some specific time"];

    // Delay for some time (??) so that CBCentralManager connection state becomes PoweredOn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [waitedForXSeconds fulfill];
    });

    [testCase waitForExpectationsWithTimeout:seconds + 1 handler:nil];
}

+ (NSData *)bytesFromIntelHexResource:(NSString *)intelHexFilename usingBundleForClass:(id)klass
{
    NSBundle *bundle = [NSBundle bundleForClass:klass];
    NSURL *url = [bundle URLForResource:intelHexFilename withExtension:@"hex"];
    PTDIntelHex *intelHex = [PTDIntelHex intelHexFromFileURL:url];
    return [intelHex bytes];
}

@end
