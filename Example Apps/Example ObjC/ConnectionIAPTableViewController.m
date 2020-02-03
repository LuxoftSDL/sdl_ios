//
//  ConnectionIAPTableViewController.m
//  SmartDeviceLink-iOS

#import "ConnectionIAPTableViewController.h"
#import "ProxyManager.h"

@implementation ConnectionIAPTableViewController

- (void)connectProxy:(ProxyManager*)proxyMgr {
    [proxyMgr startWithProxyTransportType:ProxyTransportTypeIAP];
}

@end
