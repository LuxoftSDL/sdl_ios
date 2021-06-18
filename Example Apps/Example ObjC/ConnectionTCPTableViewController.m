//
//  ConnectionTCPTableViewController.m
//  SmartDeviceLink-iOS

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "ConnectionTCPTableViewController.h"

#import "Preferences.h"
#import "ProxyManager.h"
#import "SDLGlobals.h"
#import "SDLStreamingMediaManager.h"
#import "TestRootViewController.h"

@interface ConnectionTCPTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *ipAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;

@property (weak, nonatomic) IBOutlet UITableViewCell *connectTableViewCell;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *versionSelector;

@end


NSString *TestSDLVersions[4] = {@"5.0.0", @"6.0.0", @"7.1.0", @"8.0.0"};


@implementation ConnectionTCPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Observe Proxy Manager state
    [[ProxyManager sharedManager] addObserver:self forKeyPath:NSStringFromSelector(@selector(state)) options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    
    // Tableview setup
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.ipAddressTextField.text = [Preferences sharedPreferences].ipAddress;
    self.portTextField.text = [@([Preferences sharedPreferences].port) stringValue];
    
    // Connect Button setup
    self.connectButton.tintColor = [UIColor whiteColor];
    self.testButton.enabled = NO;

    for (int i=0; i < 4; ++i) {
        [self.versionSelector setTitle:TestSDLVersions[i] forSegmentAtIndex:i];
    }
}

- (void)dealloc {
    @try {
        [[ProxyManager sharedManager] removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
    } @catch (NSException __unused *exception) {}
}


#pragma mark - IBActions

- (IBAction)connectButtonWasPressed:(UIButton *)sender {
    [Preferences sharedPreferences].ipAddress = self.ipAddressTextField.text;
    [Preferences sharedPreferences].port = self.portTextField.text.integerValue;
    
    ProxyState state = [ProxyManager sharedManager].state;
    switch (state) {
        case ProxyStateStopped: {
            [[ProxyManager sharedManager] startWithProxyTransportType:ProxyTransportTypeTCP];
        } break;
        case ProxyStateSearchingForConnection: {
            [[ProxyManager sharedManager] stopConnection];
        } break;
        case ProxyStateConnected: {
            [[ProxyManager sharedManager] stopConnection];
        } break;
        default: break;
    }
}

- (IBAction)startTestAction:(UIButton *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self showTestViewControllerAnimated:YES];
}

- (IBAction)setSDLVersionAction:(UISegmentedControl *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSInteger idx = sender.selectedSegmentIndex;
    if (idx < 0 ) { idx = 0; }
    if (idx > 3 ) { idx = 3; }
    [SDLGlobals sharedGlobals].SDLMaxProxyRPCVersion = TestSDLVersions[idx];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) { return; }
    
    switch (indexPath.row) {
        case 0: {
            [self.ipAddressTextField becomeFirstResponder];
        } break;
        case 1: {
            [self.portTextField becomeFirstResponder];
        } break;
        default: break;
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
        ProxyState newState = [change[NSKeyValueChangeNewKey] unsignedIntegerValue];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf proxyManagerDidChangeState:newState];
        });
    }
}

- (void)proxyManagerDidChangeState:(ProxyState)newState {
    UIColor* newColor = nil;
    NSString* newTitle = nil;
    
    switch (newState) {
        case ProxyStateStopped: {
            newColor = [UIColor colorWithRed:(255.0 / 255.0) green:(69.0 / 255.0) blue:(58.0 / 255.0) alpha:1.0];
            newTitle = @"Connect";
        } break;
        case ProxyStateSearchingForConnection: {
            newColor = [UIColor colorWithRed:(255.0 / 255.0) green:(159.0 / 255.0) blue:(10.0 / 255.0) alpha:1.0];
            newTitle = @"Stop Searching";
        } break;
        case ProxyStateConnected: {
            newColor = [UIColor colorWithRed:(50.0 / 255.0) green:(215.0 / 255.0) blue:(75.0 / 255.0) alpha:1.0];
            newTitle = @"Disconnect";
        } break;
        default: break;
    }

    const BOOL isConnected = ProxyStateConnected == newState;
    UIButton *testButton = self.testButton;
    const BOOL isVisible = self.parentViewController.navigationController.topViewController == self.parentViewController;
    testButton.enabled = isConnected;


    if (!isConnected && !isVisible) {
        [self popToRootAnimated:YES];
    }

    if (newColor || newTitle) {
        [self.connectTableViewCell setBackgroundColor:newColor];
        [self.connectButton setTitle:newTitle forState:UIControlStateNormal];
    }
}

- (void)popToRootAnimated:(BOOL)animated {
    const BOOL isVisible = self.parentViewController.navigationController.topViewController == self.parentViewController;
    if (!isVisible) {
        [self.parentViewController.navigationController popToViewController:self.parentViewController animated:animated];
    }
}

- (void)showTestViewControllerAnimated:(BOOL)animated {
    UIStoryboard *testSB = [UIStoryboard storyboardWithName:@"TestUI" bundle:nil];
    TestRootViewController *testRootVC = (TestRootViewController *)[testSB instantiateViewControllerWithIdentifier:@"idTestRoot"];
    testRootVC.proxyManager = [ProxyManager sharedManager];
    [self.parentViewController.navigationController pushViewController:testRootVC animated:animated];
}

@end
