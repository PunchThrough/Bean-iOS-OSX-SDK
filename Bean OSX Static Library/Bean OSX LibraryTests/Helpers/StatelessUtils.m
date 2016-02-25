//
// Created by Matthew Lewis on 2/25/16.
// Copyright (c) 2016 Punch Through Design. All rights reserved.
//

#import "StatelessUtils.h"


@implementation StatelessUtils

/**
 *  Delay for a specified period of time.
 *  @param testCase The XCTestCase calling this method (usually, self)
 *  @param seconds The amount of time to delay, in seconds
 */
+ (void)delayTestCase:(XCTestCase *)testCase forSeconds:(NSTimeInterval)seconds
{
    XCTestExpectation *waitedForXSeconds = [testCase expectationWithDescription:@"Waited for some specific time"];

    // Delay for some time (??) so that CBCentralManager connection state becomes PoweredOn
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [waitedForXSeconds fulfill];
    });

    [testCase waitForExpectationsWithTimeout:seconds + 1 handler:nil];
}

@end
