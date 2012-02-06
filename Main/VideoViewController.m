//
//  VideoViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//


#import <TargetConditionals.h>
#import "VideoViewController.h"

#import "MockImageProcessor.h"
#import "Constants.h"
#import "Image.h"
#import "NSData+MD5.h"


@implementation VideoViewController

@synthesize preview = _preview;
@synthesize tableView = _tableView;
@synthesize session = _session;
@synthesize statusTextView = _statusTextView;
@synthesize versionLabel = _versionLabel;
@synthesize remainingLabel = _remainingLabel;
@synthesize imageOutput = _imageOutput;
@synthesize imageProcessor = _imageProcessor;
@synthesize images = _images;


const int kPollingInterval = 5;
const int kPollingTimeout = 60;

const int kRowHeight = 80;

const CGRect kImageViewFrameIdle         = {{10, 5}, {200, 50}};
const CGRect kImageViewFrameProcessing   = {{10, 7}, {260, 65}};
const CGRect kTextResultFrameIdle        = {{10,61}, {245, 18}};
const CGRect kTextResultFrameProcessing  = {{140,40}, {0, 0}};


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.images = [NSMutableArray array];

    // set up image processor
#ifdef TEST
    self.imageProcessor = [[MockImageProcessor alloc] init];
#else
    self.imageProcessor = [[ImageProcessor alloc] init];
#endif
    self.imageProcessor.delegate = self;
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
  
  self.statusTextView.text = @"";
  self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  self.remainingLabel.text = @"";
  
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

  // other init work
  
  [self.session startRunning];
  [self refreshBalance];
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
  [self setStatusTextView:nil];
  [self setVersionLabel:nil];
  [self setTableView:nil];
  [self setRemainingLabel:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Helpers


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


- (Image *)imageWithId:(NSString *)imageId {
  __block Image *result = nil;
  [self.images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    Image *image = (Image *)obj;
    if ([image.imageId isEqualToString:imageId]) {
      result = image;
      *stop = YES;
    }
  }];
  return result;
}


- (void)configureImageView:(UIImageView *)view withImage:(Image *)image {
  view.image = image.image;
}


- (void)configureTextResultLabel:(UILabel *)label withImage:(Image *)image {
  if (image.state == kTimeout) {
    label.text = @"timeout";
    label.font = [UIFont italicSystemFontOfSize:14];
  } else {
    label.text = image.textResult;
    label.font = [UIFont systemFontOfSize:14];
  }
}


- (void)configureProcessingTimeLabel:(UILabel *)label withImage:(Image *)image {
  if (image.state == kProcessing) {
    label.text = @"";
  } else {
    label.text = [NSString stringWithFormat:@"%.1fs", image.processingTime];
  }
}


- (void)configureActivityIndicatorView:(UIActivityIndicatorView *)view withImage:(Image *)image {
  (image.state == kProcessing) ? [view startAnimating] : [view stopAnimating];
}


- (void)configureStatusIconView:(UIButton *)iconView withImage:(Image *)image {
  if (image.state == kProcessing) {
    [iconView removeTarget:self action:@selector(refreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  } else {
    if (image.textResult == nil || [image.textResult isEqualToString:@""]) {
      [iconView setImage:[UIImage imageNamed:@"01-refresh.png"] forState:UIControlStateNormal];
      [iconView addTarget:self action:@selector(refreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
      [iconView setImage:[UIImage imageNamed:@"258-checkmark.png"] forState:UIControlStateNormal];
    }
  }
}


- (void)transitionCell:(UITableViewCell *)cell toState:(ImageState)newState animate:(BOOL)animate {
  NSTimeInterval duration = 0;
  if (animate) {
    duration = 0.5;
  }
  { // image view
    UIView *view = [cell.contentView viewWithTag:1];
    if (newState == kProcessing) {
      [UIView animateWithDuration:duration animations:^{
        view.frame = kImageViewFrameProcessing;
      }];
    } else {
      [UIView animateWithDuration:duration animations:^{
        view.frame = kImageViewFrameIdle;
      }];
    }
  }
  { // text result label
    UIView *view = [cell.contentView viewWithTag:2];
    if (newState == kProcessing) {
      [UIView animateWithDuration:duration animations:^{
        view.alpha = 0;
        view.frame = kTextResultFrameProcessing;
      }];
    } else {
      [UIView animateWithDuration:duration animations:^{
        view.alpha = 1;
        view.frame = kTextResultFrameIdle;
      }];
    }
  }
  { // processing time label
    UIView *view = [cell.contentView viewWithTag:3];
    if (newState == kProcessing) {
      [UIView animateWithDuration:duration animations:^{
        view.alpha = 0;
      }];
    } else {
      [UIView animateWithDuration:duration animations:^{
        view.alpha = 1;
      }];
    }
  }
  { // activity indicator
    UIView *view = [cell.contentView viewWithTag:4];
    view.hidden = (newState != kProcessing);
  }
  { // status icon
    UIView *view = [cell.contentView viewWithTag:5];
    if (newState == kProcessing) {
      view.alpha = 0;
    } else {
      [UIView animateWithDuration:duration animations:^{
        view.alpha = 1;
      }];
    }
  }
}


- (Image *)imageForView:(UIView *)view {
  if (! [view isKindOfClass:[UITableViewCell class]]) {
    // walk up the view hierarchy until we find a table view cell
    return [self imageForView:[view superview]];
  } else {
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Image *image = [self.images objectAtIndex:indexPath.row];
    return image;
  }
}


- (UITableViewCell *)cellForImage:(Image *)image {
  NSUInteger index = [self.images indexOfObject:image];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  return cell;
}


- (void)startProcessingImage:(Image *)image {
  [image transitionTo:kProcessing];
  [self.imageProcessor upload:image.image];
}


- (void)addImage:(UIImage *)sampleImage {
  NSData *imageData = UIImagePNGRepresentation(sampleImage);
  
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    Image *image = [[Image alloc] init];
    image.image = sampleImage;
    image.imageId = [imageData MD5];
    [self.images insertObject:image atIndex:0];
    
    [self startProcessingImage:image];
    
    // we don't want new images to animate into position
    image.isInTransition = NO;
    NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
  });
}


#pragma mark - Actions


- (IBAction)takePicture:(id)sender {
#if !(TARGET_IPHONE_SIMULATOR)
  AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
  [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
    UIImage *image = [self convertSampleBufferToUIImage:sampleBuffer];
    [self addImage:image];
  }];
#else
  UIImage *image = [UIImage imageNamed:@"test222.tif"];
  [self addImage:image];
#endif
}


- (void)refreshButtonPressed:(id)sender {
  [sender removeTarget:self action:@selector(refreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

  Image *image = [self imageForView:sender];
  NSLog(@"Refresh started for image: %@", image.imageId);
  [self startProcessingImage:image];
  
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [self.tableView reloadData];
  });
}


- (void)refreshBalance {
  [self.imageProcessor refreshBalance];
}


#pragma mark - UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  Image *image = [self.images objectAtIndex:indexPath.row];
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ImageCell"];
  
  if (image.isInTransition) {
    [self transitionCell:cell toState:image.state animate:YES];
    image.isInTransition = NO;
  } else {
    [self transitionCell:cell toState:image.state animate:NO];
  }

  [self configureImageView:(UIImageView *)[cell.contentView viewWithTag:1] withImage:image];
  [self configureTextResultLabel:(UILabel *)[cell.contentView viewWithTag:2] withImage:image];
  [self configureProcessingTimeLabel:(UILabel *)[cell.contentView viewWithTag:3] withImage:image];
  [self configureActivityIndicatorView:(UIActivityIndicatorView *)[cell.contentView viewWithTag:4] withImage:image];
  [self configureStatusIconView:(UIButton *)[cell.contentView viewWithTag:5] withImage:image];
  
  return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.images count];
}


#pragma mark - UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kRowHeight;
}


# pragma mark - ImageProcessorDelegate


- (void)didDecodeImageId:(NSString *)imageId result:(NSString *)result {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSString *string = [NSString stringWithFormat:@"Received text '%@' for id: %@", result, imageId];
    [self addToStatusView:string];
  });

  // set result for appropriate image object
  Image *image = [self imageWithId:imageId];
  image.textResult = result;
  [image transitionTo:kIdle];
  
  [self refreshBalance];

  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [self.tableView reloadData];
  });
}


- (void)didTimeoutDecodingImageId:(NSString *)imageId {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    NSString *string = [NSString stringWithFormat:@"Timeout while decoding: %@", imageId];
    [self addToStatusView:string];
  });

  Image *image = [self imageWithId:imageId];
  [image transitionTo:kTimeout];
  
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    [self.tableView reloadData];
  });
}


- (void)didRefreshBalance:(NSNumber *)balance rate:(NSNumber *)rate {
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    if (balance != nil && rate != nil && [rate floatValue] != 0.0 ) {
      NSUInteger remaining = round([balance floatValue]/[rate floatValue]);
      self.remainingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d remaining", @"remaining label"), remaining];
    }
  });
}


@end
