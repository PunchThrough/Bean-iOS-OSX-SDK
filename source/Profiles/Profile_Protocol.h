//
//  Profile_Protocol.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/24/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProfileDelegate_Protocol.h"
#import "BEAN_Helper.h"

@protocol Profile_Protocol <CBPeripheralDelegate>

@required
@property (nonatomic, weak) id<ProfileDelegate_Protocol> profileDelegate;
@property (nonatomic) BOOL isRequired;

-(void)validate;
-(BOOL)isValid:(NSError**)error;

@end
