//
//  BeanManager_Protected.h
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 3/10/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BeanManager.h"

@protocol BeanManager <NSObject>
-(void)bean:(Bean*)bean hasBeenValidated_error:(NSError*)error;
@end

@interface BeanManager (Protected)<BeanManager>

@end
