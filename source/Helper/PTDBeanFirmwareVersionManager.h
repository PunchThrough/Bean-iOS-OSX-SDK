//
//  PTDBeanOADVersionManager.h
//  LightBlue
//
//  Created by Michael Carland on 6/11/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PTDBean.h"

@interface PTDBeanFirmwareVersionManager : NSObject

+ (PTDBeanFirmwareVersionManager *)sharedInstance;

- (NSString *)mostRecentFirmwareVersion;
- (BOOL)firmwarePathsForVersion:(NSString *)version firmwarePathA:(NSString **)firmwarePathA firmwarePathB:(NSString **)firmwarePathB;

@end
