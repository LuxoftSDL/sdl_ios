//
//  SDLPreloadChoicesOperation.m
//  SmartDeviceLink
//
//  Created by Joel Fischer on 5/23/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import "SDLPreloadChoicesOperation.h"

#import "SDLChoice.h"
#import "SDLChoiceCell.h"
#import "SDLConnectionManagerType.h"
#import "SDLCreateInteractionChoiceSet.h"
#import "SDLCreateInteractionChoiceSetResponse.h"
#import "SDLDisplayCapabilities.h"
#import "SDLDisplayCapabilities+ShowManagerExtensions.h"
#import "SDLError.h"
#import "SDLFileManager.h"
#import "SDLImage.h"
#import "SDLLogMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLChoiceCell()

@property (assign, nonatomic) UInt16 choiceId;

@end

@interface SDLPreloadChoicesOperation()

@property (strong, nonatomic) NSSet<SDLChoiceCell *> *cellsToUpload;
@property (strong, nonatomic) SDLDisplayCapabilities *displayCapabilities;
@property (assign, nonatomic, getter=isVROptional) BOOL vrOptional;

@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLFileManager *fileManager;
@property (copy, nonatomic, nullable) NSError *internalError;

@end

@implementation SDLPreloadChoicesOperation

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager fileManager:(SDLFileManager *)fileManager displayCapabilities:(SDLDisplayCapabilities *)displayCapabilities isVROptional:(BOOL)isVROptional cellsToPreload:(NSSet<SDLChoiceCell *> *)cells {
    self = [super init];
    if (!self) { return nil; }

    _connectionManager = connectionManager;
    _fileManager = fileManager;
    _displayCapabilities = displayCapabilities;
    _vrOptional = isVROptional;
    _cellsToUpload = cells;

    return self;
}

- (void)start {
    [super start];

    [self sdl_preloadCellArtworksWithCompletionHandler:^(NSError * _Nullable error) {
        [self sdl_preloadCells];
    }];
}

#pragma mark - Sending Choice Data

- (void)sdl_preloadCellArtworksWithCompletionHandler:(void(^)(NSError *_Nullable))completionHandler {
    NSMutableArray<SDLArtwork *> *artworksToUpload = [NSMutableArray arrayWithCapacity:self.cellsToUpload.count];
    for (SDLChoiceCell *cell in self.cellsToUpload) {
        if ([self.displayCapabilities hasImageFieldOfName:SDLImageFieldNameChoiceImage]) {
            cell.artwork != nil ? [artworksToUpload addObject:cell.artwork] : nil;
        }
        if ([self.displayCapabilities hasImageFieldOfName:SDLImageFieldNameChoiceSecondaryImage]) {
            cell.secondaryArtwork != nil ? [artworksToUpload addObject:cell.secondaryArtwork] : nil;
        }
    }

    if (artworksToUpload.count == 0) {
        SDLLogV(@"No choice artworks to be uploaded");
        completionHandler(nil);
        return;
    }

    [self.fileManager uploadArtworks:[artworksToUpload copy] completionHandler:^(NSArray<NSString *> * _Nonnull artworkNames, NSError * _Nullable error) {
        if (error != nil) {
            SDLLogE(@"Error uploading choice artworks: %@", error);
        } else {
            SDLLogD(@"Finished uploading choice artworks");
            SDLLogV(@"%@", artworkNames);
        }

        completionHandler(error);
    }];
}

- (void)sdl_preloadCells {
    NSMutableArray<SDLCreateInteractionChoiceSet *> *choiceRPCs = [NSMutableArray arrayWithCapacity:self.cellsToUpload.count];
    for (SDLChoiceCell *cell in self.cellsToUpload) {
        [choiceRPCs addObject:[self sdl_choiceFromCell:cell]];
    }

    __weak typeof(self) weakSelf = self;
    __block NSMutableDictionary<SDLRPCRequest *, NSError *> *errors = [NSMutableDictionary dictionary];
    [self.connectionManager sendRequests:[choiceRPCs copy] progressHandler:^(__kindof SDLRPCRequest * _Nonnull request, __kindof SDLRPCResponse * _Nullable response, NSError * _Nullable error, float percentComplete) {
        if (error != nil) {
            errors[request] = error;
        }
    } completionHandler:^(BOOL success) {
        if (!success) {
            SDLLogW(@"Error preloading choice cells: %@", errors);
            weakSelf.internalError = [NSError sdl_choiceSetManager_choiceUploadFailed:errors];
        }

        SDLLogD(@"Finished preloading choice cells");

        [weakSelf finishOperation];
    }];
}

#pragma mark - Assembling Choice Data

- (SDLCreateInteractionChoiceSet *)sdl_choiceFromCell:(SDLChoiceCell *)cell {
    NSArray<NSString *> *vrCommands = nil;
    if (cell.voiceCommands == nil) {
        vrCommands = self.isVROptional ? nil : @[[NSString stringWithFormat:@"%hu", cell.choiceId]];
    } else {
        vrCommands = cell.voiceCommands;
    }

    NSString *menuName = [self.displayCapabilities hasTextFieldOfName:SDLTextFieldNameMenuName] ? cell.text : nil;
    NSString *secondaryText = [self.displayCapabilities hasTextFieldOfName:SDLTextFieldNameSecondaryText] ? cell.secondaryText : nil;
    NSString *tertiaryText = [self.displayCapabilities hasTextFieldOfName:SDLTextFieldNameTertiaryText] ? cell.tertiaryText : nil;

    SDLImage *image = ([self.displayCapabilities hasImageFieldOfName:SDLImageFieldNameChoiceImage] && cell.artwork != nil) ? [[SDLImage alloc] initWithName:cell.artwork.name] : nil;
    SDLImage *secondaryImage = ([self.displayCapabilities hasImageFieldOfName:SDLImageFieldNameChoiceSecondaryImage] && cell.secondaryArtwork != nil) ? [[SDLImage alloc] initWithName:cell.secondaryArtwork.name] : nil;

    SDLChoice *choice = [[SDLChoice alloc] initWithId:cell.choiceId menuName:(NSString *_Nonnull)menuName vrCommands:(NSArray<NSString *> * _Nonnull)vrCommands image:image secondaryText:secondaryText secondaryImage:secondaryImage tertiaryText:tertiaryText];

    return [[SDLCreateInteractionChoiceSet alloc] initWithId:(UInt32)choice.choiceID choiceSet:@[choice]];
}

#pragma mark - Property Overrides

- (nullable NSString *)name {
    return @"com.sdl.choicesetmanager.preloadChoices";
}

- (NSOperationQueuePriority)queuePriority {
    return NSOperationQueuePriorityNormal;
}

- (nullable NSError *)error {
    return self.internalError;
}

@end

NS_ASSUME_NONNULL_END
