//
//  MenuManager.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Nicole on 5/15/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "MenuManager.h"
#import "AlertManager.h"
#import "AudioManager.h"
#import "AppConstants.h"
#import "PerformInteractionManager.h"
#import "RPCPermissionsManager.h"
#import "SmartDeviceLink.h"
#import "VehicleDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MenuManager ()
@property (strong, nonatomic) AppConstants *appConst;
@property (strong, nonatomic) VehicleDataManager *vehicleDataManager;
@end


@implementation MenuManager 

- (instancetype)initWithAppConst:(AppConstants *)appConst
              vehicleDataManager:(VehicleDataManager *)vehicleDataManager {
    if ((self = [super init])) {
        _appConst = appConst;
        _vehicleDataManager = vehicleDataManager;
    }
    return self;
}


- (NSArray<SDLMenuCell *> *)allMenuItemsWithManager:(SDLManager *)manager
                                     performManager:(PerformInteractionManager *)performManager {
    return @[[self sdlex_menuCellSpeakNameWithManager:manager],
             [self sdlex_menuCellGetAllVehicleDataWithManager:manager],
             [self sdlex_menuCellShowPerformInteractionWithManager:manager performManager:performManager],
             [self sdlex_sliderMenuCellWithManager:manager],
             [self sdlex_scrollableMessageMenuCellWithManager:manager],
             [self sdlex_menuCellRecordInCarMicrophoneAudioWithManager:manager],
             [self sdlex_menuCellDialNumberWithManager:manager],
             [self sdlex_menuCellChangeTemplateWithManager:manager],
             [self sdlex_menuCellWithSubmenuWithManager:manager]];
}

- (NSArray<SDLVoiceCommand *> *)allVoiceMenuItemsWithManager:(SDLManager *)manager {
    if (!manager.systemCapabilityManager.vrCapability) {
        SDLLogE(@"The head unit does not support voice recognition");
        return @[];
    }

    return @[[self sdlex_voiceCommandStartWithManager:manager], [self sdlex_voiceCommandStopWithManager:manager]];
}

#pragma mark - Menu Items

- (SDLMenuCell *)sdlex_menuCellSpeakNameWithManager:(SDLManager *)manager {
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACSpeakAppNameMenuName icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.SpeakBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.appConst.ACSpeakAppNameMenuName] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        [manager sendRequest:[[SDLSpeak alloc] initWithTTS:self.appConst.ExampleAppNameTTS]];
    }];
}

- (SDLMenuCell *)sdlex_menuCellGetAllVehicleDataWithManager:(SDLManager *)manager {
    NSMutableArray *submenuItems = [[NSMutableArray alloc] init];
    NSArray<NSString *> *allVehicleDataTypes = [self sdlex_allVehicleDataTypes];
    for (NSString *vehicleDataType in allVehicleDataTypes) {
        SDLMenuCell *cell = [[SDLMenuCell alloc] initWithTitle:vehicleDataType icon:nil voiceCommands:nil handler:^(SDLTriggerSource  _Nonnull triggerSource) {
            [self.vehicleDataManager getAllVehicleDataWithManager:manager triggerSource:triggerSource vehicleDataType:vehicleDataType];
        }];
        [submenuItems addObject:cell];
    }

    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACGetAllVehicleDataMenuName icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.CarBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] submenuLayout:SDLMenuLayoutTiles subCells:submenuItems];
}

- (NSArray<NSString *> *)sdlex_allVehicleDataTypes {
    return @[self.appConst.ACAccelerationPedalPositionMenuName, self.appConst.ACAirbagStatusMenuName, self.appConst.ACBeltStatusMenuName, self.appConst.ACBodyInformationMenuName, self.appConst.ACClusterModeStatusMenuName, self.appConst.ACDeviceStatusMenuName, self.appConst.ACDriverBrakingMenuName, self.appConst.ACECallInfoMenuName, self.appConst.ACElectronicParkBrakeStatus, self.appConst.ACEmergencyEventMenuName, self.appConst.ACEngineOilLifeMenuName, self.appConst.ACEngineTorqueMenuName, self.appConst.ACExternalTemperatureMenuName, self.appConst.ACFuelLevelMenuName, self.appConst.ACFuelLevelStateMenuName, self.appConst.ACFuelRangeMenuName, self.appConst.ACGPSMenuName, self.appConst.ACHeadLampStatusMenuName, self.appConst.ACInstantFuelConsumptionMenuName, self.appConst.ACMyKeyMenuName, self.appConst.ACOdometerMenuName, self.appConst.ACPRNDLMenuName, self.appConst.ACRPMMenuName, self.appConst.ACSpeedMenuName, self.appConst.ACSteeringWheelAngleMenuName, self.appConst.ACTirePressureMenuName, self.appConst.ACTurnSignalMenuName, self.appConst.ACVINMenuName, self.appConst.ACWiperStatusMenuName];
}

- (SDLMenuCell *)sdlex_menuCellShowPerformInteractionWithManager:(SDLManager *)manager performManager:(PerformInteractionManager *)performManager {
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACShowChoiceSetMenuName icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.MenuBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.appConst.ACShowChoiceSetMenuName] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        [performManager showWithTriggerSource:triggerSource];
    }];
}

- (SDLMenuCell *)sdlex_menuCellRecordInCarMicrophoneAudioWithManager:(SDLManager *)manager {
    AudioManager *audioManager = [[AudioManager alloc] initWithManager:manager];
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACRecordInCarMicrophoneAudioMenuName icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.MicrophoneBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.appConst.ACRecordInCarMicrophoneAudioMenuName] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        [audioManager startRecording];
    }];
}

- (SDLMenuCell *)sdlex_menuCellDialNumberWithManager:(SDLManager *)manager {
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACDialPhoneNumberMenuName icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.PhoneBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:@[self.appConst.ACDialPhoneNumberMenuName] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        if (![RPCPermissionsManager isDialNumberRPCAllowedWithManager:manager]) {
            [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:@"This app does not have the required permissions to dial a number" textField2:nil iconName:nil]];
            return;
        }

        [self.vehicleDataManager checkPhoneCallCapabilityWithManager:manager phoneNumber:@"555-555-5555"];
    }];
}

- (SDLMenuCell *)sdlex_menuCellChangeTemplateWithManager:(SDLManager *)manager {
    
    /// Lets give an example of 2 templates
    NSMutableArray *submenuItems = [NSMutableArray array];
    NSString *errorMessage = @"Changing the template failed";
    
    // Non - Media
    SDLMenuCell *cell = [[SDLMenuCell alloc] initWithTitle:@"Non - Media (Default)" icon:nil voiceCommands:nil handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        SDLSetDisplayLayout* display = [[SDLSetDisplayLayout alloc] initWithPredefinedLayout:SDLPredefinedLayoutNonMedia];
        [manager sendRequest:display withResponseHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
            if (!response.success) {
                [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:errorMessage textField2:nil iconName:nil]];
            }
        }];
    }];
    [submenuItems addObject:cell];
    
    // Graphic With Text
    SDLMenuCell *cell2 = [[SDLMenuCell alloc] initWithTitle:@"Graphic With Text" icon:nil voiceCommands:nil handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        SDLSetDisplayLayout* display = [[SDLSetDisplayLayout alloc] initWithPredefinedLayout:SDLPredefinedLayoutGraphicWithText];
        [manager sendRequest:display withResponseHandler:^(SDLRPCRequest *request, SDLRPCResponse *response, NSError *error) {
            if (!response.success) {
                [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:errorMessage textField2:nil iconName:nil]];
            }
        }];
    }];
    [submenuItems addObject:cell2];
    
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACSubmenuTemplateMenuName icon:nil submenuLayout:SDLMenuLayoutList subCells:[submenuItems copy]];
}

- (SDLMenuCell *)sdlex_menuCellWithSubmenuWithManager:(SDLManager *)manager {
    NSMutableArray *submenuItems = [NSMutableArray array];
    for (int i = 0; i < 75; i++) {
        SDLMenuCell *cell = [[SDLMenuCell alloc] initWithTitle:[NSString stringWithFormat:@"%@ %i", self.appConst.ACSubmenuItemMenuName, i] icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.MenuBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] voiceCommands:nil handler:^(SDLTriggerSource  _Nonnull triggerSource) {
            [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:[NSString stringWithFormat:@"You selected %@ %i", self.appConst.ACSubmenuItemMenuName, i] textField2:nil iconName:nil]];
        }];
        [submenuItems addObject:cell];
    }

    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACSubmenuMenuName icon:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.MenuBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] asImageFormat:SDLArtworkImageFormatPNG] submenuLayout:SDLMenuLayoutList subCells:[submenuItems copy]];
}

- (SDLMenuCell *)sdlex_sliderMenuCellWithManager:(SDLManager *)manager {
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACSliderMenuName icon:nil voiceCommands:@[self.appConst.ACSliderMenuName] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        SDLSlider *sliderRPC = [[SDLSlider alloc] initWithNumTicks:3 position:1 sliderHeader:@"Select a letter" sliderFooters:@[@"A", @"B", @"C"] timeout:10000];
        [manager sendRequest:sliderRPC withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
            if(![response.resultCode isEqualToEnum:SDLResultSuccess]) {
                [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:@"Slider could not be displayed" textField2:nil iconName:nil]];
            }
        }];
    }];
}

- (SDLMenuCell *)sdlex_scrollableMessageMenuCellWithManager:(SDLManager *)manager {
    return [[SDLMenuCell alloc] initWithTitle:self.appConst.ACScrollableMessageMenuName icon:nil voiceCommands:@[self.appConst.ACScrollableMessageMenuName] handler:^(SDLTriggerSource  _Nonnull triggerSource) {
        SDLScrollableMessage *messageRPC = [[SDLScrollableMessage alloc] initWithMessage:@"This is a scrollable message\nIt can contain many lines"];
        [manager sendRequest:messageRPC withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
           if(![response.resultCode isEqualToEnum:SDLResultSuccess]) {
                [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:@"Scrollable Message could not be displayed" textField2:nil iconName:nil]];
            }
        }];
    }];
}

#pragma mark - Voice Commands

- (SDLVoiceCommand *)sdlex_voiceCommandStartWithManager:(SDLManager *)manager {
    return [[SDLVoiceCommand alloc] initWithVoiceCommands:@[self.appConst.VCStop] handler:^{
        [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:[NSString stringWithFormat:@"%@ voice command selected!", self.appConst.VCStop] textField2:nil iconName:nil]];
    }];
}

- (SDLVoiceCommand *)sdlex_voiceCommandStopWithManager:(SDLManager *)manager {
    return [[SDLVoiceCommand alloc] initWithVoiceCommands:@[self.appConst.VCStart] handler:^{
        [manager sendRequest:[AlertManager alertWithMessageAndCloseButton:[NSString stringWithFormat:@"%@ voice command selected!", self.appConst.VCStart] textField2:nil iconName:nil]];
    }];
}

@end

NS_ASSUME_NONNULL_END
