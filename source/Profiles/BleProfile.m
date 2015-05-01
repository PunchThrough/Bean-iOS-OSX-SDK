//
//  BleProfile.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/8/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BleProfile.h"

static NSMutableDictionary * registeredSubclasses;

@implementation BleProfile

-(id)init
{
    self = [super init];
    if (self) {
        //Init Code
        //_isRequired = TRUE;
        profileHasReportedValidity = FALSE;
    }
    return self;
}

-(id)initWithService:(CBService*)service
{
    self = [super init];
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
        if (self.validationcompletion)
            self.validationcompletion(nil);

    profileHasReportedValidity = TRUE;
}

+(void)registerProfile:(Class)subclass serviceUUID:(NSString*)uuid
{
    CBUUID* cbuuid = [CBUUID UUIDWithString:uuid];

    if ( !registeredSubclasses )
        registeredSubclasses = [[NSMutableDictionary alloc] init];
    
    if ( !registeredSubclasses[cbuuid] )
        registeredSubclasses[cbuuid] = subclass;
    else
        PTDLog(@"Error, service %@ already registered to %@", uuid, subclass);
}

// Factory class
+(BleProfile *)createBleProfileWithService:(CBService*)service
{
    if ( registeredSubclasses[service.UUID] )
        return [[registeredSubclasses[service.UUID] alloc] initWithService:service];
    else
        return NULL;
}

+(NSArray *)registeredProfiles
{
    return [registeredSubclasses allKeys];
}

@end