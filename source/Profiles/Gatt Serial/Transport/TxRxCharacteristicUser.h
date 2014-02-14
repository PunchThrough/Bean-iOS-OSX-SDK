//
//  RxCharacteristicUser.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/13/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TxRxCharacteristicHandler.h"

@protocol TxRxCharacteristicHandler;

@protocol TxRxCharacteristicUser <NSObject>

-(void)handler:(id<TxRxCharacteristicHandler>)handler hasReceivedData:(NSData*)data;

-(void)handler:(id<TxRxCharacteristicHandler>)handler hasTransmittedDataWithError:(NSError*)error;

@end
