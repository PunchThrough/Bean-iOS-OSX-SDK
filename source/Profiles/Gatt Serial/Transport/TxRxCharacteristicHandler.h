//
//  TxCharacteristicHandler.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/13/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TxRxCharacteristicUser.h"

@protocol TxRxCharacteristicUser;

@protocol TxRxCharacteristicHandler <NSObject>

-(void)user:(id<TxRxCharacteristicUser>)user hasDataForTransmission:(NSData*)data error:(NSError**)error;

@end
