//
//  SettingsViewController.h
//  Sinma
//
//  Created by Sven A. Schmidt on 04.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kImageScaleDefault;
extern NSString * const kNumbersOnlyDefault;
extern NSString * const kPageModeDefault;

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *imageScaleLabel;
@property (weak, nonatomic) IBOutlet UISlider *imageScaleSlider;
@property (weak, nonatomic) IBOutlet UISwitch *numbersOnlySwitch;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)done:(id)sender;
- (void)valueChanged:(id)sender;

@end
