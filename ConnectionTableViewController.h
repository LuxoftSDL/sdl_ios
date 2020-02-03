//
//  ConnectionTableViewController.h
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/3/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import <UIKit/UIKit.h>

@class ProxyManager;

@interface ConnectionTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITableViewCell *connectTableViewCell;

@property (strong, nonatomic) ProxyManager * proxyManager1;
@property (strong, nonatomic) ProxyManager * proxyManager2;

- (IBAction)connectButtonWasPressed:(UIButton *)sender;

@end
