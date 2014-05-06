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
#import "PTDBean.h"

typedef enum { //These occur in sequence
    BeanManagerState_Unknown = 0,
	BeanManagerState_Resetting,
	BeanManagerState_Unsupported,
	BeanManagerState_Unauthorized,
	BeanManagerState_PoweredOff,
	BeanManagerState_PoweredOn,
} BeanManagerState;

@protocol PTDBeanManagerDelegate;

@interface PTDBeanManager : NSObject

@property (nonatomic, weak) id<PTDBeanManagerDelegate> delegate;
@property (nonatomic, assign, readonly) BeanManagerState state;

-(id)initWithDelegate:(id<PTDBeanManagerDelegate>)delegate;
-(void)startScanningForBeans_error:(NSError**)error;
-(void)stopScanningForBeans_error:(NSError**)error;
-(void)connectToBean:(PTDBean*)bean error:(NSError**)error;
-(void)disconnectBean:(PTDBean*)bean error:(NSError**)error;
@end


@protocol PTDBeanManagerDelegate <NSObject>

- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager;
- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error;
- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error;
- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error;

@end