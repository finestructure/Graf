//
//  ConfigViewController.m
//  Graf
//
//  Created by Sven A. Schmidt on 07.03.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ConfigViewController.h"

#import "Configuration.h"
#import "Constants.h"


@interface ConfigViewController ()

@property (nonatomic, strong) NSArray *servers;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end


@implementation ConfigViewController

@synthesize selectedIndexPath = _selectedIndexPath;
@synthesize servers = _servers;
@synthesize tableView = _tableView;

#pragma mark - Actions


- (IBAction)donePressed:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  self.selectedIndexPath = indexPath;
  [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *kCellIdentifier = @"ConfigCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
  }
  cell.textLabel.text = [self.servers objectAtIndex:indexPath.row];
  if ([indexPath isEqual:self.selectedIndexPath]) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
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
    NSMutableArray *s = [NSMutableArray array];
    for (Configuration *c in [[Constants sharedInstance] configurations]) {
      [s addObject:c.name];
    }
    self.servers = s;
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
