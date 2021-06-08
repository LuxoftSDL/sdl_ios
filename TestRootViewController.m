//
//  TestRootViewController.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 08.06.2021.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "TestRootViewController.h"
#import "ProxyManager.h"
#import "SmartDeviceLink.h"

@interface TestRootViewController ()
@property (nonnull, nonatomic, strong) IBOutlet UITextView *logText;
@property (nonnull, nonatomic, strong) IBOutlet UIButton *btnSubscribe;
@property (nonnull, nonatomic, strong) IBOutlet UIButton *btnUnsubscribe;
@property (nonnull, nonatomic, strong) IBOutlet UIButton *btnGet;
@end


@implementation TestRootViewController {
    SDLNotificationName TestNotificationName;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    TestNotificationName = SDLDidReceiveVehicleDataNotification;
    [self cleanLog];
}

- (IBAction)actionSubscribe:(UIButton *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self subscribeToVehicleData];
}

- (IBAction)actionUnsubscribe:(UIButton *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self unsubscribeToVehicleData];
}

- (IBAction)actionGet:(UIButton *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self getVehicleData];
}

- (IBAction)actionClean:(UIButton *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self cleanLog];
}

- (void)cleanLog {
    self.logText.text = @"";
}

- (void)writeLog:(NSString *)message {
    NSMutableString *log = [self.logText.text mutableCopy];
    if (!log) {
        log = [NSMutableString string];
    }
    [log appendString:message];
    [log appendString:@"\n"];
    self.logText.text = log;
}

#pragma mark - (Un)Subscribe/Get Vehicle Data

/**
 *  Subscribes to tire data. You must subscribe to a notification with name `SDLDidReceiveVehicleData` to get the new data when the tire data changes.
 */
- (void)subscribeToVehicleData {
    SDLLogD(@"Subscribing to tire vehicle data");
    [self.proxyManager.sdlManager subscribeToRPC:TestNotificationName withObserver:self selector:@selector(vehicleDataNotification:)];

    SDLSubscribeVehicleData *subscribeToVehicleData = [[SDLSubscribeVehicleData alloc] init];
    subscribeToVehicleData.tirePressure = @YES;
    __weak typeof(self) weakSelf = self;
    [self.proxyManager.sdlManager sendRequest:subscribeToVehicleData withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleVehicleDataRequest:request response:response error:error];
        });
    }];
}

- (void)getVehicleData {
    SDLLogD(@"Get tire vehicle data");

    SDLGetVehicleData *getVehicleData = [[SDLGetVehicleData alloc] init];
    getVehicleData.tirePressure = @YES;
    __weak typeof(self) weakSelf = self;
    [self.proxyManager.sdlManager sendRequest:getVehicleData withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleVehicleDataRequest:request response:response error:error];
        });
    }];
}

/**
 *  Unsubscribes to vehicle tire data.
 */
- (void)unsubscribeToVehicleData {
    [self.proxyManager.sdlManager unsubscribeFromRPC:TestNotificationName withObserver:self];

    SDLUnsubscribeVehicleData *unsubscribeToVehicleData = [[SDLUnsubscribeVehicleData alloc] init];
    unsubscribeToVehicleData.tirePressure = @YES;
    __weak typeof(self) weakSelf = self;
    [self.proxyManager.sdlManager sendRequest:unsubscribeToVehicleData withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
        NSString *message = [NSString stringWithFormat:@"Unsubscribe result: %@", response.success.boolValue ? @"success" : @"failure"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf writeLog:message];
        });
    }];
}

- (void)handleVehicleDataRequest:(__kindof SDLRPCRequest * _Nullable)request response:(__kindof SDLRPCResponse * _Nullable)response error:(NSError * _Nullable)error {
    if (error) {
        SDLLogE(@"Error sending Get Vehicle Data RPC: %@", error);
    }

    NSString *tag = nil;
    SDLResult resultCode = nil;
    SDLTireStatus *__nullable tireStatus = nil;
    if ([response isKindOfClass:SDLSubscribeVehicleDataResponse.class]) {
        tag = @"SUBSCRIBE";
        SDLSubscribeVehicleDataResponse *subscribeVehicleDataResponse = (SDLSubscribeVehicleDataResponse *)response;
        resultCode = subscribeVehicleDataResponse.resultCode;
        SDLVehicleDataResult *r = subscribeVehicleDataResponse.tirePressure;
        NSLog(@"R:%@", r);
//        tireStatus = r.resultCode
        tireStatus = nil;
    } else if ([response isKindOfClass:SDLGetVehicleDataResponse.class]) {
        tag = @"GET";
        SDLGetVehicleDataResponse* getVehicleDataResponse = (SDLGetVehicleDataResponse *)response;
        resultCode = getVehicleDataResponse.resultCode;
        tireStatus = getVehicleDataResponse.tirePressure;
    } else {
        tag = [NSString stringWithFormat:@"WRONG %@", NSStringFromClass(response.class)];
    }

    NSMutableString *message = [@"TireStatus: " mutableCopy];
    [message appendFormat:@"[%@] ", tag];
    if ([resultCode isEqualToEnum:SDLResultSuccess]) {
        SDLLogD(@"Subscribed to vehicle tire data");
        [message appendString:@"Subscribed"];
    } else if ([resultCode isEqualToEnum:SDLResultDisallowed]) {
        SDLLogD(@"Access to vehicle data disallowed");
        [message appendString:@"Disallowed"];
    } else if ([resultCode isEqualToEnum:SDLResultUserDisallowed]) {
        SDLLogD(@"Vehicle user disabled access to vehicle data");
        [message appendString:@"Disabled"];
    } else if ([resultCode isEqualToEnum:SDLResultIgnored]) {
        SDLLogD(@"Already subscribed to tire data");
        [message appendString:@"Subscribed"];
    } else if ([resultCode isEqualToEnum:SDLResultDataNotAvailable]) {
        SDLLogD(@"You have permission to access to vehicle data, but the vehicle you are connected to did not provide any data");
        [message appendString:@"Unknown"];
    } else {
        SDLLogE(@"Unknown reason for failure to get vehicle data: %@", error != nil ? error.localizedDescription : @"no error message");
        [message appendString:@"Unsubscribed"];
    }

    [message appendFormat:@"\n%@\n======================================\n", [self tireStatusString:tireStatus]];

    [self writeLog:message];
}


/**
 *  Notification containing the updated vehicle data.
 *
 *  @param notification A SDLOnVehicleData notification
 */
- (void)vehicleDataNotification:(SDLRPCNotificationNotification *)notification {
    if (![notification.notification isKindOfClass:SDLOnVehicleData.class]) {
        return;
    }

    SDLOnVehicleData *onVehicleData = (SDLOnVehicleData *)notification.notification;
    SDLTireStatus *tireStatus = onVehicleData.tirePressure;
    [self writeLog:[self tireStatusString:tireStatus]];
}

- (NSString *)tireStatusString:(SDLTireStatus *)tireStatus {
    if (!tireStatus) {
        return @"";
    }

    NSMutableArray *testInfo = [NSMutableArray arrayWithCapacity:10];
    [testInfo addObject:@"OnVehicleData:TireStatus {"];
    NSString *ptt = nil;
    if (nil == tireStatus.pressureTelltale) {
        ptt = @"<null>";
    } else if ([tireStatus.pressureTelltale isEqualToEnum:SDLWarningLightStatusOff]) {
        ptt = @"Off";
    } else if ([tireStatus.pressureTelltale isEqualToEnum:SDLWarningLightStatusOn]) {
        ptt = @"On";
    }  else if ([tireStatus.pressureTelltale isEqualToEnum:SDLWarningLightStatusFlash]) {
        ptt = @"Flash";
    } else if ([tireStatus.pressureTelltale isEqualToEnum:SDLWarningLightStatusNotUsed]) {
        ptt = @"Not Used";
    } else {
        ptt = [NSString stringWithFormat:@"Unexpected value [%@]", tireStatus.pressureTelltale];
    }
    [testInfo addObject:[NSString stringWithFormat:@"•pressureTelltale: '%@'", ptt]];

    [testInfo addObject:[NSString stringWithFormat:@"•leftFront:\n{%@}", [self singleTireStatusString:tireStatus.leftFront]]];
    [testInfo addObject:[NSString stringWithFormat:@"•rightFront:\n{%@}", [self singleTireStatusString:tireStatus.rightFront]]];
    [testInfo addObject:[NSString stringWithFormat:@"•leftRear:\n{%@}", [self singleTireStatusString:tireStatus.leftRear]]];
    [testInfo addObject:[NSString stringWithFormat:@"•rightRear:\n{%@}", [self singleTireStatusString:tireStatus.rightRear]]];
    [testInfo addObject:[NSString stringWithFormat:@"•innerLeftRear:\n{%@}", [self singleTireStatusString:tireStatus.innerLeftRear]]];
    [testInfo addObject:[NSString stringWithFormat:@"•innerRightRear:\n{%@}", [self singleTireStatusString:tireStatus.innerRightRear]]];
    [testInfo addObject:@"}"];

    return [testInfo componentsJoinedByString:@"\n"];
}

- (NSString *)singleTireStatusString:(SDLSingleTireStatus *)singleTireStatus {
    if (!singleTireStatus) {
        return @"<null>";
    }
    NSString *status = nil;
    if (!singleTireStatus.status) {
        status = @"<null>";
    } else if ([singleTireStatus.status isEqualToEnum:SDLComponentVolumeStatusUnknown]) {
        status = @"Unknown";
    } else if ([singleTireStatus.status isEqualToEnum:SDLComponentVolumeStatusNormal]) {
        status = @"Normal";
    } else if ([singleTireStatus.status isEqualToEnum:SDLComponentVolumeStatusLow]) {
        status = @"Low";
    } else if ([singleTireStatus.status isEqualToEnum:SDLComponentVolumeStatusFault]) {
        status = @"Fault";
    } else if ([singleTireStatus.status isEqualToEnum:SDLComponentVolumeStatusAlert]) {
        status = @"Alert";
    } else if ([singleTireStatus.status isEqualToEnum:SDLComponentVolumeStatusNotSupported]) {
        status = @"NotSupported";
    } else {
        status = [NSString stringWithFormat:@"Unexpected value [%@]", singleTireStatus.status];
    }

    NSString *tpms = nil;
    if (!singleTireStatus.monitoringSystemStatus) {
        tpms = @"<null>";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSUnknown]) {
        tpms = @"Unknown";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSSystemFault]) {
        tpms = @"SystemFault";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSSensorFault]) {
        tpms = @"SensorFault";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSLow]) {
        tpms = @"Low";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSSystemActive]) {
        tpms = @"SystemActive";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSTrain]) {
        tpms = @"Train";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSTrainingComplete]) {
        tpms = @"TrainingComplete";
    } else if ([singleTireStatus.monitoringSystemStatus isEqualToEnum:SDLTPMSNotTrained]) {
        tpms = @"NotTrained";
    } else {
        tpms = [NSString stringWithFormat:@"Unexpected value [%@]", singleTireStatus.monitoringSystemStatus];
    }

    NSString *pressure = nil;
    if (!singleTireStatus.pressure) {
        pressure = @"<null>";
    } else {
        pressure = [NSString stringWithFormat:@"%2.2f", singleTireStatus.pressure.floatValue];
    }

    return [NSString stringWithFormat:@"status:%@; tpms:%@; pressure:%@;", status, tpms, pressure];
}

@end
