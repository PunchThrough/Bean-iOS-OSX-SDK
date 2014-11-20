//
//  PTDBeanOADVersionManager.m
//  LightBlue
//
//  Created by Michael Carland on 6/11/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBeanFirmwareVersionManager.h"

#define FIRMWARE_STATUS_URL     @"http://punchthrough.com/files/bean/oad-images/latest.php"

#define FIRMWARE_VERSION_KEY    @"version"
#define FIRMWARE_URL_DATA_KEY   @"url"
#define FIRMWARE_IMAGE_A_KEY    @"img_a"
#define FIRMWARE_IMAGE_B_KEY    @"img_b"

#define RECENT_VERSION_KEY      @"__RECENT_VERSION__"

@interface PTDFirmwareURLConnection : NSURLConnection

@property (nonatomic, strong)   NSString        *firmwarePath;
@property (nonatomic, strong)   NSString        *filename;
@property (nonatomic, strong)   NSOutputStream  *outputStream;

@end
@implementation PTDFirmwareURLConnection @end

static PTDBeanFirmwareVersionManager                             *sharedInstance;

@interface PTDBeanFirmwareVersionManager() <NSURLConnectionDelegate>

@property (nonatomic, strong)   NSString                    *currentAvailableVersion;
@property (nonatomic, weak)     NSTimer                     *updateCheckTimer;

@property (nonatomic)           BOOL                        updateInProgress;
@property (nonatomic)           BOOL                        updateFailure;
@property (nonatomic)           NSUInteger                  updateRequestsPending;
@property (nonatomic, strong)   NSString                    *updateVersion;
@property (nonatomic, strong)   PTDFirmwareURLConnection    *connectionA;
@property (nonatomic, strong)   PTDFirmwareURLConnection    *connectionB;

@property (nonatomic, strong)   NSMutableDictionary         *availableVersions;
@property (nonatomic, strong)   NSURL                       *libraryDirectoryURL;
@property (nonatomic, strong)   NSURL                       *firmwareVersionsURL;

@end

@implementation PTDBeanFirmwareVersionManager

+ (PTDBeanFirmwareVersionManager *)sharedInstance
{
    return sharedInstance;
}

+ (void)initialize
{
    sharedInstance = [[PTDBeanFirmwareVersionManager alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        
        self.firmwareVersionsURL = [[self libraryDirectoryURL] URLByAppendingPathComponent:@"BeanFirmwareVersions.dat"];
        
        self.availableVersions = [NSMutableDictionary dictionaryWithContentsOfURL:self.firmwareVersionsURL];
        if (!self.availableVersions) {
            self.availableVersions = [NSMutableDictionary dictionary];
        }
        
        self.currentAvailableVersion = self.availableVersions[RECENT_VERSION_KEY];
        
        // TODO: purge older firmware files.
        
        // Check every 60 minutes for updated firmware
        NSTimer *updateCheckTimer = [NSTimer scheduledTimerWithTimeInterval:3600.0
                                                                     target:self
                                                                   selector:@selector(updateCheckTimerFired:)
                                                                   userInfo:nil
                                                                    repeats:YES];
        self.updateCheckTimer = updateCheckTimer;
        
        [self beginUpdate];
    }
    return self;
}

- (void)updateCheckTimerFired:(NSTimer *)timer
{
    [self beginUpdate];
}

- (void)beginUpdate
{
    if (self.updateInProgress) {
        NSLog(@"Bean OAD firmware update requested, already in progress.\n");
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:FIRMWARE_STATUS_URL]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   NSLog(@"Unable to retrieve BEAN OAD firmware metadata. Error: %@\n", connectionError.localizedDescription);
                                   self.updateInProgress = NO;
                                   return;
                               }
                               
                               NSError *jsonError = nil;
                               NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:kNilOptions
                                                                                      error:&jsonError];
                               if (jsonError) {
                                   NSLog(@"Unable to parse BEAN OAD firmware metadata. Error: %@\n", jsonError.localizedDescription);
                                   self.updateInProgress = NO;
                                   return;
                               }
                               
                               [self downloadLatestFirmware:json];
                           }];
}

- (void)downloadLatestFirmware:(NSDictionary *)json
{
    NSString *availableVersion = json[FIRMWARE_VERSION_KEY];
    
    if ([self.availableVersions.allKeys containsObject:availableVersion]) {
        NSLog(@"Already have available bean firmware version '%@'.\n", availableVersion);
        self.currentAvailableVersion = availableVersion;
        self.updateInProgress = NO;
        return;
    }
    
    NSLog(@"Starting download of firmware version '%@'\n", availableVersion);
    self.updateVersion = availableVersion;
    self.updateRequestsPending = 2;
    self.updateFailure = NO;
    
    NSURL *firmwareA = [NSURL URLWithString:json[FIRMWARE_URL_DATA_KEY][FIRMWARE_IMAGE_A_KEY]];
    self.connectionA = [self requestFirmware:firmwareA];
    NSURL *firmwareB = [NSURL URLWithString:json[FIRMWARE_URL_DATA_KEY][FIRMWARE_IMAGE_B_KEY]];
    self.connectionB = [self requestFirmware:firmwareB];
}

- (PTDFirmwareURLConnection *)requestFirmware:(NSURL *)url
{
    PTDFirmwareURLConnection *result = nil;
    
    NSURL *libraryDirectory = [self libraryDirectoryURL];
    if (libraryDirectory) {
        NSString *filename = [url lastPathComponent];
        NSString *firmwarePath = [[libraryDirectory URLByAppendingPathComponent:filename] path];
        NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:firmwarePath append:NO];
        if (outputStream) {
            [outputStream open];
            
            result = [[PTDFirmwareURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:url]
                                                              delegate:self];
            result.filename = filename;
            result.firmwarePath = firmwarePath;
            result.outputStream = outputStream;
        } else {
            NSLog(@"Unable to create NSOutputStream for %@\n", filename);
        }
    }
    
    self.updateFailure |= (!result);
    return result;
}

- (void)compareBeanToAvailableVersion:(PTDBean *)bean
{
    if (self.currentAvailableVersion) {
        NSString *beanVersion = [bean firmwareVersion];
        if (![beanVersion isEqualToString:self.currentAvailableVersion]) {
            
        }
    }
}

- (NSString *)mostRecentFirmwareVersion
{
    return self.currentAvailableVersion;
}

- (NSURL *)libraryDirectoryURL
{
    if (!_libraryDirectoryURL) {
        NSError *error = nil;
        _libraryDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
                                                                      inDomain:NSUserDomainMask
                                                             appropriateForURL:nil
                                                                        create:YES
                                                                         error:&error];
        if (error) {
            NSLog(@"Error finding application Library directory: %@\n", error.localizedDescription);
        }
    }
    
    return _libraryDirectoryURL;
}

- (BOOL)firmwarePathsForVersion:(NSString *)version firmwarePathA:(NSString **)firmwarePathA firmwarePathB:(NSString **)firmwarePathB
{
    NSDictionary *versionInfo = self.availableVersions[version];
    if (versionInfo) {
        if (firmwarePathA) {
            *firmwarePathA = versionInfo[@"filePathA"];
        }
        if (firmwarePathB) {
            *firmwarePathB = versionInfo[@"filePathB"];
        }
        
        return YES;
    }
    
    return NO;
}

- (void)completeUpdate
{
    if (self.updateFailure) {
        [self cleanupConnectionData:self.connectionA];
        [self cleanupConnectionData:self.connectionB];
    } else {
        self.availableVersions[self.updateVersion] = @{@"version": self.updateVersion,
                                                       @"filePathA": self.connectionA.firmwarePath,
                                                       @"filePathB": self.connectionB.firmwarePath};
        self.availableVersions[RECENT_VERSION_KEY] = self.updateVersion;
        self.currentAvailableVersion = self.updateVersion;
        [self.availableVersions writeToURL:self.firmwareVersionsURL atomically:YES];
    }
    
    self.connectionA = nil;
    self.connectionB = nil;
    self.updateInProgress = NO;
}

- (void)cleanupConnectionData:(PTDFirmwareURLConnection *)connection
{
    NSError *fileError = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:connection.firmwarePath error:&fileError]) {
        NSLog(@"Error removing failed download file: %@\n", fileError.localizedDescription);
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(PTDFirmwareURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Bean Firmware download failed: %@\n", error.localizedDescription);
    [connection.outputStream close];
    self.updateRequestsPending--;
    self.updateFailure = YES;
    
    if (!self.updateRequestsPending) {
        [self completeUpdate];
    }
}

#pragma mark - NSLURLConnectionDataDelegate

- (void)connection:(PTDFirmwareURLConnection *)connection didReceiveData:(NSData *)data
{
    NSUInteger totalBytes = data.length;
    const uint8_t *dataPtr = data.bytes;
    NSUInteger bytesWritten = 0;
    
    while (bytesWritten < totalBytes) {
        NSInteger count = [connection.outputStream write:&dataPtr[bytesWritten] maxLength:totalBytes - bytesWritten];
        if (count == -1) {
            NSLog(@"Error writing firmware data to file %@\n", connection.filename);
            [connection cancel];
            self.updateFailure = YES;
            break;
        }
        bytesWritten += count;
    }
}

- (void)connectionDidFinishLoading:(PTDFirmwareURLConnection *)connection
{
    NSLog(@"Bean Firmware download '%@' complete.\n", connection.filename);
    [connection.outputStream close];
    self.updateRequestsPending--;
    
    if (!self.updateRequestsPending) {
        [self completeUpdate];
    }
}


@end
