//
//  PTDBeanRemoteFirmwareVersionManager.m
//  Bean Loader
//
//  Created by Zeke Shearer on 12/1/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBeanRemoteFirmwareVersionManager.h"

static NSString *PTDFirmwareCheckDateKey = @"PTDFirmwareCheckDateKey";
static NSString *PTDNewestFirmwareVersionKey = @"PTDNewestFirmwareVersionKey";
static NSString *PTDFirmwareUrlStringAKey = @"PTDFirmwareUrlStringAKey";
static NSString *PTDFirmwareUrlStringBKey = @"PTDFirmwareUrlStringBKey";
static NSString *PTDFirmwareVersionUrlString = @"http://punchthrough.com/files/bean/oad-images/latest.php";

static NSString *PTDFirmwareVersionJSONKey = @"version";
static NSString *PTDFirmwareUrlBaseKey = @"url";
static NSString *PTDFirmwareUrlAKey = @"img_a";
static NSString *PTDFirmwareUrlBKey = @"img_b";

static NSString *PTDFirmwareRecentVersionKey = @"__RECENT_VERSION__";

@interface PTDFirmwareURLConnection : NSURLConnection

@property (nonatomic, strong) NSString *firmwarePath;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSOutputStream *outputStream;

@end
@implementation PTDFirmwareURLConnection @end

@interface PTDBeanRemoteFirmwareVersionManager () <NSURLConnectionDelegate>

@property (nonatomic, copy) PTDFirmwareFetchCompletion fetchCompletion;
@property (nonatomic, strong) NSDate *firmwareCheckDate;
@property (nonatomic, strong) NSString *newestFirmwareVersion;
@property (nonatomic, strong) NSString *firmwareUrlStringA;
@property (nonatomic, strong) NSString *firmwareUrlStringB;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) PTDFirmwareURLConnection *connectionA;
@property (nonatomic, strong) PTDFirmwareURLConnection *connectionB;
@property (nonatomic, assign) NSUInteger updateRequestsPending;

@property (nonatomic, strong) NSMutableDictionary *availableVersions;
@property (nonatomic, strong) NSString *updateVersion;
@property (nonatomic, strong) NSURL *libraryDirectoryURL;
@property (nonatomic, strong) NSURL *firmwareVersionsURL;

@property (nonatomic, assign, readwrite) BOOL updateFailure;
@property (nonatomic, assign, readwrite) BOOL updateInProgress;


@end

@implementation PTDBeanRemoteFirmwareVersionManager

static PTDBeanRemoteFirmwareVersionManager *_instance = nil;

#pragma mark - Init Methods

+ (PTDBeanRemoteFirmwareVersionManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    static PTDBeanRemoteFirmwareVersionManager *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance= [[PTDBeanRemoteFirmwareVersionManager alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        self.firmwareVersionsURL = [[self libraryDirectoryURL] URLByAppendingPathComponent:@"BeanFirmwareVersions.dat"];
        
        self.availableVersions = [NSMutableDictionary dictionaryWithContentsOfURL:self.firmwareVersionsURL];
        if (!self.availableVersions) {
            self.availableVersions = [NSMutableDictionary dictionary];
        }
        self.newestFirmwareVersion = self.availableVersions[PTDFirmwareRecentVersionKey];
    }
    return self;
}

#pragma mark Getters

- (NSDate *)firmwareCheckDate
{
    if ( !_firmwareCheckDate ) {
        _firmwareCheckDate = [self cachedFirmwareCheckDate];
    }
    return _firmwareCheckDate;
}

- (NSString *)newestFirmwareVersion
{
    if ( !_newestFirmwareVersion ) {
        _newestFirmwareVersion = [self cachedNewestFirmwareVersion];
    }
    return _newestFirmwareVersion;
}

- (NSString *)firmwareUrlStringA
{
    if ( !_firmwareUrlStringA ) {
        _firmwareUrlStringA = [self cachedFirmwareUrlStringA];
    }
    return _firmwareUrlStringA;
}

- (NSString *)firmwareUrlStringB
{
    if ( !_firmwareUrlStringB ) {
        _firmwareUrlStringB = [self cachedFirmwareUrlStringB];
    }
    return _firmwareUrlStringB;
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

#pragma mark - Version Number Fetching

- (void)checkForNewFirmwareWithCompletion:(PTDFirmwareVersionCheckCompletion)completion
{
    NSURLRequest *firmwareVersionRequest;
    
    if ( ![self firmwareCheckDate] || fabs([[self firmwareCheckDate] timeIntervalSinceNow]) > 3600. ) {
        firmwareVersionRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:PTDFirmwareVersionUrlString] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
        [NSURLConnection sendAsynchronousRequest:firmwareVersionRequest queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *jsonError;
            NSDictionary *responseDictionary;
            
            if ( !data || connectionError ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, connectionError);
                });
                return;
            }
            responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if ( !responseDictionary || jsonError ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, connectionError);
                });
                return;
            }
            self.newestFirmwareVersion = responseDictionary[PTDFirmwareVersionJSONKey];
            self.firmwareUrlStringA = responseDictionary[PTDFirmwareUrlBaseKey][PTDFirmwareUrlAKey];
            self.firmwareUrlStringB = responseDictionary[PTDFirmwareUrlBaseKey][PTDFirmwareUrlBKey];
            [self saveFirmwareUrlStringA:self.firmwareUrlStringA];
            [self saveFirmwareUrlStringB:self.firmwareUrlStringB];
            [self saveNewestFirmwareVersion:self.newestFirmwareVersion];
            [self saveFirmwareCheckDate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self.newestFirmwareVersion, nil);
            });
        }];
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(self.newestFirmwareVersion, nil);
        });
    }
}

#pragma mark - Firmware Fetching

- (void)fetchFirmwareForVersion:(NSString *)version withCompletion:(PTDFirmwareFetchCompletion)completion
{
    NSURL *urlA;
    NSURL *urlB;
    NSDictionary *firmwareDictionary;
    NSString *pathA;
    NSString *pathB;
    NSData *imageA;
    NSData *imageB;
    
    firmwareDictionary = self.availableVersions[version];
    if ( firmwareDictionary ) {
        pathA = firmwareDictionary[@"filePathA"];
        pathB = firmwareDictionary[@"filePathB"];
        imageA = [NSData dataWithContentsOfFile:pathA];
        imageB = [NSData dataWithContentsOfFile:pathB];
    }
    //when the app is upgraded, we lose the documents, so we double check that we have the firmware that we think we have.
    if ( imageA && imageB ) {
        completion(pathA, pathB, nil);
    } else {
        self.updateVersion = version;
        self.fetchCompletion = completion;
        self.updateFailure = NO;
        self.updateInProgress = YES;
        self.updateRequestsPending = 2;
        urlA = [NSURL URLWithString:self.firmwareUrlStringA];
        urlB = [NSURL URLWithString:self.firmwareUrlStringB];
        self.connectionA = [self requestFirmware:urlA];
        self.connectionB = [self requestFirmware:urlB];
    }
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
            NSLog(@"Unable to create NSOutputStream for %@", filename);
        }
    }
    self.updateFailure |= (!result);
    return result;
}

- (void)completeUpdate
{
    if (self.updateFailure) {
        [self cleanupConnectionData:self.connectionA];
        [self cleanupConnectionData:self.connectionB];
        if ( self.fetchCompletion ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.fetchCompletion(nil, nil, nil);
                self.fetchCompletion = nil;
            });
        }
    } else {
        self.availableVersions[self.updateVersion] = @{@"version": self.updateVersion,
                                                       @"filePathA": self.connectionA.firmwarePath,
                                                       @"filePathB": self.connectionB.firmwarePath};
        self.availableVersions[PTDFirmwareRecentVersionKey] = self.updateVersion;
        [self.availableVersions writeToURL:self.firmwareVersionsURL atomically:YES];
        if ( self.fetchCompletion ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.fetchCompletion(self.connectionA.firmwarePath, self.connectionB.firmwarePath, nil);
                self.fetchCompletion = nil;
            });
        }
    }
    
    self.connectionA = nil;
    self.connectionB = nil;
    self.updateInProgress = NO;
}

- (void)cleanupConnectionData:(PTDFirmwareURLConnection *)connection
{
    NSError *fileError = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:connection.firmwarePath error:&fileError]) {
        NSLog(@"Error removing failed download file: %@", fileError.localizedDescription);
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
    if ( self.fetchCompletion ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.fetchCompletion(nil, nil, error);
            self.fetchCompletion = nil;
        });
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
            NSLog(@"Error writing firmware data to file %@", connection.filename);
            [connection cancel];
            self.updateFailure = YES;
            break;
        }
        bytesWritten += count;
    }
}

- (void)connectionDidFinishLoading:(PTDFirmwareURLConnection *)connection
{
    [connection.outputStream close];
    self.updateRequestsPending--;
    
    if (!self.updateRequestsPending) {
        [self completeUpdate];
    }
}

#pragma mark - Firmware Version Storing Methods

- (void)saveFirmwareCheckDate
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:PTDFirmwareCheckDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)cachedFirmwareCheckDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:PTDFirmwareCheckDateKey];
}

- (void)saveNewestFirmwareVersion:(NSString *)firmwareVersion
{
    [[NSUserDefaults standardUserDefaults] setObject:firmwareVersion forKey:PTDNewestFirmwareVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)cachedNewestFirmwareVersion
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:PTDNewestFirmwareVersionKey];
}

- (void)saveFirmwareUrlStringA:(NSString *)firmwareUrlString
{
    [[NSUserDefaults standardUserDefaults] setObject:firmwareUrlString forKey:PTDFirmwareUrlStringAKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)cachedFirmwareUrlStringA
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:PTDFirmwareUrlStringAKey];
}

- (void)saveFirmwareUrlStringB:(NSString *)firmwareUrlString
{
    [[NSUserDefaults standardUserDefaults] setObject:firmwareUrlString forKey:PTDFirmwareUrlStringBKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)cachedFirmwareUrlStringB
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:PTDFirmwareUrlStringBKey];
}

@end
