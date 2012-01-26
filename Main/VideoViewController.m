//
//  VideoViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "VideoViewController.h"

#import "Constants.h"
#import "Image.h"

@implementation VideoViewController

@synthesize preview = _preview;
@synthesize tableView = _tableView;
@synthesize session = _session;
@synthesize balanceLabel = _balanceLabel;
@synthesize statusTextView = _statusTextView;
@synthesize versionLabel = _versionLabel;
@synthesize imageOutput = _imageOutput;
@synthesize imageProcessor = _imageProcessor;
@synthesize images = _images;


const int kPollingInterval = 5;
const int kPollingTimeout = 60;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.images = [NSMutableArray array];

    // set up image processor
    self.imageProcessor = [[DbcConnector alloc] init];
    self.imageProcessor.delegate = self;
    [self.imageProcessor connect];
    [self.imageProcessor login];
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
  
  // register custom table view cell
  [self.tableView registerNib:[UINib nibWithNibName:@"ImageCell" bundle:nil] forCellReuseIdentifier:@"ImageCell"];
  
  // update labels and ui controls
  
  self.balanceLabel.text = @"";
  self.statusTextView.text = @"";
  self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  
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
  
  [self.session startRunning];
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
  [self setBalanceLabel:nil];
  [self setStatusTextView:nil];
  [self setVersionLabel:nil];
  [self setTableView:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Actions


- (UIImage *)convertSampleBufferToUIImage:(CMSampleBufferRef)sampleBuffer {
  UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
  image = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:UIImageOrientationRight];
  CGSize previewSize = self.preview.frame.size;
  
  CGFloat scale = image.size.width/previewSize.width;
  CGRect cropRect = CGRectMake(0,
                               image.size.height/2 - previewSize.height/2*scale,
                               image.size.width,
                               previewSize.height*scale);
  image = [self cropImage:image toFrame:cropRect];
  NSLog(@"image size: %.0f x %.0f", image.size.width, image.size.height);
  return image;
}


- (IBAction)takePicture:(id)sender {
  //[self transitionToState:kProcessing];
  
  AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
  [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
    UIImage *image = [self convertSampleBufferToUIImage:sampleBuffer];
          
    NSString *imageId = [self.imageProcessor upload:image];

    Image *img = [[Image alloc] init];
    img.image = image;
    img.imageId = imageId;
    [self.images insertObject:img atIndex:0];
    [img transitionTo:kProcessing];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
      [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    });
    
    [self.imageProcessor pollWithInterval:kPollingInterval timeout:kPollingTimeout forImageId:imageId completionHandler:^{
      [img transitionTo:kIdle];
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];
      });
    }];
  }];
}


#pragma mark - UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  Image *image = [self.images objectAtIndex:indexPath.row];
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ImageCell"];
  { // image view
    UIImageView *subview = (UIImageView *)[cell.contentView viewWithTag:1];
    subview.image = image.image;    
    if (image.state == kProcessing) {
      subview.frame = CGRectMake(20, 20, 240, 60);
    } else {
      CGRect targetFrame = subview.frame;
      targetFrame.size = CGSizeMake(200, 50);
      [UIView animateWithDuration:0.5 animations:^{
        subview.frame = targetFrame;
      }];  
    }
  }
  { // text result label
    UILabel *subview = (UILabel *)[cell.contentView viewWithTag:2];
    if (image.state == kProcessing) {
      subview.alpha = 0;
    } else {
      CGRect targetFrame = subview.frame;
      targetFrame.origin.y = 78;
      [UIView animateWithDuration:0.5 animations:^{
        subview.alpha = 1;
        subview.frame = targetFrame;
      }];
      subview.text = image.textResult;
    }
  }
  { // processing time label
    UILabel *subview = (UILabel *)[cell.contentView viewWithTag:3];
    if (image.state == kProcessing) {
      subview.alpha = 0;
    } else {
      [UIView animateWithDuration:0.5 animations:^{
        subview.alpha = 1;
      }];
      subview.text = [NSString stringWithFormat:@"%.1fs", image.processingTime];
    }
  }
  { // activity indicator
    UIActivityIndicatorView *subview = (UIActivityIndicatorView *)[cell.contentView viewWithTag:4];
    image.state == kIdle ? [subview stopAnimating] : [subview startAnimating];
  }
  { // status icon
    UIImageView *subview = (UIImageView *)[cell.contentView viewWithTag:5];
    if (image.state == kProcessing) {
      subview.alpha = 0;
    } else {
      subview.image = [UIImage imageNamed:@"258-checkmark.png"];
      [UIView animateWithDuration:0.5 animations:^{
        subview.alpha = 1;
      }];
    }
  }
  
  return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.images count];
}


#pragma mark - UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 100;
}


# pragma mark - DbcConnectorDelegate


- (void)addToStatusView:(NSString *)string {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSLog(@"status update: %@", string);
    NSUInteger pos = [self.statusTextView.text length];
    if ([self.statusTextView.text isEqualToString:@""]) {
      self.statusTextView.text = string;
    } else {
      pos += 1;
      self.statusTextView.text = [self.statusTextView.text stringByAppendingFormat:@"\n%@", string];
    }
    NSRange range = NSMakeRange(pos, [string length]);
    [self.statusTextView scrollRangeToVisible:range];
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
  });
  // set result for appropriate image object
  [self.images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    Image *image = (Image *)obj;
    if ([image.imageId isEqualToString:imageId]) {
      image.textResult = result;
      [image transitionTo:kIdle];
      *stop = YES;
    }
  }];
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [self.tableView reloadData];
  });
}


- (void)didUpdateBalance:(float)newBalance {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    self.balanceLabel.text = [NSString stringWithFormat:@"%.1f¢", [self.imageProcessor balance]];
  });
}


- (void)didDisconnectWithError:(NSError *)error {
  NSString *string = [NSString stringWithFormat:@"Disconnected! Error %d: %@", [error code], [error localizedDescription]];
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    if ([error code] == 7) { // remote host closed connection
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Lost" message:@"The remote host closed the connection" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reconnect", nil];
      [alert show];
    } else if (! self.imageProcessor.connected) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Lost" message:@"The connection was lost" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reconnect", nil];
      [alert show];
    } else if (! self.imageProcessor.loggedIn) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logged Out" message:@"The account was logged out" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log In", nil];
      [alert show];
    } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
      [alert show];
    }
    [self addToStatusView:string];
  });
}


#pragma mark - UIAlertViewDelegate


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSLog(@"alert dismissed with buttonIndex: %d", buttonIndex);
  if (buttonIndex == 1) { // reconnect or log in
    if (! self.imageProcessor.connected) {
      [self.imageProcessor connect];
      [self.imageProcessor login];
    } else if (! self.imageProcessor.loggedIn) {
      [self.imageProcessor login];
    }
  }
}


@end
