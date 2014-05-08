//
//  ProfileDelegate_Protocol.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/24/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Profile_Protocol;
@protocol ProfileDelegate_Protocol <NSObject>

-(void)profileValidated:(id<Profile_Protocol>)profile;

@end
