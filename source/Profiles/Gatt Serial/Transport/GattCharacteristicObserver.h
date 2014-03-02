//
//  RxCharacteristicUser.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/13/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GattCharacteristicHandler.h"

@protocol GattCharacteristicHandler;

@protocol GattCharacteristicObserver <NSObject>

-(void)handler:(id<GattCharacteristicHandler>)handler hasReceivedData:(NSData*)data;

-(void)handler:(id<GattCharacteristicHandler>)handler hasTransmittedDataWithError:(NSError*)error;

@end
