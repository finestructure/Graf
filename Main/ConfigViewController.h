//
//  ConfigViewController.h
//  Graf
//
//  Created by Sven A. Schmidt on 07.03.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfigViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)donePressed:(id)sender;

@end
