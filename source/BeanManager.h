//
//  BeanLocator.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif
#import "Bean.h"

typedef enum { //These occur in sequence
    BeanManagerState_Unknown = 0,
	BeanManagerState_Resetting,
	BeanManagerState_Unsupported,
	BeanManagerState_Unauthorized,
	BeanManagerState_PoweredOff,
	BeanManagerState_PoweredOn,
} BeanManagerState;

@protocol BeanManagerDelegate;

@interface BeanManager : NSObject

@property (nonatomic, weak) id<BeanManagerDelegate> delegate;
@property (nonatomic, assign, readonly) BeanManagerState state;

-(id)initWithDelegate:(id<BeanManagerDelegate>)delegate;
-(void)startScanningForBeans_error:(NSError**)error;
-(void)stopScanningForBeans_error:(NSError**)error;
-(void)connectToBean:(Bean*)bean error:(NSError**)error;
-(void)disconnectBean:(Bean*)bean error:(NSError**)error;
@end


@protocol BeanManagerDelegate <NSObject>

- (void)beanManagerDidUpdateState:(BeanManager *)beanManager;
- (void)BeanManager:(BeanManager*)beanManager didDiscoverBean:(Bean*)bean error:(NSError*)error;
- (void)BeanManager:(BeanManager*)beanManager didConnectToBean:(Bean*)bean error:(NSError*)error;
- (void)BeanManager:(BeanManager*)beanManager didDisconnectBean:(Bean*)bean error:(NSError*)error;

@end