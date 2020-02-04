//
//  ConnectionTableViewController.h
//  SmartDeviceLink-Example-ObjC
//
//  Created by Leonid Lokhmatov on 2/3/20.
//  Copyright © 2018 Luxoft. All rights reserved
//

#import <UIKit/UIKit.h>

@class ApplicationAlpha;
@class ApplicationBeta;
@class ApplicationGamma;

@interface ConnectionTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIButton *connectButtonAlpha;
@property (weak, nonatomic) IBOutlet UIButton *connectButtonBeta;
@property (weak, nonatomic) IBOutlet UIButton *connectButtonGamma;

@property (weak, nonatomic) IBOutlet UITableViewCell *connectTableViewCellAlpha;
@property (weak, nonatomic) IBOutlet UITableViewCell *connectTableViewCellBeta;
@property (weak, nonatomic) IBOutlet UITableViewCell *connectTableViewCellGamma;

@property (strong, nonatomic) ApplicationAlpha * appAlpha;
@property (strong, nonatomic) ApplicationBeta * appBeta;
@property (strong, nonatomic) ApplicationGamma * appGamma;

- (IBAction)connectAlphaAction:(UIButton *)sender;
- (IBAction)connectBetaAction:(UIButton *)sender;
- (IBAction)connectGammaAction:(UIButton *)sender;

@end
