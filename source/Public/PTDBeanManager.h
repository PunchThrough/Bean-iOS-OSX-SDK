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
    
     //Put the following code in your class initialization
     {
        PTDBeanManager* beanManager;
        // create the Bean Manager and assign ourselves as the delegate
        beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
     }
     
     // check to make sure we're on
     - (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
       if(beanManager.state == BeanManagerState_PoweredOn){
         // if we're on, scan for advertisting beans
         NSError* scanError;
         [beanManager startScanningForBeans_error:&scanError];
         if (scanError) {
            NSLog(@"%@", [scanError localizedDescription]);
         }
       }
       else if (beanManager.state == BeanManagerState_PoweredOff) {
         // do something else
       }
     }
     // bean discovered
     - (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
       if (error) {
         NSLog(@"%@", [error localizedDescription]);
         return;
       }
       NSError* connectError;
       [beanManager connectToBean:bean error:&connectError];
       if (connectError) {
         NSLog(@"%@", [connectError localizedDescription]);
       }
     }
     // bean connected
     - (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
       if (error) {
         NSLog(@"%@", [error localizedDescription]);
         return;
       }
       // do stuff with your Bean
     }
 
 @see PTDBeanManagerDelegate
 */
@interface PTDBeanManager : NSObject

/// @name Monitoring Properties
/**
 *  The delegate object for the BeanManager. Assign your class as this delegate to receive delegate messages.
 @see PTDBeanManagerDelegate
 */
@property (nonatomic, weak) id<PTDBeanManagerDelegate> delegate;
/**
 The <BeanManagerState> state of the BeanManager. Tells you if the Bluetooth Adapter is of, off, unknown, etc.
 */
@property (nonatomic, assign, readonly) BeanManagerState state;

/// @name Initializing a Bean Manager
/**
 *  Initializes the BeanManager with a delegate that implements the PTDBeanManagerDelegate protocol.
 *
 *  @param delegate the <delegate> for this object
 *
 *  @return an instance of the BeanManager
 */
-(id)initWithDelegate:(id<PTDBeanManagerDelegate>)delegate;

/// @name Scanning or Stopping Scans for Beans
/**
 *  Begins scanning for Beans
 *
 *  @param error Nil if successful. See <BeanErrors> for error codes.
 */
-(void)startScanningForBeans_error:(NSError**)error;
/**
 *  Stops scanning for Beans
 *
 *  @param error Nil if successful. See <BeanErrors> for error codes.
 */
-(void)stopScanningForBeans_error:(NSError**)error;

/// @name Establishing or Canceling Connections with Beans
/**
 *  Connects to a Bean
 *
 *  @param bean  The Bean to connect to
 *  @param error Nil if successful. See <BeanErrors> for error codes.
 */
-(void)connectToBean:(PTDBean*)bean error:(NSError**)error;
/**
 *  Disconnects from a Bean
 *
 *  @param bean  The Bean to disconnect from
 *  @param error Nil if successful. See <BeanErrors> for error codes.
 */
-(void)disconnectBean:(PTDBean*)bean error:(NSError**)error;
@end

/**
 Delegates of a <PTDBeanManager> object should implement this protocol. See [BeanXcodeWorkspace](http://www.punchthrough.com) for more examples.
 */
@protocol PTDBeanManagerDelegate <NSObject>
@optional
/**
 The BeanManager's <BeanManagerState> has been updated. This method will also be called when Bluetooth is enabled or disabled.

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
 
 @param beanManager the BeanManager whose state was updated
 */
- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager;
/**
 An advertising Bean was discovered.

    Example:
    // Manager letting us know a Bean was discovered
    - (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
        NSError* connectError;
        [self.beanManager connectToBean:bean error:&connectError];
        if (connectError) {
          NSLog(@"%@", [connectError localizedDescription]);
        }
    }

 @param beanManager The BeanManager scanning for advertising beans
 @param bean        The Bean that was discovered
 @param error       Not implemented yet
 */
- (void)beanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error;
/**
 This method is deprecated. Use <[PTDBeanManager beanManager:didDiscoverBean:error:]> instead.
 @deprecated v0.3.2
 */
- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error __attribute__((deprecated("use beanManager:didDiscoverBean:errror:")));
/**
 *  A Bean was connected
 *
 *  @param beanManager The BeanManager that connected to an advertising beans
 *  @param bean        The Bean that was connected
 *  @param error       This error is passed through from [centralManager:didFailToConnectPeripheral:error:](https://developer.apple.com/library/mac/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/translated_content/CBCentralManagerDelegate.html#//apple_ref/occ/intfm/CBCentralManagerDelegate/centralManager:didDisconnectPeripheral:error:)
 */
- (void)beanManager:(PTDBeanManager*)beanManager didConnectBean:(PTDBean*)bean error:(NSError*)error;
/**
 This method is deprecated. Use <[PTDBeanManager beanManager:didConnectToBean:error:]> instead.
 @deprecated v0.3.2
 */
- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error __attribute__((deprecated("use beanManager:didConnectToBean:error:")));
/**
 *  A Bean was disconnected
 *
 *  @param beanManager The BeanManager that lost connection with the Bean
 *  @param bean        The Bean that was disconnect
 *  @param error       This error is passed through from [centralManager:didDisconnectPeripheral:error:](https://developer.apple.com/library/mac/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/translated_content/CBCentralManagerDelegate.html#//apple_ref/occ/intfm/CBCentralManagerDelegate/centralManager:didDisconnectPeripheral:error:)
 */
- (void)beanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error;
/**
 This method is deprecated. Use <[PTDBeanManager beanManager:didDisconnectBean:error:]> instead.
 @deprecated v0.3.2
 */
- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error __attribute__((deprecated("use beanManager:didDisconnectBean:error:")));

@end