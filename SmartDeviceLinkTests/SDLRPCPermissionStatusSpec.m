//
//  SDLRPCPermissionStatusSpec.m
//  SmartDeviceLinkTests
//
//  Created by James Lapinski on 6/29/20.
//  Copyright © 2020 smartdevicelink. All rights reserved.
//

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

#import "SDLRPCPermissionStatus.h"

QuickSpecBegin(SDLRPCPermissionStatusSpec)

describe(@"A rpc permission status", ^{
    __block NSString *testRPCName = nil;
    __block NSString *testParameterName = nil;
    __block BOOL isRPCAllowed = NO;
    __block NSMutableDictionary<NSString *,NSNumber *> *allowedParameters = nil;

    beforeEach(^{
        testRPCName = @"testRPCName";
        testParameterName = @"testParameterRPCName";
        allowedParameters = [@{testParameterName:@0} mutableCopy];
    });

    describe(@"it should initialize correctly", ^{
        __block SDLRPCPermissionStatus *testSDLRPCPermissionStatusSpec = nil;

        beforeEach(^{
            testSDLRPCPermissionStatusSpec = [[SDLRPCPermissionStatus alloc] initWithRPCName:testRPCName isRPCAllowed:isRPCAllowed rpcParameters:allowedParameters];
        });

        it(@"should set the rpcName correctly", ^{
            expect(testSDLRPCPermissionStatusSpec.rpcName).to(equal(testRPCName));
        });

        it(@"should set isRPCAllowed correctly", ^{
            expect(testSDLRPCPermissionStatusSpec.isRPCAllowed).to(equal(isRPCAllowed));
        });

        it(@"should set the parameter permissions correctly", ^{
            expect(testSDLRPCPermissionStatusSpec.rpcParameters[testParameterName]).to(equal(@NO));
        });
    });
});

QuickSpecEnd
