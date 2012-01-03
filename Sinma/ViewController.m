//
//  ViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 02.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController


#pragma mark - Actions

- (IBAction)takePicture:(id)sender {
  UIImagePickerController *vc = [[UIImagePickerController alloc] init];
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
//    CGFloat inset = 5;
//    CGFloat yOffset = 100;
//    CGFloat width = vc.view.frame.size.width - 2*inset;
//    CGFloat height = 80;
//    OverlayView *overlay = [[OverlayView alloc] initWithFrame:CGRectMake(inset, yOffset, width, height)];
//    vc.cameraOverlayView = overlay;
  } else {
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
  }
  vc.delegate = self;
  [self presentModalViewController:vc animated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - Other

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

@end
