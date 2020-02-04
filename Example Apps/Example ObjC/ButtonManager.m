//
//  ButtonManager.m
//  SmartDeviceLink
//
//  Created by Nicole on 5/11/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "ButtonManager.h"
#import "AlertManager.h"
#import "AppConstants.h"
#import "SmartDeviceLink.h"

NS_ASSUME_NONNULL_BEGIN

@interface ButtonManager ()

@property (copy, nonatomic, nullable) RefreshUIHandler refreshUIHandler;
@property (strong, nonatomic) SDLManager *sdlManager;

@property (assign, nonatomic, getter=isTextEnabled, readwrite) BOOL textEnabled;
@property (assign, nonatomic, getter=isHexagonEnabled, readwrite) BOOL toggleEnabled;
@property (assign, nonatomic, getter=areImagesEnabled, readwrite) BOOL imagesEnabled;
@property (strong, nonatomic) AppConstants *appConst;

@end

@implementation ButtonManager

- (instancetype)initWithManager:(SDLManager *)manager
                       appConst:(AppConstants *)appConst
               refreshUIHandler:(RefreshUIHandler)refreshUIHandler {
    self = [super init];
    if (!self) {
        return nil;
    }

    _sdlManager = manager;
    _appConst = appConst;
    _refreshUIHandler = refreshUIHandler;

    _textEnabled = YES;
    _imagesEnabled = YES;
    _toggleEnabled = YES;

    return self;
}

#pragma mark - Setters

- (void)setTextEnabled:(BOOL)textEnabled {
    _textEnabled = textEnabled;
    if (self.refreshUIHandler == nil) { return; }
    self.refreshUIHandler();
}

- (void)setImagesEnabled:(BOOL)imagesEnabled {
    _imagesEnabled = imagesEnabled;

    SDLSoftButtonObject *object = [self.sdlManager.screenManager softButtonObjectNamed:self.appConst.AlertSoftButton];
    [object transitionToNextState];

    if (self.refreshUIHandler == nil) { return; }
    self.refreshUIHandler();
}

- (void)setToggleEnabled:(BOOL)toggleEnabled {
    _toggleEnabled = toggleEnabled;
    SDLSoftButtonObject *object = [self.sdlManager.screenManager softButtonObjectNamed:self.appConst.ToggleSoftButton];
    [object transitionToStateNamed:(toggleEnabled ? self.appConst.ToggleSoftButtonImageOnState : self.appConst.ToggleSoftButtonImageOffState)];
}

#pragma mark - Custom Soft Buttons

- (NSArray<SDLSoftButtonObject *> *)allScreenSoftButtons {
    return @[[self sdlex_softButtonAlertWithManager:self.sdlManager], [self sdlex_softButtonToggleWithManager:self.sdlManager], [self sdlex_softButtonTextVisibleWithManager:self.sdlManager], [self sdlex_softButtonImagesVisibleWithManager:self.sdlManager]];
}

- (SDLSoftButtonObject *)sdlex_softButtonAlertWithManager:(SDLManager *)manager {
    SDLSoftButtonState *alertImageAndTextState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.AlertSoftButtonImageState text:self.appConst.AlertSoftButtonText artwork:[SDLArtwork artworkWithImage:[[UIImage imageNamed:self.appConst.CarBWIconImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] name:self.appConst.CarBWIconImageName asImageFormat:SDLArtworkImageFormatPNG]];
    SDLSoftButtonState *alertTextState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.AlertSoftButtonTextState text:self.appConst.AlertSoftButtonText image:nil];

    __weak typeof(self) weakself = self;
    SDLSoftButtonObject *alertSoftButton = [[SDLSoftButtonObject alloc] initWithName:self.appConst.AlertSoftButton states:@[alertImageAndTextState, alertTextState] initialStateName:alertImageAndTextState.name handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (buttonPress == nil) { return; }

        [weakself.sdlManager.fileManager uploadArtwork:[SDLArtwork artworkWithImage:[UIImage imageNamed:self.appConst.CarBWIconImageName] asImageFormat:SDLArtworkImageFormatPNG] completionHandler:^(BOOL success, NSString * _Nonnull artworkName, NSUInteger bytesAvailable, NSError * _Nullable error) {
            [weakself.sdlManager sendRequest:[AlertManager alertWithMessageAndCloseButton:@"You pushed the soft button!" textField2:nil iconName:artworkName] withResponseHandler:^(__kindof SDLRPCRequest * _Nullable request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error) {
                NSLog(@"ALERT req: %@, res: %@, err: %@", request, response, error);
            }];
        }];

        SDLLogD(@"Star icon soft button press fired");
    }];

    return alertSoftButton;
}

- (SDLSoftButtonObject *)sdlex_softButtonToggleWithManager:(SDLManager *)manager {
    SDLSoftButtonState *toggleImageOnState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.ToggleSoftButtonImageOnState text:nil image:[[UIImage imageNamed:self.appConst.ToggleOnBWIconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    SDLSoftButtonState *toggleImageOffState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.ToggleSoftButtonImageOffState text:nil image:[[UIImage imageNamed:self.appConst.ToggleOffBWIconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

    __weak typeof(self) weakself = self;
    SDLSoftButtonObject *toggleButton = [[SDLSoftButtonObject alloc] initWithName:self.appConst.ToggleSoftButton states:@[toggleImageOnState, toggleImageOffState] initialStateName:toggleImageOnState.name handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (buttonPress == nil) { return; }
        weakself.toggleEnabled = !weakself.toggleEnabled;
        SDLLogD(@"Toggle icon button press fired %d", self.toggleEnabled);
    }];

    return toggleButton;
}

- (SDLSoftButtonObject *)sdlex_softButtonTextVisibleWithManager:(SDLManager *)manager {
    SDLSoftButtonState *textOnState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.TextVisibleSoftButtonTextOnState text:self.appConst.TextVisibleSoftButtonTextOnText image:nil];
    SDLSoftButtonState *textOffState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.TextVisibleSoftButtonTextOffState text:self.appConst.TextVisibleSoftButtonTextOffText image:nil];

    __weak typeof(self) weakself = self;
    SDLSoftButtonObject *textButton = [[SDLSoftButtonObject alloc] initWithName:self.appConst.TextVisibleSoftButton states:@[textOnState, textOffState] initialStateName:textOnState.name handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (buttonPress == nil) { return; }

        weakself.textEnabled = !weakself.textEnabled;
        SDLSoftButtonObject *object = [weakself.sdlManager.screenManager softButtonObjectNamed:self.appConst.TextVisibleSoftButton];
        [object transitionToNextState];

        SDLLogD(@"Text visibility soft button press fired %d", weakself.textEnabled);
    }];

    return textButton;
}

- (SDLSoftButtonObject *)sdlex_softButtonImagesVisibleWithManager:(SDLManager *)manager {
    SDLSoftButtonState *imagesOnState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.ImagesVisibleSoftButtonImageOnState text:self.appConst.ImagesVisibleSoftButtonImageOnText image:nil];
    SDLSoftButtonState *imagesOffState = [[SDLSoftButtonState alloc] initWithStateName:self.appConst.ImagesVisibleSoftButtonImageOffState text:self.appConst.ImagesVisibleSoftButtonImageOffText image:nil];

    __weak typeof(self) weakself = self;
    SDLSoftButtonObject *imagesButton = [[SDLSoftButtonObject alloc] initWithName:self.appConst.ImagesVisibleSoftButton states:@[imagesOnState, imagesOffState] initialStateName:imagesOnState.name handler:^(SDLOnButtonPress * _Nullable buttonPress, SDLOnButtonEvent * _Nullable buttonEvent) {
        if (buttonPress == nil) {
            return;
        }

        weakself.imagesEnabled = !weakself.imagesEnabled;

        SDLSoftButtonObject *object = [weakself.sdlManager.screenManager softButtonObjectNamed:self.appConst.ImagesVisibleSoftButton];
        [object transitionToNextState];

        SDLSoftButtonObject *textButton = [weakself.sdlManager.screenManager softButtonObjectNamed:self.appConst.TextVisibleSoftButton];
        [textButton transitionToNextState];

        SDLLogD(@"Image visibility soft button press fired %d", weakself.imagesEnabled);
    }];

    return imagesButton;
}

@end

NS_ASSUME_NONNULL_END
