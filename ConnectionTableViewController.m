//
//  ConnectionTableViewController.m
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/3/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import "ConnectionTableViewController.h"
#import "ProxyManager.h"
#import "AppConstants.h"
#import "ApplicationAlpha.h"
#import "ApplicationBeta.h"
#import "ApplicationGamma.h"

// KVO key to observe
static NSString * kState = @"state";


@implementation ConnectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (nil == self.appAlpha) {
        self.appAlpha = [ApplicationAlpha new];
        // Observe Proxy Manager state
        [self.appAlpha addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    }
    if (nil == self.appBeta) {
        self.appBeta = [ApplicationBeta new];
        // Observe Proxy Manager state
        [self.appBeta addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    }

    if (nil == self.appGamma) {
        self.appGamma = [ApplicationGamma new];
        // Observe Proxy Manager state
        [self.appGamma addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    }

    // Tableview setup
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // Connect Button setup
    self.connectButtonAlpha.tintColor = [UIColor whiteColor];
    self.connectButtonBeta.tintColor = [UIColor whiteColor];
    self.connectButtonGamma.tintColor = [UIColor whiteColor];
}

- (void)dealloc {
    @try {
        [self.appAlpha removeObserver:self forKeyPath:kState];
    } @catch (NSException __unused *exception) {}
    @try {
        [self.appBeta removeObserver:self forKeyPath:kState];
    } @catch (NSException __unused *exception) {}
    @try {
        [self.appGamma removeObserver:self forKeyPath:kState];
    } @catch (NSException __unused *exception) {}
}

#pragma mark - IBActions

- (IBAction)connectAlphaAction:(UIButton *)sender {
    [self connectDisconnectProxy:self.appAlpha];
}

- (IBAction)connectBetaAction:(UIButton *)sender {
    [self connectDisconnectProxy:self.appBeta];
}

- (IBAction)connectGammaAction:(UIButton *)sender {
    [self connectDisconnectProxy:self.appGamma];
}

- (void)connectDisconnectProxy:(ProxyManager*)proxyMgr {
    if (nil == proxyMgr) {
        return;
    }
    const ProxyState state = proxyMgr.state;
    switch (state) {
        case ProxyStateStopped: {
            [self connectProxy:proxyMgr];
        } break;
        case ProxyStateSearchingForConnection: {
            [proxyMgr stopConnection];
        } break;
        case ProxyStateConnected: {
            [proxyMgr stopConnection];
        } break;
    }
}

- (void)connectProxy:(ProxyManager*)proxyMgr {
    //TODO: implement it with a proper transport type
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kState]) {
        const ProxyState newState = [change[NSKeyValueChangeNewKey] unsignedIntegerValue];
        if (object == self.appAlpha) {
            [self proxyManagerDidChangeState:newState instanceNum:0];
        } else if (object == self.appBeta) {
            [self proxyManagerDidChangeState:newState instanceNum:1];
        } else if (object == self.appGamma) {
            [self proxyManagerDidChangeState:newState instanceNum:2];
        } else {
            NSLog(@"wrong kvo obj: %@", object);
        }
    }
}

#pragma mark - Private Methods

- (void)proxyManagerDidChangeState:(ProxyState)newState instanceNum:(int)num {
    UIColor* newColor = nil;
    NSString* newTitle = nil;

    switch (newState) {
        case ProxyStateStopped: {
            newColor = [UIColor redColor];
            newTitle = [NSString stringWithFormat:@"Connect %d", num+1];
        } break;
        case ProxyStateSearchingForConnection: {
            newColor = [UIColor blueColor];
            newTitle = [NSString stringWithFormat:@"Stop Searching %d", num+1];
        } break;
        case ProxyStateConnected: {
            newColor = [UIColor greenColor];
            newTitle = [NSString stringWithFormat:@"Disconnect %d", num+1];
        } break;
        default: break;
    }

    if (newColor || newTitle) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setTitle:newTitle color:newColor instanceNum:num];
        });
    }
}

- (void)setTitle:(NSString*)title color:(UIColor*)color instanceNum:(int)num {
    if (color || title) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (num) {
                case 0:
                    [self.connectTableViewCellAlpha setBackgroundColor:color];
                    [self.connectButtonAlpha setTitle:title forState:UIControlStateNormal];
                    break;

                case 1:
                    [self.connectTableViewCellBeta setBackgroundColor:color];
                    [self.connectButtonBeta setTitle:title forState:UIControlStateNormal];
                    break;

                case 2:
                    [self.connectTableViewCellGamma setBackgroundColor:color];
                    [self.connectButtonGamma setTitle:title forState:UIControlStateNormal];
                    break;
            }
        });
    }
}

@end
