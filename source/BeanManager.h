//
//  BeanLocator.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 2/18/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "Bean.h"

typedef enum { //These occur in sequence
    BeanManagerStateUnknown = 0,
	BeanManagerStateResetting,
	BeanManagerStateUnsupported,
	BeanManagerStateUnauthorized,
	BeanManagerStatePoweredOff,
	BeanManagerStatePoweredOn,
} BeanManagerState;

@protocol BeanManagerDelegate;

@interface BeanManager : NSObject

@property (nonatomic, assign) id<BeanManagerDelegate> delegate;
@property (nonatomic, readonly) BeanManagerState state;

-(id)initWithDelegate:(id<BeanManagerDelegate>)delegate;

-(void)startScanningForBeans_error:(NSError**)error;

-(void)stopScanningForBeans_error:(NSError**)error;

-(void)connectToBeanWithUUID:(NSUUID*)uuid error:(NSError**)error;

-(void)disconnectBeanWithUUID:(NSUUID*)uuid error:(NSError**)error;

@end


@protocol BeanManagerDelegate <NSObject>

- (void)beanManagerDidUpdateState:(BeanManager *)beanManager;
    
- (void)BeanManager:(BeanManager*)beanManager didDiscoverBean:(NSDictionary *)beanData uuid:(NSUUID*)uuid error:(NSError*)error;

- (void)BeanManager:(BeanManager*)beanManager didConnectToBean:(Bean*)bean error:(NSError*)error;

- (void)BeanManager:(BeanManager*)beanManager didDisconnectBean:(Bean*)bean error:(NSError*)error;

@end