//
//  SDLGetVehicleDataResponseSpec.m
//  SmartDeviceLink


#import <Foundation/Foundation.h>

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>

#import "SmartDeviceLink.h"
#import "SDLRPCParameterNames.h"
#import "SDLRPCFunctionNames.h"


QuickSpecBegin(SDLGetVehicleDataResponseSpec)

// set up all test constants
SDLGPSData* gps = [[SDLGPSData alloc] init];
SDLTireStatus* tirePressure = [[SDLTireStatus alloc] init];
SDLBeltStatus* beltStatus = [[SDLBeltStatus alloc] init];
SDLBodyInformation* bodyInformation = [[SDLBodyInformation alloc] init];
SDLDeviceStatus* deviceStatus = [[SDLDeviceStatus alloc] init];
SDLHeadLampStatus* headLampStatus = [[SDLHeadLampStatus alloc] init];
SDLECallInfo* eCallInfo = [[SDLECallInfo alloc] init];
SDLAirbagStatus* airbagStatus = [[SDLAirbagStatus alloc] init];
SDLEmergencyEvent* emergencyEvent = [[SDLEmergencyEvent alloc] init];
SDLClusterModeStatus* clusterModeStatus = [[SDLClusterModeStatus alloc] init];
SDLMyKey* myKey = [[SDLMyKey alloc] init];
SDLFuelRange* fuelRange = [[SDLFuelRange alloc] init];
NSArray<SDLFuelRange*> *fuelRangeArray = @[fuelRange, fuelRange];
NSString* vin = @"6574839201a";
NSString* cloudAppVehicleID = @"cloud-6f56054e-d633-11ea-999a-14109fcf4b5b";
const float speed = 123.45;
const NSUInteger rpm = 3599;
const float fuelLevel = 34.45;
SDLComponentVolumeStatus fuelLevel_State = SDLComponentVolumeStatusLow;
const float instantFuelConsumption = 45.67;
const float externalTemperature = 56.67;
SDLTurnSignal turnSignal = SDLTurnSignalLeft;
SDLPRNDL prndl = SDLPRNDLReverse;
const NSUInteger odometer = 100999;
SDLVehicleDataEventStatus driverBraking = SDLVehicleDataEventStatusYes;
SDLWiperStatus wiperStatus = SDLWiperStatusWash;
const float steeringWheelAngle = 359.99;
const float engineTorque = 999.123;
const float accPedalPosition = 35.88;
const float engineOilLife = 98.76;
SDLElectronicParkBrakeStatus electronicParkBrakeStatus = SDLElectronicParkBrakeStatusTransition;
NSArray<SDLWindowStatus *> *windowStatus = @[[[SDLWindowStatus alloc] init], [[SDLWindowStatus alloc] init]];

describe(@"getter/setter tests", ^{
    context(@"init and assign", ^{
        SDLGetVehicleDataResponse* testResponse = [[SDLGetVehicleDataResponse alloc] init];

        testResponse.accPedalPosition = @(accPedalPosition);
        testResponse.airbagStatus = airbagStatus;
        testResponse.beltStatus = beltStatus;
        testResponse.bodyInformation = bodyInformation;
        testResponse.cloudAppVehicleID = cloudAppVehicleID;
        testResponse.clusterModeStatus = clusterModeStatus;
        testResponse.deviceStatus = deviceStatus;
        testResponse.driverBraking = driverBraking;
        testResponse.eCallInfo = eCallInfo;
        testResponse.electronicParkBrakeStatus = electronicParkBrakeStatus;
        testResponse.emergencyEvent = emergencyEvent;
        testResponse.engineOilLife = @(engineOilLife);
        testResponse.engineTorque = @(engineTorque);
        testResponse.externalTemperature = @(externalTemperature);
        testResponse.fuelLevel = @(fuelLevel);
        testResponse.fuelLevel_State = fuelLevel_State;
        testResponse.fuelRange = fuelRangeArray;
        testResponse.gps = gps;
        testResponse.headLampStatus = headLampStatus;
        testResponse.instantFuelConsumption = @(instantFuelConsumption);
        testResponse.myKey = myKey;
        testResponse.odometer = @(odometer);
        testResponse.prndl = prndl;
        testResponse.rpm = @(rpm);
        testResponse.speed = @(speed);
        testResponse.steeringWheelAngle = @(steeringWheelAngle);
        testResponse.tirePressure = tirePressure;
        testResponse.turnSignal = turnSignal;
        testResponse.vin = vin;
        testResponse.wiperStatus = wiperStatus;

        it(@"expect all properties to be set properly", ^{
            expect(testResponse.accPedalPosition).to(equal(@(accPedalPosition)));
            expect(testResponse.airbagStatus).to(equal(airbagStatus));
            expect(testResponse.beltStatus).to(equal(beltStatus));
            expect(testResponse.bodyInformation).to(equal(bodyInformation));
            expect(testResponse.cloudAppVehicleID).to(equal(cloudAppVehicleID));
            expect(testResponse.clusterModeStatus).to(equal(clusterModeStatus));
            expect(testResponse.deviceStatus).to(equal(deviceStatus));
            expect(testResponse.driverBraking).to(equal(driverBraking));
            expect(testResponse.eCallInfo).to(equal(eCallInfo));
            expect(testResponse.electronicParkBrakeStatus).to(equal(electronicParkBrakeStatus));
            expect(testResponse.emergencyEvent).to(equal(emergencyEvent));
            expect(testResponse.engineOilLife).to(equal(@(engineOilLife)));
            expect(testResponse.engineTorque).to(equal(@(engineTorque)));
            expect(testResponse.externalTemperature).to(equal(@(externalTemperature)));
            expect(testResponse.fuelLevel).to(equal(@(fuelLevel)));
            expect(testResponse.fuelLevel_State).to(equal(fuelLevel_State));
            expect(testResponse.fuelRange).to(equal(fuelRangeArray));
            expect(testResponse.gps).to(equal(gps));
            expect(testResponse.headLampStatus).to(equal(headLampStatus));
            expect(testResponse.instantFuelConsumption).to(equal(@(instantFuelConsumption)));
            expect(testResponse.myKey).to(equal(myKey));
            expect(testResponse.odometer).to(equal(@(odometer)));
            expect(testResponse.prndl).to(equal(prndl));
            expect(testResponse.rpm).to(equal(@(rpm)));
            expect(testResponse.speed).to(equal(@(speed)));
            expect(testResponse.steeringWheelAngle).to(equal(@(steeringWheelAngle)));
            expect(testResponse.tirePressure).to(equal(tirePressure));
            expect(testResponse.turnSignal).to(equal(turnSignal));
            expect(testResponse.vin).to(equal(vin));
            expect(testResponse.wiperStatus).to(equal(wiperStatus));
        });
    });
    
    context(@"initWithDictionary:", ^{
        NSDictionary* dict = @{SDLRPCParameterNameNotification:
                                        @{SDLRPCParameterNameParameters:@{
                                            SDLRPCParameterNameAccelerationPedalPosition:@(accPedalPosition),
                                            SDLRPCParameterNameAirbagStatus:airbagStatus,
                                            SDLRPCParameterNameBeltStatus:beltStatus,
                                            SDLRPCParameterNameBodyInformation:bodyInformation,
                                            SDLRPCParameterNameCloudAppVehicleID:cloudAppVehicleID,
                                            SDLRPCParameterNameClusterModeStatus:clusterModeStatus,
                                            SDLRPCParameterNameDeviceStatus:deviceStatus,
                                            SDLRPCParameterNameDriverBraking:driverBraking,
                                            SDLRPCParameterNameECallInfo:eCallInfo,
                                            SDLRPCParameterNameElectronicParkBrakeStatus:electronicParkBrakeStatus,
                                            SDLRPCParameterNameEmergencyEvent:emergencyEvent,
                                            SDLRPCParameterNameEngineOilLife:@(engineOilLife),
                                            SDLRPCParameterNameEngineTorque:@(engineTorque),
                                            SDLRPCParameterNameExternalTemperature:@(externalTemperature),
                                            SDLRPCParameterNameFuelLevel:@(fuelLevel),
                                            SDLRPCParameterNameFuelLevelState:fuelLevel_State,
                                            SDLRPCParameterNameFuelRange:fuelRangeArray,
                                            SDLRPCParameterNameGPS:gps,
                                            SDLRPCParameterNameHeadLampStatus:headLampStatus,
                                            SDLRPCParameterNameInstantFuelConsumption:@(instantFuelConsumption),
                                            SDLRPCParameterNameMyKey:myKey,
                                            SDLRPCParameterNameOdometer:@(odometer),
                                            SDLRPCParameterNamePRNDL:prndl,
                                            SDLRPCParameterNameRPM:@(rpm),
                                            SDLRPCParameterNameSpeed:@(speed),
                                            SDLRPCParameterNameSteeringWheelAngle:@(steeringWheelAngle),
                                            SDLRPCParameterNameTirePressure:tirePressure,
                                            SDLRPCParameterNameTurnSignal:turnSignal,
                                            SDLRPCParameterNameVIN:vin,
                                            SDLRPCParameterNameWindowStatus:windowStatus,
                                            SDLRPCParameterNameWiperStatus:wiperStatus,
                                            },
                                        SDLRPCParameterNameOperationName:SDLRPCFunctionNameGetVehicleData}};
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        SDLGetVehicleDataResponse* testResponse = [[SDLGetVehicleDataResponse alloc] initWithDictionary:dict];
#pragma clang diagnostic pop

        it(@"expect all properties to be set properly", ^{
            expect(testResponse.accPedalPosition).to(equal(@(accPedalPosition)));
            expect(testResponse.airbagStatus).to(equal(airbagStatus));
            expect(testResponse.beltStatus).to(equal(beltStatus));
            expect(testResponse.bodyInformation).to(equal(bodyInformation));
            expect(testResponse.cloudAppVehicleID).to(equal(cloudAppVehicleID));
            expect(testResponse.clusterModeStatus).to(equal(clusterModeStatus));
            expect(testResponse.deviceStatus).to(equal(deviceStatus));
            expect(testResponse.driverBraking).to(equal(driverBraking));
            expect(testResponse.eCallInfo).to(equal(eCallInfo));
            expect(testResponse.electronicParkBrakeStatus).to(equal(electronicParkBrakeStatus));
            expect(testResponse.emergencyEvent).to(equal(emergencyEvent));
            expect(testResponse.engineOilLife).to(equal(@(engineOilLife)));
            expect(testResponse.engineTorque).to(equal(@(engineTorque)));
            expect(testResponse.externalTemperature).to(equal(@(externalTemperature)));
            expect(testResponse.fuelLevel).to(equal(@(fuelLevel)));
            expect(testResponse.fuelLevel_State).to(equal(fuelLevel_State));
            expect(testResponse.fuelRange).to(equal(fuelRangeArray));
            expect(testResponse.gps).to(equal(gps));
            expect(testResponse.headLampStatus).to(equal(headLampStatus));
            expect(testResponse.instantFuelConsumption).to(equal(@(instantFuelConsumption)));
            expect(testResponse.myKey).to(equal(myKey));
            expect(testResponse.odometer).to(equal(@(odometer)));
            expect(testResponse.prndl).to(equal(prndl));
            expect(testResponse.rpm).to(equal(@(rpm)));
            expect(testResponse.speed).to(equal(@(speed)));
            expect(testResponse.steeringWheelAngle).to(equal(@(steeringWheelAngle)));
            expect(testResponse.tirePressure).to(equal(tirePressure));
            expect(testResponse.turnSignal).to(equal(turnSignal));
            expect(testResponse.vin).to(equal(vin));
            expect(testResponse.windowStatus).to(equal(windowStatus));
            expect(testResponse.wiperStatus).to(equal(wiperStatus));
        });
    });
    
    context(@"init", ^{
        SDLGetVehicleDataResponse* testResponse = [[SDLGetVehicleDataResponse alloc] init];

        it(@"expect all properties to be set properly", ^{
            expect(testResponse.accPedalPosition).to(beNil());
            expect(testResponse.airbagStatus).to(beNil());
            expect(testResponse.beltStatus).to(beNil());
            expect(testResponse.bodyInformation).to(beNil());
            expect(testResponse.cloudAppVehicleID).to(beNil());
            expect(testResponse.clusterModeStatus).to(beNil());
            expect(testResponse.deviceStatus).to(beNil());
            expect(testResponse.driverBraking).to(beNil());
            expect(testResponse.eCallInfo).to(beNil());
            expect(testResponse.electronicParkBrakeStatus).to(beNil());
            expect(testResponse.emergencyEvent).to(beNil());
            expect(testResponse.engineOilLife).to(beNil());
            expect(testResponse.engineTorque).to(beNil());
            expect(testResponse.externalTemperature).to(beNil());
            expect(testResponse.fuelLevel).to(beNil());
            expect(testResponse.fuelLevel_State).to(beNil());
            expect(testResponse.fuelRange).to(beNil());
            expect(testResponse.gps).to(beNil());
            expect(testResponse.headLampStatus).to(beNil());
            expect(testResponse.instantFuelConsumption).to(beNil());
            expect(testResponse.myKey).to(beNil());
            expect(testResponse.odometer).to(beNil());
            expect(testResponse.prndl).to(beNil());
            expect(testResponse.rpm).to(beNil());
            expect(testResponse.speed).to(beNil());
            expect(testResponse.steeringWheelAngle).to(beNil());
            expect(testResponse.tirePressure).to(beNil());
            expect(testResponse.turnSignal).to(beNil());
            expect(testResponse.vin).to(beNil());
            expect(testResponse.windowStatus).to(beNil());
            expect(testResponse.wiperStatus).to(beNil());
        });
    });

    context(@"initWithGps:speed:rpm:fuelLevel:fuelLevel_State:instantFuelConsumption:fuelRange:externalTemperature:turnSignal:vin:prndl:tirePressure:odometer:beltStatus:bodyInformation:deviceStatus:driverBraking:wiperStatus:headLampStatus:engineTorque:accPedalPosition:steeringWheelAngle:engineOilLife:electronicParkBrakeStatus:cloudAppVehicleID:eCallInfo:airbagStatus:emergencyEvent:clusterModeStatus:myKey:windowStatus:", ^{
        SDLGetVehicleDataResponse *testResponse = [[SDLGetVehicleDataResponse alloc] initWithGps:gps speed:speed rpm:@(rpm) fuelLevel:fuelLevel fuelLevel_State:fuelLevel_State instantFuelConsumption:instantFuelConsumption fuelRange:fuelRangeArray externalTemperature:externalTemperature turnSignal:turnSignal vin:vin prndl:prndl tirePressure:tirePressure odometer:@(odometer) beltStatus:beltStatus bodyInformation:bodyInformation deviceStatus:deviceStatus driverBraking:driverBraking wiperStatus:wiperStatus headLampStatus:headLampStatus engineTorque:engineTorque accPedalPosition:accPedalPosition steeringWheelAngle:steeringWheelAngle engineOilLife:engineOilLife electronicParkBrakeStatus:electronicParkBrakeStatus cloudAppVehicleID:cloudAppVehicleID eCallInfo:eCallInfo airbagStatus:airbagStatus emergencyEvent:emergencyEvent clusterModeStatus:clusterModeStatus myKey:myKey windowStatus:windowStatus];

        it(@"expect all properties to be set properly", ^{
            expect(testResponse.accPedalPosition).to(equal(accPedalPosition));
            expect(testResponse.airbagStatus).to(equal(airbagStatus));
            expect(testResponse.beltStatus).to(equal(beltStatus));
            expect(testResponse.bodyInformation).to(equal(bodyInformation));
            expect(testResponse.cloudAppVehicleID).to(equal(cloudAppVehicleID));
            expect(testResponse.clusterModeStatus).to(equal(clusterModeStatus));
            expect(testResponse.deviceStatus).to(equal(deviceStatus));
            expect(testResponse.driverBraking).to(equal(driverBraking));
            expect(testResponse.eCallInfo).to(equal(eCallInfo));
            expect(testResponse.electronicParkBrakeStatus).to(equal(electronicParkBrakeStatus));
            expect(testResponse.emergencyEvent).to(equal(emergencyEvent));
            expect(testResponse.engineOilLife).to(equal(engineOilLife));
            expect(testResponse.engineTorque).to(equal(engineTorque));
            expect(testResponse.externalTemperature).to(equal(@(externalTemperature)));
            expect(testResponse.fuelLevel).to(equal(@(fuelLevel)));
            expect(testResponse.fuelLevel_State).to(equal(fuelLevel_State));
            expect(testResponse.fuelRange).to(equal(fuelRangeArray));
            expect(testResponse.gps).to(equal(gps));
            expect(testResponse.headLampStatus).to(equal(headLampStatus));
            expect(testResponse.instantFuelConsumption).to(equal(@(instantFuelConsumption)));
            expect(testResponse.myKey).to(equal(myKey));
            expect(testResponse.odometer).to(equal(@(odometer)));
            expect(testResponse.prndl).to(equal(prndl));
            expect(testResponse.rpm).to(equal(@(rpm)));
            expect(testResponse.speed).to(equal(@(speed)));
            expect(testResponse.steeringWheelAngle).to(equal(@(steeringWheelAngle)));
            expect(testResponse.tirePressure).to(equal(tirePressure));
            expect(testResponse.turnSignal).to(equal(turnSignal));
            expect(testResponse.vin).to(equal(vin));
            expect(testResponse.windowStatus).to(equal(windowStatus));
            expect(testResponse.wiperStatus).to(equal(wiperStatus));
        });
    });

    context(@"should set OEM Custom Vehicle Data", ^{
        SDLGetVehicleDataResponse *testRequest = [[SDLGetVehicleDataResponse alloc] init];
        [testRequest setOEMCustomVehicleData:@"customVehicleData" withVehicleDataState:@"oemVehicleData"];

        it(@"expect OEM Custom Vehicle Data to be set properly", ^{
            expect([testRequest getOEMCustomVehicleData:@"customVehicleData"]).to(equal(@"oemVehicleData"));
        });
    });
});

QuickSpecEnd
