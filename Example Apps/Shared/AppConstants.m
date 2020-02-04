//
//  AppConstants.m
//  SmartDeviceLink
//
//  Created by Nicole on 4/10/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "AppConstants.h"

@implementation AppConstants

#pragma mark - SDL Configuration
- (NSString *)ExampleAppName {
    return @"SDL Example Alpha";
}

- (NSString *)ExampleAppNameShort {
    return @"SDL";
}

- (NSString *)ExampleAppNameTTS {
    return @"S D L Example App";
}

- (NSString *)ExampleFullAppId {
    return @"-e89b-12d3-a456-426655440000";
}

#pragma mark - SDL Textfields
- (NSString *)SmartDeviceLinkText {
    return @"SmartDeviceLink (SDL)";
}

- (NSString *)ExampleAppText {
    return @"Example App";
}


#pragma mark - SDL Soft Buttons
- (NSString *)ToggleSoftButton {
    return @"ToggleSoftButton";
}

- (NSString *)ToggleSoftButtonImageOnState {
    return @"ToggleSoftButtonImageOnState";
}

- (NSString *)ToggleSoftButtonImageOffState {
    return @"ToggleSoftButtonImageOffState";
}

- (NSString *)ToggleSoftButtonTextOnState {
    return @"ToggleSoftButtonTextOnState";
}

- (NSString *)ToggleSoftButtonTextOffState {
    return @"ToggleSoftButtonTextOffState";
}

- (NSString *)ToggleSoftButtonTextTextOnText {
    return @"➖";
}

- (NSString *)ToggleSoftButtonTextTextOffText {
    return @"➕";
}

- (NSString *)AlertSoftButton {
    return @"AlertSoftButton";
}

- (NSString *)AlertSoftButtonImageState {
    return @"AlertSoftButtonImageState";
}

- (NSString *)AlertSoftButtonTextState {
    return @"AlertSoftButtonTextState";
}

- (NSString *)AlertSoftButtonText {
    return @"Tap Me";
}

- (NSString *)TextVisibleSoftButton {
    return @"TextVisibleSoftButton";
}

- (NSString *)TextVisibleSoftButtonTextOnState {
    return @"TextVisibleSoftButtonTextOnState";
}

- (NSString *)TextVisibleSoftButtonTextOffState {
    return @"TextVisibleSoftButtonTextOffState";
}

- (NSString *)TextVisibleSoftButtonTextOnText {
    return @"➖Text";
}

- (NSString *)TextVisibleSoftButtonTextOffText {
    return @"➕Text";
}


- (NSString *)ImagesVisibleSoftButton {
    return @"ImagesVisibleSoftButton";
}

- (NSString *)ImagesVisibleSoftButtonImageOnState {
    return @"ImagesVisibleSoftButtonImageOnState";
}

- (NSString *)ImagesVisibleSoftButtonImageOffState {
    return @"ImagesVisibleSoftButtonImageOffState";
}

- (NSString *)ImagesVisibleSoftButtonImageOnText {
    return @"➖Icons";
}

- (NSString *)ImagesVisibleSoftButtonImageOffText {
    return @"➕Icons";
}


#pragma mark - Alert
NSString * const AlertOKButtonText = @"OK";

#pragma mark - SDL Text-To-Speech
- (NSString *)TTSGoodJob {
    return @"Good Job";
}

- (NSString *)TTSYouMissed {
    return @"You Missed";
}


#pragma mark - SDL Voice Commands
- (NSString *)VCStart {
    return @"Start";
}

- (NSString *)VCStop {
    return @"Stop";
}


#pragma mark - SDL Perform Interaction Choice Set Menu
- (NSString *)PICSInitialText {
    return @"Perform Interaction Choice Set Menu Example";
}

- (NSString *)PICSInitialPrompt {
    return @"Select an item from the menu";
}

- (NSString *)PICSHelpPrompt {
    return @"Select a menu row using your voice or by tapping on the screen";
}

- (NSString *)PICSTimeoutPrompt {
    return @"Closing the menu";
}

- (NSString *)PICSFirstChoice {
    return @"First Choice";
}

- (NSString *)PICSSecondChoice {
    return @"Second Choice";
}

- (NSString *)PICSThirdChoice {
    return @"Third Choice";
}


#pragma mark - SDL Perform Interaction Choice Set Menu VR Commands

NSString * const VCPICSFirstChoice = @"First";
NSString * const VCPICSecondChoice = @"Second";
NSString * const VCPICSThirdChoice = @"Dritte";

#pragma mark - SDL Add Command Menu
- (NSString *)ACSpeakAppNameMenuName {
    return @"Speak App Name";
}

- (NSString *)ACShowChoiceSetMenuName {
    return @"Show Perform Interaction Choice Set";
}

- (NSString *)ACGetVehicleDataMenuName {
    return @"Get Vehicle Speed";
}

- (NSString *)ACGetAllVehicleDataMenuName {
    return @"Get All Vehicle Data";
}

- (NSString *)ACRecordInCarMicrophoneAudioMenuName {
    return @"Record In-Car Microphone Audio";
}

- (NSString *)ACDialPhoneNumberMenuName {
    return @"Dial Phone Number";
}

- (NSString *)ACSubmenuMenuName {
    return @"Submenu";
}

- (NSString *)ACSubmenuItemMenuName {
    return @"Item";
}

- (NSString *)ACSubmenuTemplateMenuName {
    return @"Change Template";
}

- (NSString *)ACSliderMenuName {
    return @"Show Slider";
}

- (NSString *)ACScrollableMessageMenuName {
    return @"Show Scrollable Message";
}


- (NSString *)ACAccelerationPedalPositionMenuName {
    return @"Acceleration Pedal Position";
}

- (NSString *)ACAirbagStatusMenuName {
    return @"Airbag Status";
}

- (NSString *)ACBeltStatusMenuName {
    return @"Belt Status";
}

- (NSString *)ACBodyInformationMenuName {
    return @"Body Information";
}

- (NSString *)ACClusterModeStatusMenuName {
    return @"Cluster Mode Status";
}

- (NSString *)ACDeviceStatusMenuName {
    return @"Device Status";
}

- (NSString *)ACDriverBrakingMenuName {
    return @"Driver Braking";
}

- (NSString *)ACECallInfoMenuName {
    return @"eCall Info";
}

- (NSString *)ACElectronicParkBrakeStatus {
    return @"Electronic Parking Brake Status";
}

- (NSString *)ACEmergencyEventMenuName {
    return @"Emergency Event";
}

- (NSString *)ACEngineOilLifeMenuName {
    return @"Engine Oil Life";
}

- (NSString *)ACEngineTorqueMenuName {
    return @"Engine Torque";
}

- (NSString *)ACExternalTemperatureMenuName {
    return @"External Temperature";
}

- (NSString *)ACFuelLevelMenuName {
    return @"Fuel Level";
}

- (NSString *)ACFuelLevelStateMenuName {
    return @"Fuel Level State";
}

- (NSString *)ACFuelRangeMenuName {
    return @"Fuel Range";
}

- (NSString *)ACGPSMenuName {
    return @"GPS";
}

- (NSString *)ACHeadLampStatusMenuName {
    return @"Head Lamp Status";
}

- (NSString *)ACInstantFuelConsumptionMenuName {
    return @"Instant Fuel Consumption";
}

- (NSString *)ACMyKeyMenuName {
    return @"MyKey";
}

- (NSString *)ACOdometerMenuName {
    return @"Odometer";
}

- (NSString *)ACPRNDLMenuName {
    return @"PRNDL";
}

- (NSString *)ACRPMMenuName {
    return @"RPM";
}

- (NSString *)ACSpeedMenuName {
    return @"Speed";
}

- (NSString *)ACSteeringWheelAngleMenuName {
    return @"Steering Wheel Angle";
}

- (NSString *)ACTirePressureMenuName {
    return @"Tire Pressure";
}

- (NSString *)ACTurnSignalMenuName {
    return @"Turn Signal";
}

- (NSString *)ACVINMenuName {
    return @"VIN";
}

- (NSString *)ACWiperStatusMenuName {
    return @"Wiper Status";
}


#pragma mark - SDL Image Names
- (NSString *)AlertBWIconName {
    return @"alert";
}

- (NSString *)CarBWIconImageName {
    return @"car";
}

- (NSString *)ExampleAppLogoName {
    return @"sdl_logo_green";
}

- (NSString *)MenuBWIconImageName {
    return @"choice_set";
}

- (NSString *)MicrophoneBWIconImageName {
    return @"microphone";
}

- (NSString *)PhoneBWIconImageName {
    return @"phone";
}

- (NSString *)SpeakBWIconImageName {
    return @"speak";
}

- (NSString *)ToggleOffBWIconName {
    return @"toggle_off";
}

- (NSString *)ToggleOnBWIconName {
    return @"toggle_on";
}


#pragma mark - SDL App Name in Different Languages
- (NSString *)ExampleAppNameSpanish {
    return @"SDL Aplicación de ejemplo (sp)";
}

- (NSString *)ExampleAppNameFrench {
    return @"SDL Exemple App (fr)";
}


#pragma mark - SDL Vehicle Data
- (NSString *)VehicleDataOdometerName {
    return @"Odometer";
}

- (NSString *)VehicleDataSpeedName {
    return @"Speed";
}

@end
