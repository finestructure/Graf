//
//  ViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 02.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ViewController.h"

#import "MBProgressHUD.h"
#import "OverlayView.h"
#import "UIImage+Resize.h"

#include "baseapi.h"

#include "environ.h"
#import "pix.h"


@implementation ViewController

@synthesize imageView = _imageView;
@synthesize progressHud = _progressHud;


#pragma mark - Actions

- (IBAction)takePicture:(id)sender {
  UIImagePickerController *vc = [[UIImagePickerController alloc] init];
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    [vc setSourceType:UIImagePickerControllerSourceTypeCamera];
    CGFloat inset = 5;
    CGFloat yOffset = 100;
    CGFloat width = vc.view.frame.size.width - 2*inset;
    CGFloat height = 80;
    OverlayView *overlay = [[OverlayView alloc] initWithFrame:CGRectMake(inset, yOffset, width, height)];
    vc.cameraOverlayView = overlay;
  } else {
    [vc setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
  }
  vc.delegate = self;
  [self presentModalViewController:vc animated:YES];
}


#pragma mark - UIImagePickerControllerDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {  
  [self dismissModalViewControllerAnimated:YES];
  
  UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
  CGFloat newWidth = image.size.width/3;
  image = [self resizeImage:image toWidth:newWidth];
  
  // resize to overlay frame
  CGRect frame = picker.cameraOverlayView.frame;
  CGFloat scale = image.size.width/(frame.size.width +2*frame.origin.x);
  CGRect cropRect = CGRectMake(frame.origin.x*scale, frame.origin.y*scale, frame.size.width*scale, frame.size.height*scale);
  UIImage *croppedImage = [self cropImage:image toFrame:cropRect];
  NSLog(@"final image size: (%f, %f)", croppedImage.size.width, croppedImage.size.height);
  
  self.imageView.image = croppedImage;
  
  self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
  self.progressHud.labelText = @"Processing OCR";
  
  [self.view addSubview:self.progressHud];
  //[self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:croppedImage animated:YES];
}


#pragma mark - Helpers


- (UIImage *)cropImage:(UIImage *)image toFrame:(CGRect)rect {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.);
  [image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)
           blendMode:kCGBlendModeCopy
               alpha:1.];
  UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return croppedImage;
}


- (UIImage *)resizeImage:(UIImage *)img toWidth:(CGFloat)width {
  CGFloat aspectRatio = img.size.height/img.size.width;
  UIImage *resizedImage = [img resizedImage:CGSizeMake(width, width*aspectRatio) interpolationQuality:kCGInterpolationDefault];
  return resizedImage;
}


#pragma mark - View lifecycle


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Set up the tessdata path. This is included in the application bundle
    // but is copied to the Documents directory on the first run.
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:dataPath]) {
      // get the path to the app bundle (with the tessdata dir)
      NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
      NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
      if (tessdataPath) {
        [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
      }
    }
    
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
    
    // init the tesseract engine.
    tesseract = new tesseract::TessBaseAPI();
    tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
    tesseract->SetVariable("tessedit_char_whitelist", "0123456789");
  }
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
  [self setImageView:nil];
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
