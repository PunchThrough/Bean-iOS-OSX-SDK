//
//  BleProfile.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 5/8/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "BleProfile.h"

static NSMutableDictionary * registeredSubclasses;

@interface BleProfile ()
@property (nonatomic, copy) void (^validationcompletion)(NSError *error);
@end 

@implementation BleProfile

-(id)init
{
    self = [super init];
    if (self) {
        //Init Code
        profileHasReportedValidity = FALSE;
    }
    return self;
}

-(void)validateWithCompletion:(void (^)(NSError *error))completion
{
    self.validationcompletion = completion;
    
    // Call the subclass implementation of "validate"
    [self validate];
}

#pragma mark - protected methods
-(void)__notifyValidity
{
    if( profileHasReportedValidity == FALSE
       && self.validationcompletion ){
        self.validationcompletion(nil);
    }

    profileHasReportedValidity = TRUE;
}

#pragma mark - Pure virtual methods (Must be overridden in subclass)
-(void)validate{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

-(BOOL)isValid:(NSError**)error{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return FALSE;
}

#pragma mark - Class factory methods
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