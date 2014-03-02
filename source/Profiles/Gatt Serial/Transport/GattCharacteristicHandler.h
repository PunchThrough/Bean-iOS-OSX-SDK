//
//  TxCharacteristicHandler.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/13/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GattCharacteristicObserver.h"

@protocol GattCharacteristicObserver;

@protocol GattCharacteristicHandler <NSObject>

-(void)user:(id<GattCharacteristicObserver>)user hasDataForTransmission:(NSData*)data error:(NSError**)error;

@end
