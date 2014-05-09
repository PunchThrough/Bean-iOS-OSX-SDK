//
//  BeanManager_Protected.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 3/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "PTDBeanManager.h"

@protocol PTDBeanManager <NSObject>
-(void)bean:(PTDBean*)bean hasBeenValidated_error:(NSError*)error;
@end

@interface PTDBeanManager (Protected)<PTDBeanManager>

@end
