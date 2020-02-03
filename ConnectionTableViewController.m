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

@implementation ConnectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (nil == self.proxyManager1) {
        self.proxyManager1 = [[ProxyManager alloc] initWithName:ExampleAppName1 identifier:ExampleFullAppId1 iconName:ExampleAppLogoName1];
        // Observe Proxy Manager state
        [self.proxyManager1 addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    }
    if (nil == self.proxyManager2) {
        self.proxyManager2 = [[ProxyManager alloc] initWithName:ExampleAppName2 identifier:ExampleFullAppId2 iconName:ExampleAppLogoName2];
        // Observe Proxy Manager state
        [self.proxyManager2 addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    }

    // Tableview setup
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // Connect Button setup
    self.connectButton.tintColor = [UIColor whiteColor];
}

- (void)dealloc {
    @try {
        [self.proxyManager1 removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
        [self.proxyManager2 removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
    } @catch (NSException __unused *exception) {}
}

#pragma mark - IBActions

- (IBAction)connectButtonWasPressed:(UIButton *)sender {
    [self connectDisconnectProxy:self.proxyManager1];
    [self connectDisconnectProxy:self.proxyManager2];
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
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
        ProxyState newState = [change[NSKeyValueChangeNewKey] unsignedIntegerValue];
        [self proxyManagerDidChangeState:newState];
    }
}

#pragma mark - Private Methods

- (void)proxyManagerDidChangeState:(ProxyState)newState {
    UIColor* newColor = nil;
    NSString* newTitle = nil;

    switch (newState) {
        case ProxyStateStopped: {
            newColor = [UIColor redColor];
            newTitle = @"Connect";
        } break;
        case ProxyStateSearchingForConnection: {
            newColor = [UIColor blueColor];
            newTitle = @"Stop Searching";
        } break;
        case ProxyStateConnected: {
            newColor = [UIColor greenColor];
            newTitle = @"Disconnect";
        } break;
        default: break;
    }

    if (newColor || newTitle) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.connectTableViewCell setBackgroundColor:newColor];
            [self.connectButton setTitle:newTitle forState:UIControlStateNormal];
        });
    }
}

@end
