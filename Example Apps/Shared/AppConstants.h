//
//  AppConstants.h
//  SmartDeviceLink
//
//  Created by Nicole on 4/10/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern BOOL const ExampleAppShouldRestartSDLManagerOnDisconnect;

@interface AppConstants : NSObject

#pragma mark - SDL Configuration
@property (nonatomic, readonly) NSString * ExampleAppName;
@property (nonatomic, readonly) NSString * ExampleAppNameShort;
@property (nonatomic, readonly) NSString * ExampleAppNameTTS;
@property (nonatomic, readonly) NSString * ExampleFullAppId;

#pragma mark - SDL Textfields
@property (nonatomic, readonly) NSString * SmartDeviceLinkText;
@property (nonatomic, readonly) NSString * ExampleAppText;

#pragma mark - SDL Soft Buttons
@property (nonatomic, readonly) NSString * ToggleSoftButton;
@property (nonatomic, readonly) NSString * ToggleSoftButtonImageOnState;
@property (nonatomic, readonly) NSString * ToggleSoftButtonImageOffState;
@property (nonatomic, readonly) NSString * ToggleSoftButtonTextOnState;
@property (nonatomic, readonly) NSString * ToggleSoftButtonTextOffState;
@property (nonatomic, readonly) NSString * ToggleSoftButtonTextTextOnText;
@property (nonatomic, readonly) NSString * ToggleSoftButtonTextTextOffText;

@property (nonatomic, readonly) NSString * AlertSoftButton;
@property (nonatomic, readonly) NSString * AlertSoftButtonImageState;
@property (nonatomic, readonly) NSString * AlertSoftButtonTextState;
@property (nonatomic, readonly) NSString * AlertSoftButtonText;

@property (nonatomic, readonly) NSString * TextVisibleSoftButton;
@property (nonatomic, readonly) NSString * TextVisibleSoftButtonTextOnState;
@property (nonatomic, readonly) NSString * TextVisibleSoftButtonTextOffState;
@property (nonatomic, readonly) NSString * TextVisibleSoftButtonTextOnText;
@property (nonatomic, readonly) NSString * TextVisibleSoftButtonTextOffText;

@property (nonatomic, readonly) NSString * ImagesVisibleSoftButton;
@property (nonatomic, readonly) NSString * ImagesVisibleSoftButtonImageOnState;
@property (nonatomic, readonly) NSString * ImagesVisibleSoftButtonImageOffState;
@property (nonatomic, readonly) NSString * ImagesVisibleSoftButtonImageOnText;
@property (nonatomic, readonly) NSString * ImagesVisibleSoftButtonImageOffText;

#pragma mark - Alert
extern NSString * const AlertOKButtonText;

#pragma mark - SDL Text-To-Speech
@property (nonatomic, readonly) NSString * TTSGoodJob;
@property (nonatomic, readonly) NSString * TTSYouMissed;

#pragma mark - SDL Voice Commands
@property (nonatomic, readonly) NSString * VCStart;
@property (nonatomic, readonly) NSString * VCStop;

#pragma mark - SDL Perform Interaction Choice Set Menu
@property (nonatomic, readonly) NSString * PICSInitialText;
@property (nonatomic, readonly) NSString * PICSInitialPrompt;
@property (nonatomic, readonly) NSString * PICSHelpPrompt;
@property (nonatomic, readonly) NSString * PICSTimeoutPrompt;
@property (nonatomic, readonly) NSString * PICSFirstChoice;
@property (nonatomic, readonly) NSString * PICSSecondChoice;
@property (nonatomic, readonly) NSString * PICSThirdChoice;

#pragma mark - SDL Perform Interaction Choice Set Menu VR Commands
extern NSString  * const VCPICSFirstChoice;
extern NSString  * const VCPICSecondChoice;
extern NSString  * const VCPICSThirdChoice;

#pragma mark - SDL Add Command Menu
@property (nonatomic, readonly) NSString * ACSpeakAppNameMenuName;
@property (nonatomic, readonly) NSString * ACShowChoiceSetMenuName;
@property (nonatomic, readonly) NSString * ACGetVehicleDataMenuName;
@property (nonatomic, readonly) NSString * ACGetAllVehicleDataMenuName;
@property (nonatomic, readonly) NSString * ACRecordInCarMicrophoneAudioMenuName;
@property (nonatomic, readonly) NSString * ACDialPhoneNumberMenuName;
@property (nonatomic, readonly) NSString * ACSubmenuMenuName;
@property (nonatomic, readonly) NSString * ACSubmenuItemMenuName;
@property (nonatomic, readonly) NSString * ACSubmenuTemplateMenuName;
@property (nonatomic, readonly) NSString * ACSliderMenuName;
@property (nonatomic, readonly) NSString * ACScrollableMessageMenuName;

@property (nonatomic, readonly) NSString * ACAccelerationPedalPositionMenuName;
@property (nonatomic, readonly) NSString * ACAirbagStatusMenuName;
@property (nonatomic, readonly) NSString * ACBeltStatusMenuName;
@property (nonatomic, readonly) NSString * ACBodyInformationMenuName;
@property (nonatomic, readonly) NSString * ACClusterModeStatusMenuName;
@property (nonatomic, readonly) NSString * ACDeviceStatusMenuName;
@property (nonatomic, readonly) NSString * ACDriverBrakingMenuName;
@property (nonatomic, readonly) NSString * ACECallInfoMenuName;
@property (nonatomic, readonly) NSString * ACElectronicParkBrakeStatus;
@property (nonatomic, readonly) NSString * ACEmergencyEventMenuName;
@property (nonatomic, readonly) NSString * ACEngineOilLifeMenuName;
@property (nonatomic, readonly) NSString * ACEngineTorqueMenuName;
@property (nonatomic, readonly) NSString * ACExternalTemperatureMenuName;
@property (nonatomic, readonly) NSString * ACFuelLevelMenuName;
@property (nonatomic, readonly) NSString * ACFuelLevelStateMenuName;
@property (nonatomic, readonly) NSString * ACFuelRangeMenuName;
@property (nonatomic, readonly) NSString * ACGPSMenuName;
@property (nonatomic, readonly) NSString * ACHeadLampStatusMenuName;
@property (nonatomic, readonly) NSString * ACInstantFuelConsumptionMenuName;
@property (nonatomic, readonly) NSString * ACMyKeyMenuName;
@property (nonatomic, readonly) NSString * ACOdometerMenuName;
@property (nonatomic, readonly) NSString * ACPRNDLMenuName;
@property (nonatomic, readonly) NSString * ACRPMMenuName;
@property (nonatomic, readonly) NSString * ACSpeedMenuName;
@property (nonatomic, readonly) NSString * ACSteeringWheelAngleMenuName;
@property (nonatomic, readonly) NSString * ACTirePressureMenuName;
@property (nonatomic, readonly) NSString * ACTurnSignalMenuName;
@property (nonatomic, readonly) NSString * ACVINMenuName;
@property (nonatomic, readonly) NSString * ACWiperStatusMenuName;

#pragma mark - SDL Image Names
@property (nonatomic, readonly) NSString * AlertBWIconName;
@property (nonatomic, readonly) NSString * CarBWIconImageName;
@property (nonatomic, readonly) NSString * ExampleAppLogoName;
@property (nonatomic, readonly) NSString * MenuBWIconImageName;
@property (nonatomic, readonly) NSString * MicrophoneBWIconImageName;
@property (nonatomic, readonly) NSString * PhoneBWIconImageName;
@property (nonatomic, readonly) NSString * SpeakBWIconImageName;
@property (nonatomic, readonly) NSString * ToggleOffBWIconName;
@property (nonatomic, readonly) NSString * ToggleOnBWIconName;

#pragma mark - SDL App Name in Different Languages
@property (nonatomic, readonly) NSString * ExampleAppNameSpanish;
@property (nonatomic, readonly) NSString * ExampleAppNameFrench;

#pragma mark - SDL Vehicle Data
@property (nonatomic, readonly) NSString * VehicleDataOdometerName;
@property (nonatomic, readonly) NSString * VehicleDataSpeedName;

@end

NS_ASSUME_NONNULL_END
