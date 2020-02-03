//
//  ConnectionTCPTableViewController.m
//  SmartDeviceLink-iOS

#import "ConnectionTCPTableViewController.h"
#import "Preferences.h"
#import "ProxyManager.h"
#import "SDLStreamingMediaManager.h"

@interface ConnectionTCPTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *ipAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;

@end


@implementation ConnectionTCPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.ipAddressTextField.text = [Preferences sharedPreferences].ipAddress;
    self.portTextField.text = [@([Preferences sharedPreferences].port) stringValue];
}

#pragma mark - IBActions

- (IBAction)connectButtonWasPressed:(UIButton *)sender {
    [Preferences sharedPreferences].ipAddress = self.ipAddressTextField.text;
    [Preferences sharedPreferences].port = self.portTextField.text.integerValue;

    [super connectButtonWasPressed:sender];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (0 == indexPath.section) {
        switch (indexPath.row) {
            case 0: {
                [self.ipAddressTextField becomeFirstResponder];
            } break;
            case 1: {
                [self.portTextField becomeFirstResponder];
            } break;
        }
    }
}

- (void)connectProxy:(ProxyManager*)proxyMgr {
    [proxyMgr startWithProxyTransportType:ProxyTransportTypeTCP];
}

@end
