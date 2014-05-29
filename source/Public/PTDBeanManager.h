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

/**
 *  The state of the BeanManager bluetooth connection
 */
typedef NS_ENUM(NSUInteger, BeanManagerState) {
    /**
     *  Initializing or an unknown error has occured
     */
    BeanManagerState_Unknown = 0,
    /**
     *  The bluetooth connection is resetting
     */
    BeanManagerState_Resetting,
    /**
     *  An unsupport request has been made
     */
    BeanManagerState_Unsupported,
    /**
     *  Unauthorized access has been attempted
     */
    BeanManagerState_Unauthorized,
    /**
     *  The BeanManager is off
     */
    BeanManagerState_PoweredOff,
    /**
     *  The BeanManager is on
     */
    BeanManagerState_PoweredOn,
};

@protocol PTDBeanManagerDelegate;

/**
 Manages discovery and connection of Beans
 
     Example:
     // create the bean and assign ourselves as the delegate
     self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
     
     // check to make sure we're on
     - (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
       if(self.beanManager.state == BeanManagerState_PoweredOn){
         // if we're on, scan for advertisting beans
         [self.beanManager startScanningForBeans_error:nil];
       }
       else if (self.beanManager.state == BeanManagerState_PoweredOff) {
         // do something else
       }
     }
     // bean discovered
     - (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
       if (error) {
         PTDLog(@"%@", [error localizedDescription]);
         return;
       }
       [self.beanManager connectToBean:bean error:nil];
     }
     // bean connected
     - (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
       if (error) {
         PTDLog(@"%@", [error localizedDescription]);
         return;
       }
       // do stuff with your bean
     }
 
 @see PTDBeanManagerDelegate
 */
@interface PTDBeanManager : NSObject

/// @name Monitoring Properties
/**
 *  The delegate object for the BeanManager. 
 @see PTDBeanManagerDelegate
 */
@property (nonatomic, weak) id<PTDBeanManagerDelegate> delegate;
/**
 The BeanManagerState of the BeanManager
 */
@property (nonatomic, assign, readonly) BeanManagerState state;

/// @name Initializing a Bean Manager
/**
 *  Initializes the BeanManager
 *
 *  @param delegate the delegate for this object
 *
 *  @return an instance of the BeanManager
 */
-(id)initWithDelegate:(id<PTDBeanManagerDelegate>)delegate;

/// @name Scanning or Stopping Scans for Beans
/**
 *  Begins scanning for Beans
 *
 *  @param error see BeanErrors
 */
-(void)startScanningForBeans_error:(NSError**)error;
/**
 *  Stops scanning for Beans
 *
 *  @param error see BeanErrors
 */
-(void)stopScanningForBeans_error:(NSError**)error;

/// @name Establishing or Canceling Connections with Beans
/**
 *  Connects to a Bean
 *
 *  @param bean  the Bean to connect to
 *  @param error see BeanErrors
 */
-(void)connectToBean:(PTDBean*)bean error:(NSError**)error;
/**
 *  Disconnects from a Bean
 *
 *  @param bean  the Bean to disconnect from
 *  @param error see BeanErrors
 */
-(void)disconnectBean:(PTDBean*)bean error:(NSError**)error;
@end

/**
 Delegates of a PTDBeanManager object should implement this protocol. See [BeanXcodeWorkspace](http://www.punchthrough.com) for more examples.
 */
@protocol PTDBeanManagerDelegate <NSObject>
/**
 The state representing the BeanManager

     Example:
     - (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
       // if manager is powered on, start scanning
       if(self.beanManager.state == BeanManagerState_PoweredOn){
         [self.beanManager startScanningForBeans_error:nil];
       }
       else if (self.beanManager.state == BeanManagerState_PoweredOff) {
         // do something else
       }
     }
 
 @param beanManager the BeanManager updating state
 */
- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager;
/**
 A Bean was discovered

    Example:
    // Manager letting us know a Bean was discovered
    - (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean 
        error:(NSError*)error{
      // maintains a list of all discovered beans
      NSUUID * key = bean.identifier;
      if (![self.beans objectForKey:key]) {
        [self.beans setObject:bean forKey:key];
        // attempt to connect to the bean
        [self.beanManager connectToBean:bean error:nil];
      }
    }

 @param beanManager the BeanManager scanning for advertising beans
 @param bean        the Bean
 @param error       not implemented yet
 */
- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error;
/**
 *  A Bean was connected
 *
 *  @param beanManager the BeanManager that connected to an advertising beans
 *  @param bean        the Bean
 *  @param error       error is passed through from [centralManager:didFailToConnectPeripheral:error:](https://developer.apple.com/library/mac/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/translated_content/CBCentralManagerDelegate.html#//apple_ref/occ/intfm/CBCentralManagerDelegate/centralManager:didDisconnectPeripheral:error:)
 */
- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error;
/**
 *  A Bean was disconnected
 *
 *  @param beanManager the BeanManager disconnected from the Bean
 *  @param bean        the Bean
 *  @param error       error is passed through from [centralManager:didDisconnectPeripheral:error:](https://developer.apple.com/library/mac/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/translated_content/CBCentralManagerDelegate.html#//apple_ref/occ/intfm/CBCentralManagerDelegate/centralManager:didDisconnectPeripheral:error:)
 */
- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error;

@end