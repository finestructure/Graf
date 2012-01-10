//
//  VideoViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "VideoViewController.h"

#import "SettingsViewController.h"

@implementation VideoViewController

@synthesize preview = _preview;
@synthesize session = _session;
@synthesize imageProcessor = _imageProcessor;
@synthesize pageModeNames = _pageModeNames;
@synthesize pageModeValues = _pageModeValues;
@synthesize snapShotView = _snapShotView;
@synthesize imageSizeLabel = _imageSizeLabel;
@synthesize textResultView = _textResultView;
@synthesize numbersOnlySwitch = _numbersOnlySwitch;
@synthesize pageModeSlider = _pageModeSlider;
@synthesize pageModeLabel = _pageModeLabel;
@synthesize runOcrSwitch = _runOcrSwitch;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.pageModeNames = [NSArray arrayWithObjects:
                        @"osd only", // 0
                        @"auto osd", // 1
                        @"auto only", // 2
                        @"auto", // 3
                        @"single column", // 4
                        @"single col vert text", // 5
                        @"single line", // 6
                        @"single word", // 7
                        nil];
  self.pageModeValues = [NSArray arrayWithObjects:
                         [NSNumber numberWithInt:0],
                         [NSNumber numberWithInt:1],
                         [NSNumber numberWithInt:2],
                         [NSNumber numberWithInt:3],
                         [NSNumber numberWithInt:4],
                         [NSNumber numberWithInt:5],
                         [NSNumber numberWithInt:6],
                         [NSNumber numberWithInt:7],
                         nil];
  self.pageModeSlider.minimumValue = 0;
  self.pageModeSlider.maximumValue = [[self.pageModeValues lastObject] floatValue];

  // update labels and ui controls
  
  self.imageSizeLabel.text = @"";
  self.textResultView.text = @"";
  
  NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
  
  NSNumber *numbersOnly = [def valueForKey:kNumbersOnlyDefault];
  self.numbersOnlySwitch.on = [numbersOnly boolValue];
  
  NSNumber *pageMode = [def valueForKey:kPageModeDefault];
  NSUInteger pageModeIndex = [self.pageModeValues indexOfObject:pageMode];
  if (pageModeIndex == NSNotFound) {
    pageModeIndex = 0;
  }
  self.pageModeSlider.value = pageModeIndex;
  
  self.pageModeLabel.text = [self.pageModeNames objectAtIndex:pageModeIndex];
  
  [self.numbersOnlySwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
  [self.pageModeSlider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];

  
  // create image processor
  self.imageProcessor = [[ImageProcessor alloc] init];
  
  // session init
  
  self.session = [[AVCaptureSession alloc] init];
  self.session.sessionPreset = AVCaptureSessionPresetMedium;
  
  // set up device
  
  AVCaptureDevice *device =
  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  NSError *error = nil;
  AVCaptureDeviceInput *input =
  [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
  if (!input) {
    NSLog(@"error setting up video device");
    return;
  }
  [self.session addInput:input];

  // set up data output
  
  AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
  output.alwaysDiscardsLateVideoFrames = YES;
  output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  [self.session addOutput:output];

  // set up handler queue
  
  dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
  [output setSampleBufferDelegate:self queue:queue];
  dispatch_release(queue);
  
  // set up preview
  
  AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
  CGRect bounds = self.preview.layer.bounds;
  captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  captureVideoPreviewLayer.bounds = bounds;
  captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
  [self.preview.layer addSublayer:captureVideoPreviewLayer];

  // start session
  
  NSLog(@"starting ocr");
  [self.session startRunning];
  self.runOcrSwitch.on = YES;
}


- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  // Lock the base address of the pixel buffer.
  CVPixelBufferLockBaseAddress(imageBuffer,0);
  
  // Get the number of bytes per row for the pixel buffer.
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  // Get the pixel buffer width and height.
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  NSLog(@"sample buffer: %d x %d (%d)", (int)width, (int)height, (int)bytesPerRow);
  
  // Create a device-dependent RGB color space.
  static CGColorSpaceRef colorSpace = NULL;
  if (colorSpace == NULL) {
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
      // Handle the error appropriately.
      return nil;
    }
  }
  
  // Get the base address of the pixel buffer.
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
  // Get the data size for contiguous planes of the pixel buffer.
  size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
  
  // Create a Quartz direct-access data provider that uses data we supply.
  CGDataProviderRef dataProvider =
  CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
  // Create a bitmap image from data supplied by the data provider.
  CGImageRef cgImage =
  CGImageCreate(width, height, 8, 32, bytesPerRow,
                colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                dataProvider, NULL, true, kCGRenderingIntentDefault);
  CGDataProviderRelease(dataProvider);
  
  // Create and return an image object to represent the Quartz image.
  UIImage *image = [UIImage imageWithCGImage:cgImage];
  CGImageRelease(cgImage);
  
  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
  
  return image;
}



- (UIImage *)_imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer 
{
  // Get a CMSampleBuffer's Core Video image buffer for the media data
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
  // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0); 
  
  // Get the number of bytes per row for the pixel buffer
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
  
  // Get the number of bytes per row for the pixel buffer
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
  // Get the pixel buffer width and height
  size_t width = CVPixelBufferGetWidth(imageBuffer); 
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  
  // Create a device-dependent RGB color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
  
  // Create a bitmap graphics context with the sample buffer data
  CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
                                               bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  
  // Free up the context and color space
  CGContextRelease(context); 
  CGColorSpaceRelease(colorSpace);
  
  // Create an image object from the Quartz image
  UIImage *image = [UIImage imageWithCGImage:quartzImage];
  
  // Release the Quartz image
  CGImageRelease(quartzImage);
  
  return (image);
}


- (UIImage *)cropImage:(UIImage *)image toFrame:(CGRect)rect {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.);
  [image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)
           blendMode:kCGBlendModeCopy
               alpha:1.];
  UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return croppedImage;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
  UIImage *image = [self _imageFromSampleBuffer:sampleBuffer];
  image = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationRight];
  CGSize previewSize = self.preview.frame.size;
  
  CGFloat scale = image.size.width/previewSize.width;
  CGRect cropRect = CGRectMake(0,
                               image.size.height/2 - previewSize.height/2*scale,
                               image.size.width,
                               previewSize.height*scale);
  image = [self cropImage:image toFrame:cropRect];
  
  NSString *result = [self.imageProcessor processImage:image];
  //NSLog(@"%@ ocr: %@", [NSDate date], result);

  // update UI elements on main thread
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    self.imageSizeLabel.text = [NSString stringWithFormat:@"%.0f x %.0f", image.size.width, image.size.height];
    self.textResultView.text = result;
    self.snapShotView.image = image;
  });
}


- (void)viewDidUnload
{
  [self setPreview:nil];
  self.session = nil;
  [self setSnapShotView:nil];
  [self setImageSizeLabel:nil];
  [self setTextResultView:nil];
  [self setNumbersOnlySwitch:nil];
  [self setPageModeSlider:nil];
  [self setPageModeLabel:nil];
  [self setRunOcrSwitch:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Actions


- (IBAction)done:(id)sender {
  NSLog(@"stopping ocr");
  [self.session stopRunning];
  self.runOcrSwitch.on = NO;
  [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)valueChanged:(id)sender {
  if (sender == self.runOcrSwitch) {
    if (self.runOcrSwitch.on) {
      NSLog(@"starting ocr");
      [self.session startRunning];
    } else {
      NSLog(@"stopping ocr");
      [self.session stopRunning];
    }
  } else if (sender == self.pageModeSlider) {
    NSNumber *sliderValue = [NSNumber numberWithInt:(int)self.pageModeSlider.value];
    NSNumber *pageModeValue = [self.pageModeValues objectAtIndex:[sliderValue intValue]];
    [[NSUserDefaults standardUserDefaults] setValue:pageModeValue forKey:kPageModeDefault];
    self.pageModeLabel.text = [self.pageModeNames objectAtIndex:[sliderValue intValue]];
  } else if (sender == self.numbersOnlySwitch) {
    NSNumber *value = [NSNumber numberWithBool:self.numbersOnlySwitch.on];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kNumbersOnlyDefault];
  }
  self.imageProcessor = [[ImageProcessor alloc] init];
}


@end
