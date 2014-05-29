//
//  BleProfile.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/8/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BleProfile.h"

@implementation BleProfile

-(id)init
{
    self = [super init];
    if (self) {
        //Init Code
        _isRequired = TRUE;
        profileHasReportedValidity = FALSE;
    }
    return self;
}

-(void)validate{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}
-(BOOL)isValid:(NSError**)error{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return FALSE;
}

-(void)__notifyValidity
{
    if(profileHasReportedValidity == FALSE)
    {
        if (self.profileDelegate)
        {
            if([self.profileDelegate respondsToSelector:@selector(profileValidated:)])
            {
                [self.profileDelegate profileValidated:self];
            }
        }
    }
    profileHasReportedValidity = TRUE;
}
@end
