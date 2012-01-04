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
@synthesize textView = _textView;
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
  CGFloat newWidth = image.size.width/4;
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
  [self.progressHud showWhileExecuting:@selector(processImage:) onTarget:self withObject:croppedImage animated:YES];
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


- (void)processImage:(UIImage *)image
{
  [self setTesseractImage:image];
  
  tesseract->Recognize(NULL);
  char* utf8Text = tesseract->GetUTF8Text();
  
  [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                         withObject:[NSString stringWithUTF8String:utf8Text]
                      waitUntilDone:NO];
  delete [] utf8Text;
}


- (void)ocrProcessingFinished:(NSString *)result
{
  NSLog(@"result:\n%@", result);
  self.textView.text = result;
  free(pixels);
  pixels = NULL;
}



- (void)setTesseractImage:(UIImage *)image
{
  free(pixels);
  pixels = NULL;
  
  CGSize size = [image size];
  int width = size.width;
  int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
  // the pixels will be painted to this array
  pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
  // clear the pixels so any transparency is preserved
  memset(pixels, 0, width * height * sizeof(uint32_t));
	
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
  // create a context with RGBA pixels
  CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, 
                                               kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
  // paint the bitmap to our context which will fill in the pixels array
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
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
    //tesseract->SetVariable("tessedit_char_whitelist", "0123456789");
  }
  return self;
}


- (void)viewDidUnload
{
  [self setImageView:nil];
  
  if (![self.progressHud isHidden]) {
    [self.progressHud hide:NO];
  }
  self.progressHud = nil;

  [self setTextView:nil];
  [super viewDidUnload];
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
