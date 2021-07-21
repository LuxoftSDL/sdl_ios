#import <Quick/Quick.h>
#import <Nimble/Nimble.h>
#import <OCMock/OCMock.h>

#import "SDLPreloadPresentChoicesOperation.h"

#import "SDLChoice.h"
#import "SDLChoiceCell.h"
#import "SDLCreateInteractionChoiceSet.h"
#import "SDLDisplayType.h"
#import "SDLFileManager.h"
#import "SDLGlobals.h"
#import "SDLImageField.h"
#import "SDLImageFieldName.h"
#import "SDLTextField.h"
#import "SDLTextFieldName.h"
#import "SDLWindowCapability.h"
#import "TestConnectionManager.h"

@interface SDLPreloadPresentChoicesOperation()

// Dependencies
@property (weak, nonatomic) id<SDLConnectionManagerType> connectionManager;
@property (weak, nonatomic) SDLFileManager *fileManager;
@property (strong, nonatomic) SDLWindowCapability *windowCapability;

// Preload Dependencies
@property (strong, nonatomic) NSMutableOrderedSet<SDLChoiceCell *> *cellsToUpload;
@property (strong, nonatomic) NSString *displayName;
@property (assign, nonatomic, readwrite, getter=isVROptional) BOOL vrOptional;
@property (copy, nonatomic) SDLUploadChoicesCompletionHandler preloadCompletionHandler;

// Present Dependencies
@property (strong, nonatomic) SDLChoiceSet *choiceSet;
@property (strong, nonatomic, nullable) SDLInteractionMode presentationMode;
@property (strong, nonatomic, nullable) SDLKeyboardProperties *originalKeyboardProperties;
@property (strong, nonatomic, nullable) SDLKeyboardProperties *customKeyboardProperties;
@property (weak, nonatomic, nullable) id<SDLKeyboardDelegate> keyboardDelegate;
@property (assign, nonatomic) UInt16 cancelId;

// Internal operation properties
@property (strong, nonatomic) NSUUID *operationId;
@property (copy, nonatomic, nullable) NSError *internalError;

// Mutable state
@property (strong, nonatomic) NSMutableSet<SDLChoiceCell *> *mutableLoadedCells;

// Present completion handler properties
@property (strong, nonatomic, nullable) SDLChoiceCell *selectedCell;
@property (strong, nonatomic, nullable) SDLTriggerSource selectedTriggerSource;
@property (assign, nonatomic) NSUInteger selectedCellRow;
@property (copy, nonatomic, nullable) SDLPresentChoiceSetCompletionHandler presentCompletionHandler;

@end

@interface SDLChoiceCell()

@property (assign, nonatomic) UInt16 choiceId;

@end

QuickSpecBegin(SDLPreloadPresentChoicesOperationSpec)

describe(@"a preload choices operation", ^{
    __block TestConnectionManager *testConnectionManager = nil;
    __block SDLFileManager *testFileManager = nil;
    __block SDLPreloadPresentChoicesOperation *testOp = nil;
    __block NSString *testDisplayName = @"SDL_GENERIC";
    __block SDLVersion *choiceSetUniquenessActiveVersion = [[SDLVersion alloc] initWithMajor:7 minor:1 patch:0];
    __block SDLVersion *choiceSetUniquenessInactiveVersion = [[SDLVersion alloc] initWithMajor:7 minor:0 patch:0];

    __block SDLWindowCapability *enabledWindowCapability = nil;
    __block SDLWindowCapability *disabledWindowCapability = nil;
    __block SDLWindowCapability *primaryTextOnlyCapability = nil;

    __block NSSet<SDLChoiceCell *> *emptyLoadedCells = [NSSet set];
    __block NSData *cellArtData = [@"testart" dataUsingEncoding:NSUTF8StringEncoding];
    __block NSData *cellArtData2 = [@"testart2" dataUsingEncoding:NSUTF8StringEncoding];
    __block NSMutableOrderedSet<SDLChoiceCell *> *cellsWithArtwork = nil;
    __block NSMutableOrderedSet<SDLChoiceCell *> *cellsWithStaticIcon = nil;
    __block NSString *art1Name = @"Art1Name";
    __block NSString *art2Name = @"Art2Name";
    __block SDLArtwork *cell1Art2 = [[SDLArtwork alloc] initWithData:cellArtData2 name:art1Name fileExtension:@"png" persistent:NO];

    __block SDLChoiceCell *cellBasic = nil;
    __block SDLChoiceCell *cellBasicDuplicate = nil;
    __block SDLChoiceCell *cellWithVR = nil;
    __block SDLChoiceCell *cellWithAllText = nil;

    __block NSMutableOrderedSet<SDLChoiceCell *> *cellsWithoutArtwork = nil;

    __block SDLCreateInteractionChoiceSetResponse *testBadResponse = nil;
    __block SDLCreateInteractionChoiceSetResponse *testGoodResponse = nil;

    __block NSSet<SDLChoiceCell *> *resultChoices = nil;
    __block NSError *resultPreloadError = nil;
    __block SDLTriggerSource resultTriggerSource = SDLTriggerSourceMenu;
    __block SDLChoiceCell *resultChoiceCell = nil;
    __block NSUInteger resultChoiceRow = NSUIntegerMax;
    __block NSError *resultPresentError = nil;

    __block SDLChoiceSet *testChoiceSet = nil;
    __block int testCancelID = 98;
    __block SDLInteractionMode testInteractionMode = SDLInteractionModeBoth;
    __block SDLKeyboardProperties *testKeyboardProperties = nil;
    __block id<SDLKeyboardDelegate> testKeyboardDelegate = nil;
    __block id<SDLChoiceSetDelegate> testChoiceDelegate = nil;

    beforeEach(^{
        resultPreloadError = nil;
        resultChoices = nil;

        testConnectionManager = [[TestConnectionManager alloc] init];
        testFileManager = OCMClassMock([SDLFileManager class]);
        OCMStub([testFileManager uploadArtworks:[OCMArg any] completionHandler:[OCMArg invokeBlock]]);
        OCMStub([testFileManager fileNeedsUpload:[OCMArg isNotNil]]).andReturn(YES);

        enabledWindowCapability = [[SDLWindowCapability alloc] init];
        enabledWindowCapability.textFields = @[
            [[SDLTextField alloc] initWithName:SDLTextFieldNameMenuName characterSet:SDLCharacterSetUtf8 width:500 rows:1],
            [[SDLTextField alloc] initWithName:SDLTextFieldNameSecondaryText characterSet:SDLCharacterSetUtf8 width:500 rows:1],
            [[SDLTextField alloc] initWithName:SDLTextFieldNameTertiaryText characterSet:SDLCharacterSetUtf8 width:500 rows:1]
        ];
        enabledWindowCapability.imageFields = @[
            [[SDLImageField alloc] initWithName:SDLImageFieldNameChoiceImage imageTypeSupported:@[SDLFileTypePNG] imageResolution:nil],
            [[SDLImageField alloc] initWithName:SDLImageFieldNameChoiceSecondaryImage imageTypeSupported:@[SDLFileTypePNG] imageResolution:nil]
        ];
        disabledWindowCapability = [[SDLWindowCapability alloc] init];
        disabledWindowCapability.textFields = @[];
        primaryTextOnlyCapability = [[SDLWindowCapability alloc] init];
        primaryTextOnlyCapability.textFields = @[
            [[SDLTextField alloc] initWithName:SDLTextFieldNameMenuName characterSet:SDLCharacterSetUtf8 width:500 rows:1],
        ];

        SDLArtwork *cell1Art = [[SDLArtwork alloc] initWithData:cellArtData name:art1Name fileExtension:@"png" persistent:NO];
        SDLChoiceCell *cell1WithArt = [[SDLChoiceCell alloc] initWithText:@"Cell1" artwork:cell1Art voiceCommands:nil];
        SDLArtwork *cell2Art = [[SDLArtwork alloc] initWithData:cellArtData name:art2Name fileExtension:@"png" persistent:NO];
        SDLChoiceCell *cell2WithArtAndSecondary = [[SDLChoiceCell alloc] initWithText:@"Cell2" secondaryText:nil tertiaryText:nil voiceCommands:nil artwork:cell2Art secondaryArtwork:cell2Art];

        SDLArtwork *staticIconArt = [SDLArtwork artworkWithStaticIcon:SDLStaticIconNameDate];
        SDLChoiceCell *cellWithStaticIcon = [[SDLChoiceCell alloc] initWithText:@"Static Icon" secondaryText:nil tertiaryText:nil voiceCommands:nil artwork:staticIconArt secondaryArtwork:nil];

        cellsWithArtwork = [[NSMutableOrderedSet alloc] initWithArray:@[cell1WithArt, cell2WithArtAndSecondary]];
        cellsWithStaticIcon = [[NSMutableOrderedSet alloc] initWithArray:@[cellWithStaticIcon]];

        cellBasic = [[SDLChoiceCell alloc] initWithText:@"Cell1" artwork:nil voiceCommands:nil];
        cellBasicDuplicate = [[SDLChoiceCell alloc] initWithText:@"Cell1" artwork:nil voiceCommands:nil];
        cellWithVR = [[SDLChoiceCell alloc] initWithText:@"Cell2" secondaryText:nil tertiaryText:nil voiceCommands:@[@"Cell2"] artwork:nil secondaryArtwork:nil];
        cellWithAllText = [[SDLChoiceCell alloc] initWithText:@"Cell2" secondaryText:@"Cell2" tertiaryText:@"Cell2" voiceCommands:nil artwork:nil secondaryArtwork:nil];
        cellsWithoutArtwork = [[NSMutableOrderedSet alloc] initWithArray:@[cellBasic, cellWithVR, cellWithAllText]];

        testBadResponse = [[SDLCreateInteractionChoiceSetResponse alloc] init];
        testBadResponse.success = @NO;
        testBadResponse.resultCode = SDLResultRejected;

        testGoodResponse = [[SDLCreateInteractionChoiceSetResponse alloc] init];
        testGoodResponse.success = @YES;
        testGoodResponse.resultCode = SDLResultSuccess;

        testChoiceDelegate = OCMProtocolMock(@protocol(SDLChoiceSetDelegate));
        testKeyboardDelegate = OCMProtocolMock(@protocol(SDLKeyboardDelegate));
        OCMStub([testKeyboardDelegate customKeyboardConfiguration]).andReturn(nil);
        testKeyboardProperties = [[SDLKeyboardProperties alloc] initWithLanguage:SDLLanguageArSa keyboardLayout:SDLKeyboardLayoutAZERTY keypressMode:SDLKeypressModeResendCurrentEntry limitedCharacterList:nil autoCompleteList:nil maskInputCharacters:nil customKeys:nil];
        testChoiceSet = [[SDLChoiceSet alloc] initWithTitle:@"Choice Set" delegate:testChoiceDelegate choices:@[cellBasic, cellWithAllText]];

        resultTriggerSource = SDLTriggerSourceMenu;
        resultChoiceCell = nil;
        resultChoiceRow = NSUIntegerMax;
        resultPresentError = nil;
    });

    it(@"should have a priority of 'normal'", ^{
        testOp = [[SDLPreloadPresentChoicesOperation alloc] init];

        expect(@(testOp.queuePriority)).to(equal(@(NSOperationQueuePriorityNormal)));
    });

    context(@"running a preload only operation", ^{
        describe(@"updating cells for uniqueness", ^{
            beforeEach(^{
                testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:enabledWindowCapability isVROptional:YES cellsToPreload:[NSOrderedSet orderedSetWithArray:@[cellWithVR]] loadedCells:[NSSet setWithArray:@[cellWithAllText]] preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {}];
            });

            context(@"when some choices are already uploaded with duplicate titles version >= 7.1.0", ^{
                beforeEach(^{
                    [SDLGlobals sharedGlobals].rpcVersion = choiceSetUniquenessActiveVersion;
                });

                context(@"if there are duplicate cells once you strip unused cell properties", ^{
                    beforeEach(^{
                        testOp.windowCapability = primaryTextOnlyCapability;
                        [testOp start];
                    });

                    it(@"should update the choiceCells' unique title", ^{
                        for (SDLChoiceCell *choiceCell in testOp.cellsToUpload) {
                            if (choiceCell.secondaryText) {
                                expect(choiceCell.uniqueText).to(equal("test1 (2)"));
                            } else {
                                expect(choiceCell.uniqueText).to(equal("test1"));
                            }
                        }
                        expect(testOp.cellsToUpload).to(haveCount(2));
                        expect(testOp.cellsToUpload).to(contain(cellBasic));
                        expect(testOp.cellsToUpload).to(contain(cellBasicDuplicate));
                    });
                });

                context(@"if all cell properties are used", ^{
                    beforeEach(^{
                        testOp.windowCapability = enabledWindowCapability;
                    });

                    it(@"should not update the choiceCells' unique title", ^{
                        NSArray<SDLChoiceCell *> *cellsToUpload = testOp.cellsToUpload.array;
                        for (SDLChoiceCell *choiceCell in cellsToUpload) {
                            expect(choiceCell.uniqueText).to(equal("test1"));
                        }
                        expect(cellsToUpload).to(haveCount(2));
                        expect(cellsToUpload).to(contain(cellBasic));
                        expect(cellsToUpload).to(contain(cellBasicDuplicate));
                    });
                });
            });

            context(@"when some choices are already uploaded with duplicate titles version <= 7.1.0", ^{
                beforeEach(^{
                    [SDLGlobals sharedGlobals].rpcVersion = choiceSetUniquenessInactiveVersion;
                    [testOp start];
                });

                it(@"append a number to the unique text for choice set cells", ^{
                    NSArray<SDLChoiceCell *> *cellsToUpload = testOp.cellsToUpload.array;
                    for (SDLChoiceCell *choiceCell in cellsToUpload) {
                        if (choiceCell.secondaryText) {
                            expect(choiceCell.uniqueText).to(equal("test1 (2)"));
                        } else {
                            expect(choiceCell.uniqueText).to(equal("test1"));
                        }
                    }
                    expect(cellsToUpload).to(haveCount(2));
                    expect(cellsToUpload).to(contain(cellBasic));
                    expect(cellsToUpload).to(contain(cellBasicDuplicate));
                });
            });
        });

        context(@"with artworks", ^{
            context(@"if the menuName is not set", ^{
                it(@"should not send any requests", ^{;
                    testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:disabledWindowCapability isVROptional:YES cellsToPreload:[NSOrderedSet orderedSet] loadedCells:[cellsWithArtwork set] preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                        resultPreloadError = error;
                        resultChoices = updatedLoadedCells;
                    }];
                    [testOp start];

                    expect(testOp.cellsToUpload).to(haveCount(0));
                });
            });

            context(@"only main text capabilities", ^{
                it(@"should skip to preloading cells", ^{
                    testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:primaryTextOnlyCapability isVROptional:YES cellsToPreload:[NSOrderedSet orderedSet] loadedCells:[cellsWithArtwork set] preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                        resultPreloadError = error;
                        resultChoices = updatedLoadedCells;
                    }];
                    [testOp start];

                    expect(testConnectionManager.receivedRequests).to(haveCount(2));
                });
            });

            context(@"all text and image display capabilities", ^{
                context(@"when artworks are already on the system", ^{
                    beforeEach(^{
                        OCMStub([testFileManager hasUploadedFile:[OCMArg isNotNil]]).andReturn(YES);

                        testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:enabledWindowCapability isVROptional:YES cellsToPreload:cellsWithArtwork loadedCells:[cellsWithArtwork set] preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                            resultPreloadError = error;
                            resultChoices = updatedLoadedCells;
                        }];
                    });

                    it(@"should not upload artworks", ^{
                        OCMReject([testFileManager uploadArtworks:[OCMArg checkWithBlock:^BOOL(id obj) {
                            NSArray<SDLArtwork *> *artworks = (NSArray<SDLArtwork *> *)obj;
                            return (artworks.count == 2);
                        }] completionHandler:[OCMArg any]]);

                        [testOp start];

                        OCMVerifyAll(testFileManager);
                    });

                    it(@"should properly overwrite artwork", ^{
                        OCMExpect([testFileManager uploadArtworks:[OCMArg any] completionHandler:[OCMArg any]]);

                        cell1Art2.overwrite = YES;
                        SDLChoiceCell *cell1WithArt = [[SDLChoiceCell alloc] initWithText:@"Cell1" artwork:cell1Art2 voiceCommands:nil];

                        SDLArtwork *cell2Art = [[SDLArtwork alloc] initWithData:cellArtData name:art2Name fileExtension:@"png" persistent:NO];
                        SDLChoiceCell *cell2WithArtAndSecondary = [[SDLChoiceCell alloc] initWithText:@"Cell2" secondaryText:nil tertiaryText:nil voiceCommands:nil artwork:cell2Art secondaryArtwork:cell2Art];

                        testOp.cellsToUpload = [NSMutableOrderedSet orderedSetWithArray:@[cell1WithArt, cell2WithArtAndSecondary]];
                        [testOp start];

                        OCMVerifyAll(testFileManager);
                    });
                });

                context(@"when artworks are static icons", ^{
                    beforeEach(^{
                        testOp.cellsToUpload = cellsWithStaticIcon;
                        [testOp start];
                    });

                    it(@"should skip uploading artwork", ^{
                        OCMReject([testFileManager uploadArtwork:[OCMArg any] completionHandler:[OCMArg any]]);
                    });
                });

                context(@"when artwork are not already on the system", ^{
                    beforeEach(^{
                        OCMStub([testFileManager hasUploadedFile:[OCMArg isNotNil]]).andReturn(NO);

                        testOp.cellsToUpload = cellsWithArtwork;
                        testOp.loadedCells = [NSSet set];
                    });

                    it(@"should upload artworks", ^{
                        OCMExpect([testFileManager uploadArtworks:[OCMArg checkWithBlock:^BOOL(id obj) {
                            NSArray<SDLArtwork *> *artworks = (NSArray<SDLArtwork *> *)obj;
                            return (artworks.count == 3);
                        }] completionHandler:[OCMArg any]]);

                        [testOp start];
                        OCMVerifyAll(testFileManager);
                    });
                });
            });
        });

        context(@"without artworks", ^{
            describe(@"assembling choices", ^{
                beforeEach(^{
                    testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:enabledWindowCapability isVROptional:YES cellsToPreload:cellsWithoutArtwork loadedCells:emptyLoadedCells preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                        resultChoices = updatedLoadedCells;
                        resultPreloadError = error;
                    }];
                });

                it(@"should skip preloading the choices if all choice items have already been uploaded", ^{
                    testOp.loadedCells = cellsWithoutArtwork.set;
                    [testOp start];

                    expect(testConnectionManager.receivedRequests).to(haveCount(0));
                });

                it(@"should be correct with no text and VR required", ^{
                    testOp.windowCapability = disabledWindowCapability;
                    [testOp start];

                    NSArray<SDLCreateInteractionChoiceSet *> *receivedRequests = (NSArray<SDLCreateInteractionChoiceSet *> *)testConnectionManager.receivedRequests;

                    expect(receivedRequests).to(haveCount(3));
                    expect(receivedRequests.lastObject.choiceSet.firstObject.menuName).toNot(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.secondaryText).to(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.tertiaryText).to(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.vrCommands).toNot(beNil());
                });

                it(@"should be correct with only primary text", ^{
                    testOp.windowCapability = primaryTextOnlyCapability;
                    [testOp start];

                    NSArray<SDLCreateInteractionChoiceSet *> *receivedRequests = (NSArray<SDLCreateInteractionChoiceSet *> *)testConnectionManager.receivedRequests;

                    expect(receivedRequests).to(haveCount(3));
                    expect(receivedRequests.lastObject.choiceSet.firstObject.menuName).toNot(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.secondaryText).to(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.tertiaryText).to(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.vrCommands).toNot(beNil());
                });

                it(@"should be correct with all text", ^{
                    SDLWindowCapability *allTextCapability = [enabledWindowCapability copy];
                    allTextCapability.imageFields = @[];
                    testOp.windowCapability = allTextCapability;
                    [testOp start];

                    NSArray<SDLCreateInteractionChoiceSet *> *receivedRequests = (NSArray<SDLCreateInteractionChoiceSet *> *)testConnectionManager.receivedRequests;

                    expect(receivedRequests).to(haveCount(3));
                    expect(receivedRequests.lastObject.choiceSet.firstObject.menuName).toNot(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.secondaryText).toNot(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.tertiaryText).toNot(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.vrCommands).toNot(beNil());
                });

                it(@"should be correct with VR optional", ^{
                    testOp.vrOptional = NO;
                    [testOp start];

                    NSArray<SDLCreateInteractionChoiceSet *> *receivedRequests = (NSArray<SDLCreateInteractionChoiceSet *> *)testConnectionManager.receivedRequests;

                    expect(receivedRequests).to(haveCount(3));
                    expect(receivedRequests.lastObject.choiceSet.firstObject.menuName).toNot(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.secondaryText).to(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.tertiaryText).to(beNil());
                    expect(receivedRequests.lastObject.choiceSet.firstObject.vrCommands).to(beNil());
                });
            });
        });

        describe(@"the module's response to choice uploads", ^{
            context(@"when a bad response comes back", ^{
                beforeEach(^{
                    testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:primaryTextOnlyCapability isVROptional:YES cellsToPreload:cellsWithoutArtwork loadedCells:emptyLoadedCells preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                        resultChoices = updatedLoadedCells;
                        resultPreloadError = error;
                    }];
                });

                it(@"should not add the item to the list of loaded cells", ^{
                    [testOp start];

                    NSArray<SDLCreateInteractionChoiceSet *> *receivedRequests = (NSArray<SDLCreateInteractionChoiceSet *> *)testConnectionManager.receivedRequests;

                    expect(receivedRequests).to(haveCount(2));
                    expect(receivedRequests[0].choiceSet[0].menuName).to(equal(cellsWithoutArtwork[0].text));
                    expect(receivedRequests[1].choiceSet[0].menuName).to(equal(cellsWithoutArtwork[1].text));

                    [testConnectionManager respondToRequestWithResponse:testGoodResponse requestNumber:0 error:nil];
                    [testConnectionManager respondToRequestWithResponse:testBadResponse requestNumber:1 error:[NSError errorWithDomain:SDLErrorDomainChoiceSetManager code:SDLChoiceSetManagerErrorUploadFailed userInfo:nil]];
                    [testConnectionManager respondToLastMultipleRequestsWithSuccess:NO];

                    expect(testOp.loadedCells).to(haveCount(1));
                    expect(testOp.loadedCells).to(contain(cellsWithoutArtwork[0]));
                    expect(testOp.loadedCells).toNot(contain(cellsWithoutArtwork[1]));
                    expect(testOp.error).toNot(beNil());
                    expect(resultChoices).toNot(beNil());
                    expect(resultPreloadError).toNot(beNil());
                });
            });

            context(@"when only good responses comes back", ^{
                beforeEach(^{
                    testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager displayName:testDisplayName windowCapability:primaryTextOnlyCapability isVROptional:YES cellsToPreload:cellsWithoutArtwork loadedCells:emptyLoadedCells preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                        resultChoices = updatedLoadedCells;
                        resultPreloadError = error;
                    }];
                });

                it(@"should add all the items to the list of loaded cells", ^{
                    [testOp start];

                    NSArray<SDLCreateInteractionChoiceSet *> *receivedRequests = (NSArray<SDLCreateInteractionChoiceSet *> *)testConnectionManager.receivedRequests;

                    expect(receivedRequests).to(haveCount(2));
                    expect(receivedRequests[0].choiceSet[0].menuName).to(equal(cellsWithoutArtwork[0].text));
                    expect(receivedRequests[1].choiceSet[0].menuName).to(equal(cellsWithoutArtwork[1].text));

                    [testConnectionManager respondToRequestWithResponse:testGoodResponse requestNumber:0 error:nil];
                    [testConnectionManager respondToRequestWithResponse:testGoodResponse requestNumber:1 error:nil];
                    [testConnectionManager respondToLastMultipleRequestsWithSuccess:YES];

                    expect(resultChoices).to(haveCount(2));
                    expect(testOp.loadedCells).to(contain(cellsWithoutArtwork[0]));
                    expect(testOp.loadedCells).to(contain(cellsWithoutArtwork[1]));
                    expect(resultPreloadError).to(beNil());
                });
            });
        });
    });

    context(@"running a preload and present operation", ^{
        beforeEach(^{
            testOp = [[SDLPreloadPresentChoicesOperation alloc] initWithConnectionManager:testConnectionManager fileManager:testFileManager choiceSet:testChoiceSet mode:testInteractionMode keyboardProperties:testKeyboardProperties keyboardDelegate:testKeyboardDelegate cancelID:testCancelID displayName:testDisplayName windowCapability:enabledWindowCapability isVROptional:YES loadedCells:emptyLoadedCells preloadCompletionHandler:^(NSSet<SDLChoiceCell *> * _Nonnull updatedLoadedCells, NSError * _Nullable error) {
                resultChoices = updatedLoadedCells;
                resultPreloadError = error;
            } presentCompletionHandler:^(SDLChoiceCell * _Nullable selectedCell, NSUInteger selectedRow, SDLTriggerSource  _Nonnull selectedTriggerSource, NSError * _Nullable error) {
                resultChoiceCell = selectedCell;
                resultTriggerSource = selectedTriggerSource;
                resultChoiceRow = selectedRow;
                resultPresentError = error;
            }];
        });

        describe(@"updating cells for uniqueness", ^{
            context(@"when some choices are already uploaded with duplicate titles version >= 7.1.0", ^{
                beforeEach(^{
                    [SDLGlobals sharedGlobals].rpcVersion = choiceSetUniquenessActiveVersion;
                });

                context(@"if there are duplicate cells once you strip unused cell properties", ^{
                    beforeEach(^{
                        testOp.windowCapability = primaryTextOnlyCapability;
                        [testOp start];
                    });

                    it(@"should update the choiceCells' unique title", ^{
                        for (SDLChoiceCell *choiceCell in testOp.cellsToUpload) {
                            if (choiceCell.secondaryText) {
                                expect(choiceCell.uniqueText).to(equal("test1 (2)"));
                            } else {
                                expect(choiceCell.uniqueText).to(equal("test1"));
                            }
                        }
                        expect(testOp.cellsToUpload).to(haveCount(2));
                        expect(testOp.cellsToUpload).to(contain(cellBasic));
                        expect(testOp.cellsToUpload).to(contain(cellBasicDuplicate));
                    });
                });

                context(@"if all cell properties are used", ^{
                    beforeEach(^{
                        testOp.windowCapability = enabledWindowCapability;
                    });

                    it(@"should not update the choiceCells' unique title", ^{
                        NSArray<SDLChoiceCell *> *cellsToUpload = testOp.cellsToUpload.array;
                        for (SDLChoiceCell *choiceCell in cellsToUpload) {
                            expect(choiceCell.uniqueText).to(equal("test1"));
                        }
                        expect(cellsToUpload).to(haveCount(2));
                        expect(cellsToUpload).to(contain(cellBasic));
                        expect(cellsToUpload).to(contain(cellBasicDuplicate));
                    });
                });
            });

            context(@"when some choices are already uploaded with duplicate titles version <= 7.1.0", ^{
                beforeEach(^{
                    [SDLGlobals sharedGlobals].rpcVersion = choiceSetUniquenessInactiveVersion;
                    [testOp start];
                });

                it(@"append a number to the unique text for choice set cells", ^{
                    NSArray<SDLChoiceCell *> *cellsToUpload = testOp.cellsToUpload.array;
                    for (SDLChoiceCell *choiceCell in cellsToUpload) {
                        if (choiceCell.secondaryText) {
                            expect(choiceCell.uniqueText).to(equal("test1 (2)"));
                        } else {
                            expect(choiceCell.uniqueText).to(equal("test1"));
                        }
                    }
                    expect(cellsToUpload).to(haveCount(2));
                    expect(cellsToUpload).to(contain(cellBasic));
                    expect(cellsToUpload).to(contain(cellBasicDuplicate));
                });
            });
        });

        describe(@"running a non-searchable choice set operation", ^{
            beforeEach(^{
                testOp.keyboardDelegate = nil;
                [testOp start];

                // Move us past the preload
                testConnectionManager respondToRequestWithResponse:<#(nonnull __kindof SDLRPCResponse *)#> requestNumber:<#(NSInteger)#> error:<#(nullable NSError *)#>
                [testConnectionManager respondToLastMultipleRequestsWithSuccess:YES];
            });

            it(@"should not update global keyboard properties", ^{
                expect(testConnectionManager.receivedRequests.lastObject).toNot(beAnInstanceOf([SDLSetGlobalProperties class]));
            });

            describe(@"presenting the choice set", ^{
                it(@"should send the perform interaction", ^{
                    expect(testConnectionManager.receivedRequests.lastObject).to(beAnInstanceOf([SDLPerformInteraction class]));
                    SDLPerformInteraction *request = testConnectionManager.receivedRequests.lastObject;
                    expect(request.initialText).to(equal(testChoiceSet.title));
                    expect(request.initialPrompt).to(equal(testChoiceSet.initialPrompt));
                    expect(request.interactionMode).to(equal(testInteractionMode));
                    expect(request.interactionLayout).to(equal(SDLLayoutModeIconOnly));
                    expect(request.timeoutPrompt).to(equal(testChoiceSet.timeoutPrompt));
                    expect(request.helpPrompt).to(equal(testChoiceSet.helpPrompt));
                    expect(request.timeout).to(equal(testChoiceSet.timeout * 1000));
                    expect(request.vrHelp).to(beNil());
                    expect(request.interactionChoiceSetIDList).to(equal(@[@65535]));
                    expect(request.cancelID).to(equal(testCancelID));
                });

                describe(@"after a perform interaction response", ^{
                    __block UInt16 responseChoiceId = UINT16_MAX;
                    __block SDLTriggerSource responseTriggerSource = SDLTriggerSourceMenu;

                    beforeEach(^{
                        SDLPerformInteractionResponse *response = [[SDLPerformInteractionResponse alloc] init];
                        response.success = @YES;
                        response.choiceID = @(responseChoiceId);
                        response.triggerSource = responseTriggerSource;

                        [testConnectionManager respondToLastRequestWithResponse:response];
                    });

                    it(@"should not reset the keyboard properties and should be finished", ^{
                        expect(testConnectionManager.receivedRequests.lastObject).toNot(beAnInstanceOf([SDLSetGlobalProperties class]));
                        expect(testOp.isFinished).to(beTrue());
                        expect(resultChoiceCell).to(equal(testChoices.firstObject));
                        expect(resultTriggerSource).to(equal(responseTriggerSource));
                    });
                });
            });

            describe(@"Canceling the choice set", ^{
                context(@"if the head unit supports the `CancelInteration` RPC", ^{
                    beforeEach(^{
                        SDLVersion *supportedVersion = [SDLVersion versionWithMajor:6 minor:0 patch:0];
                        id globalMock = OCMPartialMock([SDLGlobals sharedGlobals]);
                        OCMStub([globalMock rpcVersion]).andReturn(supportedVersion);
                    });

                     context(@"If the operation is executing", ^{
                         beforeEach(^{
                             [testCancelOp start];

                             expect(testCancelOp.isExecuting).to(beTrue());
                             expect(testCancelOp.isFinished).to(beFalse());
                             expect(testCancelOp.isCancelled).to(beFalse());

                             [testChoiceSet cancel];
                         });

                         it(@"should attempt to send a cancel interaction", ^{
                             SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                             expect(lastRequest).to(beAnInstanceOf([SDLCancelInteraction class]));
                             expect(lastRequest.cancelID).to(equal(testCancelID));
                             expect(lastRequest.functionID).to(equal([SDLFunctionID.sharedInstance functionIdForName:SDLRPCFunctionNamePerformInteraction]));
                         });

                         context(@"If the cancel interaction was successful", ^{
                             beforeEach(^{
                                 SDLCancelInteractionResponse *testCancelInteractionResponse = [[SDLCancelInteractionResponse alloc] init];
                                 testCancelInteractionResponse.success = @YES;
                                 [testConnectionManager respondToLastRequestWithResponse:testCancelInteractionResponse];
                             });

                             it(@"should not error", ^{
                                 expect(testCancelOp.error).to(beNil());
                             });

                             it(@"should not finish", ^{
                                 expect(testCancelOp.isExecuting).to(beTrue());
                                 expect(testCancelOp.isFinished).to(beFalse());
                                 expect(testCancelOp.isCancelled).to(beFalse());
                             });
                         });

                         context(@"If the cancel interaction was not successful", ^{
                             __block NSError *testError = [NSError sdl_lifecycle_notConnectedError];

                             beforeEach(^{
                                 SDLCancelInteractionResponse *testCancelInteractionResponse = [[SDLCancelInteractionResponse alloc] init];
                                 testCancelInteractionResponse.success = @NO;
                                 [testConnectionManager respondToLastRequestWithResponse:testCancelInteractionResponse error:testError];
                             });

                             it(@"should error", ^{
                                 expect(testCancelOp.error).to(equal(testError));
                             });

                             it(@"should not finish", ^{
                                 expect(testCancelOp.isExecuting).to(beTrue());
                                 expect(testCancelOp.isFinished).to(beFalse());
                                 expect(testCancelOp.isCancelled).to(beFalse());
                             });
                         });
                     });

                     context(@"If the operation has already finished", ^{
                         beforeEach(^{
                             [testCancelOp finishOperation];

                             expect(testCancelOp.isExecuting).to(beFalse());
                             expect(testCancelOp.isFinished).to(beTrue());
                             expect(testCancelOp.isCancelled).to(beFalse());

                             [testChoiceSet cancel];
                         });

                         it(@"should not attempt to send a cancel interaction", ^{
                             SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                             expect(lastRequest).toNot(beAnInstanceOf([SDLCancelInteraction class]));
                         });
                     });

                     context(@"If the started operation has been canceled", ^{
                         beforeEach(^{
                             [testCancelOp start];
                             [testCancelOp cancel];

                             expect(testCancelOp.isExecuting).to(beTrue());
                             expect(testCancelOp.isFinished).to(beFalse());
                             expect(testCancelOp.isCancelled).to(beTrue());

                             [testChoiceSet cancel];
                         });

                         it(@"should not attempt to send a cancel interaction", ^{
                             SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                             expect(lastRequest).toNot(beAnInstanceOf([SDLCancelInteraction class]));
                         });

                         it(@"should not finish", ^{
                             expect(testCancelOp.isExecuting).toEventually(beTrue());
                             expect(testCancelOp.isFinished).toEventually(beFalse());
                             expect(testCancelOp.isCancelled).toEventually(beTrue());
                         });
                     });

                    context(@"If the operation has not started", ^{
                        beforeEach(^{
                            expect(testCancelOp.isExecuting).to(beFalse());
                            expect(testCancelOp.isFinished).to(beFalse());
                            expect(testCancelOp.isCancelled).to(beFalse());

                            [testChoiceSet cancel];
                        });

                        it(@"should not attempt to send a cancel interaction", ^{
                            SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                            expect(lastRequest).toNot(beAnInstanceOf([SDLCancelInteraction class]));
                        });

                        context(@"Once the operation has started", ^{
                            beforeEach(^{
                                [testCancelOp start];
                            });

                            it(@"should not attempt to send a cancel interaction", ^{
                                SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                                expect(lastRequest).toNot(beAnInstanceOf([SDLCancelInteraction class]));
                            });

                            it(@"should finish", ^{
                                expect(testCancelOp.isExecuting).toEventually(beFalse());
                                expect(testCancelOp.isFinished).toEventually(beTrue());
                                expect(testCancelOp.isCancelled).toEventually(beTrue());
                            });
                        });
                    });
                });

                context(@"Head unit does not support the `CancelInteration` RPC", ^{
                    beforeEach(^{
                        SDLVersion *unsupportedVersion = [SDLVersion versionWithMajor:5 minor:1 patch:0];
                        id globalMock = OCMPartialMock([SDLGlobals sharedGlobals]);
                        OCMStub([globalMock rpcVersion]).andReturn(unsupportedVersion);
                    });

                    it(@"should not attempt to send a cancel interaction if the operation is executing", ^{
                        [testCancelOp start];

                        expect(testCancelOp.isExecuting).to(beTrue());
                        expect(testCancelOp.isFinished).to(beFalse());
                        expect(testCancelOp.isCancelled).to(beFalse());

                        [testChoiceSet cancel];

                        SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                        expect(lastRequest).toNot(beAnInstanceOf([SDLCancelInteraction class]));
                    });

                    it(@"should cancel the operation if it has not yet been run", ^{
                        expect(testCancelOp.isExecuting).to(beFalse());
                        expect(testCancelOp.isFinished).to(beFalse());
                        expect(testCancelOp.isCancelled).to(beFalse());

                        [testChoiceSet cancel];

                        SDLCancelInteraction *lastRequest = testConnectionManager.receivedRequests.lastObject;
                        expect(lastRequest).toNot(beAnInstanceOf([SDLCancelInteraction class]));

                        expect(testCancelOp.isExecuting).to(beFalse());
                        expect(testCancelOp.isFinished).to(beFalse());
                        expect(testCancelOp.isCancelled).to(beTrue());
                    });
                });
            });
        });

        describe(@"running a searchable choice set operation", ^{
            beforeEach(^{
                testOp = [[SDLPresentChoiceSetOperation alloc] initWithConnectionManager:testConnectionManager choiceSet:testChoiceSet mode:testInteractionMode keyboardProperties:testKeyboardProperties keyboardDelegate:testKeyboardDelegate cancelID:testCancelID windowCapability:windowCapability loadedCells:testLoadedChoices completionHandler:^(SDLChoiceCell * _Nullable selectedCell, NSUInteger selectedRow, SDLTriggerSource  _Nonnull selectedTriggerSource, NSError * _Nullable error) {
                    resultChoiceCell = selectedCell;
                    resultChoiceRow = selectedRow;
                    resultTriggerSource = selectedTriggerSource;
                    resultError = error;
                }];

                [testOp start];
            });

            it(@"should ask for custom properties", ^{
                OCMVerify([testKeyboardDelegate customKeyboardConfiguration]);
            });

            it(@"should update global keyboard properties", ^{
                expect(testConnectionManager.receivedRequests.lastObject).to(beAnInstanceOf([SDLSetGlobalProperties class]));
            });

            describe(@"presenting the keyboard", ^{
                beforeEach(^{
                    SDLSetGlobalPropertiesResponse *response = [[SDLSetGlobalPropertiesResponse alloc] init];
                    response.success = @YES;
                    [testConnectionManager respondToLastRequestWithResponse:response];
                });

                it(@"should send the perform interaction", ^{
                    expect(testConnectionManager.receivedRequests.lastObject).to(beAnInstanceOf([SDLPerformInteraction class]));
                    SDLPerformInteraction *request = testConnectionManager.receivedRequests.lastObject;
                    expect(request.initialText).to(equal(testChoiceSet.title));
                    expect(request.initialPrompt).to(equal(testChoiceSet.initialPrompt));
                    expect(request.interactionMode).to(equal(testInteractionMode));
                    expect(request.interactionLayout).to(equal(SDLLayoutModeIconWithSearch));
                    expect(request.timeoutPrompt).to(equal(testChoiceSet.timeoutPrompt));
                    expect(request.helpPrompt).to(equal(testChoiceSet.helpPrompt));
                    expect(request.timeout).to(equal(testChoiceSet.timeout * 1000));
                    expect(request.vrHelp).to(beNil());
                    expect(request.interactionChoiceSetIDList).to(equal(@[@65535]));
                    expect(request.cancelID).to(equal(testCancelID));
                });

                it(@"should respond to submitted notifications", ^{
                    NSString *inputData = @"Test";
                    SDLRPCNotificationNotification *notification = nil;

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventSubmitted;
                    input.data = inputData;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventSubmitted];
                    }] text:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(NSString *)obj isEqualToString:inputData];
                    }]]);

                    OCMVerify([testKeyboardDelegate userDidSubmitInput:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(NSString *)obj isEqualToString:inputData];
                    }] withEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventSubmitted];
                    }]]);
                });

                it(@"should respond to voice request notifications", ^{
                    SDLRPCNotificationNotification *notification = nil;

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventVoice;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventVoice];
                    }] text:[OCMArg isNil]]);

                    OCMVerify([testKeyboardDelegate userDidSubmitInput:[OCMArg isNil] withEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventVoice];
                    }]]);
                });

                it(@"should respond to abort notifications", ^{
                    SDLRPCNotificationNotification *notification = nil;

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventAborted;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventAborted];
                    }] text:[OCMArg isNil]]);

                    OCMVerify([testKeyboardDelegate keyboardDidAbortWithReason:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventAborted];
                    }]]);
                });

                it(@"should respond to enabled keyboard event", ^{
                    SDLRPCNotificationNotification *notification = nil;

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventInputKeyMaskEnabled;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventInputKeyMaskEnabled];
                    }] text:[OCMArg isNil]]);

                    OCMVerify([testKeyboardDelegate keyboardDidUpdateInputMask:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventInputKeyMaskEnabled];
                    }]]);
                });

                it(@"should respond to cancellation notifications", ^{
                    SDLRPCNotificationNotification *notification = nil;

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventCancelled;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventCancelled];
                    }] text:[OCMArg isNil]]);

                    OCMVerify([testKeyboardDelegate keyboardDidAbortWithReason:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventCancelled];
                    }]]);
                });

                it(@"should respond to text input notification with autocomplete", ^{
                    NSString *inputData = @"Test";
                    SDLRPCNotificationNotification *notification = nil;

                    OCMStub([testKeyboardDelegate updateAutocompleteWithInput:[OCMArg any] autoCompleteResultsHandler:([OCMArg invokeBlockWithArgs:@[inputData], nil])]);

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventKeypress;
                    input.data = inputData;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventKeypress];
                    }] text:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(NSString *)obj isEqualToString:inputData];
                    }]]);

                    OCMVerify([testKeyboardDelegate updateAutocompleteWithInput:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(NSString *)obj isEqualToString:inputData];
                    }] autoCompleteResultsHandler:[OCMArg any]]);

                    expect(testConnectionManager.receivedRequests.lastObject).to(beAnInstanceOf([SDLSetGlobalProperties class]));

                    SDLSetGlobalProperties *setProperties = testConnectionManager.receivedRequests.lastObject;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    expect(setProperties.keyboardProperties.autoCompleteText).to(equal(inputData));
    #pragma clang diagnostic pop
                });

                it(@"should respond to text input notification with character set", ^{
                    NSString *inputData = @"Test";
                    SDLRPCNotificationNotification *notification = nil;

                    OCMStub([testKeyboardDelegate updateCharacterSetWithInput:[OCMArg any] completionHandler:([OCMArg invokeBlockWithArgs:@[inputData], nil])]);

                    // Submit notification
                    SDLOnKeyboardInput *input = [[SDLOnKeyboardInput alloc] init];
                    input.event = SDLKeyboardEventKeypress;
                    input.data = inputData;
                    notification = [[SDLRPCNotificationNotification alloc] initWithName:SDLDidReceiveKeyboardInputNotification object:nil rpcNotification:input];

                    [[NSNotificationCenter defaultCenter] postNotification:notification];

                    OCMVerify([testKeyboardDelegate keyboardDidSendEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(SDLKeyboardEvent)obj isEqualToEnum:SDLKeyboardEventKeypress];
                    }] text:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(NSString *)obj isEqualToString:inputData];
                    }]]);

                    OCMVerify([testKeyboardDelegate updateCharacterSetWithInput:[OCMArg checkWithBlock:^BOOL(id obj) {
                        return [(NSString *)obj isEqualToString:inputData];
                    }] completionHandler:[OCMArg any]]);

                    expect(testConnectionManager.receivedRequests.lastObject).to(beAnInstanceOf([SDLSetGlobalProperties class]));

                    SDLSetGlobalProperties *setProperties = testConnectionManager.receivedRequests.lastObject;
                    expect(setProperties.keyboardProperties.limitedCharacterList).to(equal(@[inputData]));
                });

                describe(@"after a perform interaction response", ^{
                    beforeEach(^{
                        SDLPerformInteractionResponse *response = [[SDLPerformInteractionResponse alloc] init];
                        response.success = @YES;
                        response.choiceID = @65535;
                        response.triggerSource = SDLTriggerSourceVoiceRecognition;

                        [testConnectionManager respondToLastRequestWithResponse:response];
                    });

                    it(@"should reset the keyboard properties", ^{
                        expect(testConnectionManager.receivedRequests.lastObject).to(beAnInstanceOf([SDLSetGlobalProperties class]));
                    });

                    describe(@"after the reset response", ^{
                        beforeEach(^{
                            SDLSetGlobalPropertiesResponse *response = [[SDLSetGlobalPropertiesResponse alloc] init];
                            response.success = @YES;
                            [testConnectionManager respondToLastRequestWithResponse:response];
                        });

                        it(@"should be finished", ^{
                            expect(resultChoiceCell).toNot(beNil());
                            expect(resultChoiceRow).to(equal(0));
                            expect(resultTriggerSource).to(equal(SDLTriggerSourceVoiceRecognition));
                            expect(resultError).to(beNil());
                            expect(testOp.isFinished).to(beTrue());
                        });
                    });
                });
            });
        });
    });
});

QuickSpecEnd
