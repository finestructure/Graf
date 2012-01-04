//
//  SettingsViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 04.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "SettingsViewController.h"

NSString * const kImageScaleDefault = @"ImageScale";
NSString * const kNumbersOnlyDefault = @"NumbersOnly";


@implementation SettingsViewController

@synthesize imageScaleLabel = _imageScaleLabel;
@synthesize imageScaleSlider = _imageScaleSlider;
@synthesize numbersOnlySwitch = _numbersOnlySwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Actions


- (IBAction)done:(id)sender {
  [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)valueChanged:(id)sender {
  if (sender == self.imageScaleSlider) {
    NSNumber *value = [NSNumber numberWithInt:(int)self.imageScaleSlider.value];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kImageScaleDefault];
    self.imageScaleLabel.text = [NSString stringWithFormat:@"%d", [value intValue]];
  } else if (sender == self.numbersOnlySwitch) {
    NSNumber *value = [NSNumber numberWithBool:self.numbersOnlySwitch.on];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kNumbersOnlyDefault];
  }
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  
  NSNumber *imageScale = [def valueForKey:kImageScaleDefault];
  if (imageScale == nil) {
    imageScale = [NSNumber numberWithInt:4];
  }
  self.imageScaleLabel.text = [NSString stringWithFormat:@"%d", [imageScale intValue]];
  self.imageScaleSlider.value = [imageScale floatValue];
  
  NSNumber *numbersOnly = [def valueForKey:kNumbersOnlyDefault];
  if (numbersOnly == nil) {
    numbersOnly = [NSNumber numberWithBool:NO];
  }
  self.numbersOnlySwitch.on = [numbersOnly boolValue];
  
  [self.imageScaleSlider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
  [self.numbersOnlySwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload
{
  [self setImageScaleLabel:nil];
  [self setImageScaleSlider:nil];
  [self setNumbersOnlySwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
