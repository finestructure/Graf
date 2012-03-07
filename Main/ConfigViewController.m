//
//  ConfigViewController.m
//  Graf
//
//  Created by Sven A. Schmidt on 07.03.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ConfigViewController.h"

@interface ConfigViewController ()

@property (nonatomic, strong) NSArray *servers;

@end


@implementation ConfigViewController

@synthesize servers = _servers;
@synthesize tableView = _tableView;

#pragma mark - Actions


- (IBAction)donePressed:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *kCellIdentifier = @"ConfigCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
  }
  cell.textLabel.text = [self.servers objectAtIndex:indexPath.row];
  return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.servers.count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  NSString *title = NSLocalizedString(@"CouchDB Server", @"Config server list title");
  return title;
}


#pragma mark - Init


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.servers = [NSArray arrayWithObjects:@"Production (graf)", @"Test (graf_test)", nil];
  }
  return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
}


- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
