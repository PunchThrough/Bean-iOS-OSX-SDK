#import "StatelessUtils.h"
#import <OCMock/OCMock.h>
#import "PTDIntelHex.h"
#import "PTDUtils.h"
#import "PTDHardwareLookup.h"

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

+ (NSArray *)firmwareImagesFromResource:(NSString *)imageFolder withHardwareName:(NSString *)hardwareName
{
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString *path = [resourcePath stringByAppendingPathComponent:imageFolder];
    path = [path stringByAppendingPathComponent:[PTDHardwareLookup hardwareNameForVersion:hardwareName]];
    NSLog(@"Path = %@", path);
    
    NSError *error;
    NSArray *imageNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        return nil;
    }
    
    // build full resource path to each firmware image
    NSMutableArray *firmwarePaths = [NSMutableArray new];
    for (NSString *imageName in imageNames){
        if (![imageName hasSuffix:@".bin"]) continue;
        [firmwarePaths addObject:[path stringByAppendingPathComponent:imageName]];
    }
    
    return firmwarePaths;
}

+ (NSNumber *)firmwareVersionFromResource:(NSString *)imageFolder withHardwareName:(NSString *)hardwareName
{
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString *folderPath = [resourcePath stringByAppendingPathComponent:imageFolder];
    folderPath = [folderPath stringByAppendingPathComponent:[PTDHardwareLookup hardwareNameForVersion:hardwareName]];
    NSString *versionFile = [folderPath stringByAppendingPathComponent:@"version.txt"];
    NSError *error;
    NSString *versionFileData = [NSString stringWithContentsOfFile:versionFile encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Could not open version file (%@): %@", versionFile, error);
        return nil;
    }
    NSNumber *asNumber = [PTDUtils parseLeadingInteger:versionFileData];
    return asNumber;
}

+ (PTDBean *)fakeBeanWithFirmware:(NSString *)version;
{
    PTDBean *bean = OCMClassMock([PTDBean class]);
    OCMStub(bean.firmwareVersion).andReturn(version);
    return bean;
}

@end
