//
//  VideoViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "VideoViewController.h"

#import "Constants.h"
#import "MBProgressHUD.h"

@implementation VideoViewController

@synthesize preview = _preview;
@synthesize session = _session;
@synthesize imageSizeLabel = _imageSizeLabel;
@synthesize textResultView = _textResultView;
@synthesize processingTimeLabel = _processingTimeLabel;
@synthesize snapshotPreview = _snapshotPreview;
@synthesize balanceLabel = _balanceLabel;
@synthesize imageIdLabel = _imageIdLabel;
@synthesize statusTextView = _statusTextView;
@synthesize imageOutput = _imageOutput;
@synthesize imageProcessor = _imageProcessor;


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


- (AVCaptureSession *)createSession {
  AVCaptureSession *session = [[AVCaptureSession alloc] init];
  session.sessionPreset = AVCaptureSessionPresetMedium;
  
  // set up device
  
  AVCaptureDevice *device =
  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  NSError *error = nil;
  AVCaptureDeviceInput *input =
  [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
  if (!input) {
    NSLog(@"error setting up video device");
    return nil;
  }
  [session addInput:input];
  
  return session;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // set up image processor
  self.imageProcessor = [[DbcConnector alloc] init];
  self.imageProcessor.delegate = self;
  [self.imageProcessor connect];
  [self.imageProcessor login];
  
  // update labels and ui controls
  
  self.imageSizeLabel.text = @"";
  self.textResultView.text = @"";
  self.processingTimeLabel.text = @"";
  self.balanceLabel.text = @"";
  self.imageIdLabel.text = @"";
  self.statusTextView.text = @"";
  
  // session init
  
  self.session = [self createSession];
  
  // set up output
  
  self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
  self.imageOutput.outputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  [self.session addOutput:self.imageOutput];
  
  // set up preview
  
  AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
  CGRect bounds = self.preview.layer.bounds;
  captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  captureVideoPreviewLayer.bounds = bounds;
  captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
  [self.preview.layer addSublayer:captureVideoPreviewLayer];

  // start session
  
  [self startSession];
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


- (UIImage *)cropImage:(UIImage *)image toFrame:(CGRect)rect {
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.);
  [image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)
           blendMode:kCGBlendModeCopy
               alpha:1.];
  UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return croppedImage;
}


- (void)viewDidUnload
{
  [self setPreview:nil];
  self.session = nil;
  [self setImageSizeLabel:nil];
  [self setTextResultView:nil];
  [self setProcessingTimeLabel:nil];
  [self setSnapshotPreview:nil];
  [self setBalanceLabel:nil];
  [self setImageIdLabel:nil];
  [self setStatusTextView:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Actions


- (void)updateHud:(NSTimer *)timer {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSLog(@"timer fired");
    NSDate *start = [[timer userInfo] objectForKey:@"start"];
    MBProgressHUD *progressHud = [[timer userInfo] objectForKey:@"progressHud"];
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
    NSLog(@"updating label: %.0fs", elapsed);
    progressHud.labelText = [NSString stringWithFormat:@"Blah OCR (%.0fs)", elapsed];
  });
}


- (IBAction)takePicture:(id)sender {
  NSDate *start = [NSDate date];
  MBProgressHUD *progressHud = [MBProgressHUD showHUDAddedTo:self.textResultView animated:YES];
  self.imageIdLabel.text = @"";
  self.textResultView.text = @"";
  self.processingTimeLabel.text = @"";
  
  // timer for ui update
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);  
  dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                  queue);
  dispatch_source_set_timer(_timer,
                            dispatch_time(DISPATCH_TIME_NOW, 0),
                            1*NSEC_PER_SEC, 0);
  dispatch_source_set_event_handler(_timer, ^{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:start];
      NSLog(@"updating label: %.0fs", elapsed);
      progressHud.labelText = [NSString stringWithFormat:@"Decoding (%.0fs)", elapsed];
    });
  });
  dispatch_resume(_timer);

  
  AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
  [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:UIImageOrientationRight];
    CGSize previewSize = self.preview.frame.size;
    
    CGFloat scale = image.size.width/previewSize.width;
    CGRect cropRect = CGRectMake(0,
                                 image.size.height/2 - previewSize.height/2*scale,
                                 image.size.width,
                                 previewSize.height*scale);
    image = [self cropImage:image toFrame:cropRect];
          
    // update UI elements on main thread
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      self.snapshotPreview.image = image;
    });
    
    NSString *imageId = [self.imageProcessor upload:image];
    
    // update UI elements on main thread
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      self.imageSizeLabel.text = [NSString stringWithFormat:@"%.0f x %.0f", image.size.width, image.size.height];
      self.imageIdLabel.text = imageId;
      // update processing time label
      NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
      NSLog(@"duration: %f", duration);      
      self.processingTimeLabel.text = [NSString stringWithFormat:@"%.0f s", duration];
      [progressHud hide:YES];
      // clean up timer
      dispatch_source_cancel(_timer);
      dispatch_release(_timer);
    });
  }];
}


- (void)startSession {
  [self.session startRunning];
}


- (void)stopSession {
  [self.session stopRunning];
}


# pragma mark - DbcConnectorDelegate


- (void)addToStatusView:(NSString *)string {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSLog(@"status update: %@", string);
    if ([self.statusTextView.text isEqualToString:@""]) {
      self.statusTextView.text = string;
    } else {
      self.statusTextView.text = [self.statusTextView.text stringByAppendingFormat:@"\n%@", string];
    }
  });
}


- (void)didConnectToHost:(NSString *)host port:(UInt16)port {
  NSString *string = [NSString stringWithFormat:@"Connected to %@:%d", host, port];
  [self addToStatusView:string];
}


- (void)didLogInAs:(NSString *)user {
  NSString *string = [NSString stringWithFormat:@"Logged in as: %@", user];
  [self addToStatusView:string];
  self.balanceLabel.text = [NSString stringWithFormat:@"%.1f¢", [self.imageProcessor balance]];
}


- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSString *string = [NSString stringWithFormat:@"Received text '%@' for id: %@", result, imageId];
    [self addToStatusView:string];
    self.balanceLabel.text = [NSString stringWithFormat:@"%.1f¢", [self.imageProcessor balance]];
    self.textResultView.text = result;
  });
}


- (void)didDisconnectWithError:(NSError *)error {
  NSString *string = [NSString stringWithFormat:@"Disconnected! Error: %@", error];
  [self addToStatusView:string];
}


@end
