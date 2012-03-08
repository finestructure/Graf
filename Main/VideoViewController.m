//
//  VideoViewController.m
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//


#import <TargetConditionals.h>
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchTouchDBServer.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>

#import "VideoViewController.h"

#import "ConfigViewController.h"
#import "Configuration.h"
#import "Constants.h"
#import "ImageCell.h"
#import "NSData+MD5.h"
#import "Image.h"
#import "VideoViewController+Helpers.h"


@implementation VideoViewController

@synthesize preview = _preview;
@synthesize tableView = _tableView;
@synthesize dataSource = _dataSource;
@synthesize session = _session;
@synthesize statusTextView = _statusTextView;
@synthesize versionLabel = _versionLabel;
@synthesize remainingLabel = _remainingLabel;
@synthesize imageOutput = _imageOutput;
@synthesize database = _database;


const int kPollingInterval = 5;
const int kPollingTimeout = 60;

const int kRowHeight = 80;

const CGRect kImageViewFrameIdle         = {{10, 5}, {200, 50}};
const CGRect kImageViewFrameProcessing   = {{10, 7}, {260, 65}};
const CGRect kTextResultFrameIdle        = {{10,61}, {245, 18}};
const CGRect kTextResultFrameProcessing  = {{140,40}, {0, 0}};

NSString * const kDatabaseName = @"graf";


//#define TEST

#pragma mark - Initialization


- (void)setupDataSource {
  self.dataSource = [[CouchUITableSource alloc] init];
  
  // Create a 'view' containing list items sorted by date:
  CouchDesignDocument* design = [self.database designDocumentWithName: @"default"];
  [design defineViewNamed: @"byDate" 
                 mapBlock: ^(NSDictionary* doc, void (^emit)(id key, id value)) {
                   id date = [doc objectForKey: @"created_at"];
                   if (date) {
                     id _id = [doc objectForKey:@"_id"];
                     emit([NSArray arrayWithObjects:date, _id, nil], doc);
                   }
                 } 
                  version: @"2.0"];
  
  // and a validation function requiring parseable dates:
  design.validationBlock = ^BOOL(TDRevision* newRevision, id<TDValidationContext> context) {
    if (newRevision.deleted)
      return YES;
    id date = [newRevision.properties objectForKey: @"created_at"];
    if (date && ! [RESTBody dateWithJSONObject: date]) {
      context.errorMessage = [@"invalid date " stringByAppendingString: date];
      return NO;
    }
    return YES;
  };

  // Create a query sorted by descending date, i.e. newest items first:
  CouchLiveQuery* query = [[[self.database designDocumentWithName: @"default"]
                            queryViewNamed: @"byDate"] asLiveQuery];
  query.descending = YES;
  self.dataSource.query = query;  
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    gCouchLogLevel = 0;

    // register db credentials
    NSURLCredential* cred;
    cred = [NSURLCredential credentialWithUser: @"graf"
                                      password: @"BaumHinkelstein"
                                   persistence: NSURLCredentialPersistencePermanent];
    NSURLProtectionSpace* space;
    space = [[NSURLProtectionSpace alloc] initWithHost: @"graf.abstracture.de"
                                                   port: 443
                                               protocol: @"https"
                                                  realm: @"Graf"
                                   authenticationMethod: NSURLAuthenticationMethodDefault];
    [[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential: cred
                                                        forProtectionSpace: space];
    
    // register user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Configuration *defaultConf = [[Constants sharedInstance] defaultConfiguration];
    NSDictionary *appdefaults = [NSDictionary dictionaryWithObject:defaultConf.name forKey:kConfigurationDefaultsKey];
    [defaults registerDefaults:appdefaults];
    [defaults synchronize];
    
    // set up touchdb
    CouchTouchDBServer *server = [CouchTouchDBServer sharedInstance];
    if (server.error) {
      [self failedWithError:server.error];
    }
    self.database = [server databaseNamed: kDatabaseName];
    NSError *error;
    if (![self.database ensureCreated:&error]) {
      [self failedWithError:error];
    }
    [self setupDataSource];
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
#ifdef TEST
  NSString *prefix = @"TEST-";
#else
  NSString *prefix = @"";
#endif
  self.versionLabel.text = [NSString stringWithFormat:@"%@%@", prefix, [[Constants sharedInstance] version]];
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

  // connect table view and data source
  
  self.dataSource.tableView = self.tableView;
  self.tableView.dataSource = self.dataSource;
  
  // other init work
  
  [self.session startRunning];
  [self updateSyncURL];
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
  [self.dataSource.rows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    Image *image = (Image *)obj;
    if ([image.image_id isEqualToString:imageId]) {
      result = image;
      *stop = YES;
    }
  }];
  return result;
}


- (void)configureImageView:(UIImageView *)view withImage:(Image *)image {
  view.image = image.image;
}


- (void)configureTextResultLabel:(UILabel *)label withImage:(Image *)image
{
  if ([image.state isEqualToString:kImageStateNew] ||
      [image.state isEqualToString:kImageStateProcessing]) {
    label.superview.hidden = YES;
  } else if ([image.state isEqualToString:kImageStateTimeout]) {
    label.text = @"timeout";
    label.font = [UIFont italicSystemFontOfSize:14];
    label.superview.hidden = NO;
  } else {
    if (image.text_result != nil && ! [image.text_result isEqual:[NSNull null]]) {
      label.text = image.text_result;
      label.font = [UIFont systemFontOfSize:14];
      label.superview.hidden = NO;
    } else {
      label.superview.hidden = YES;
    }
  }
}


- (void)configureProcessingTimeLabel:(UILabel *)label withImage:(Image *)image
{
  if ([image.state isEqualToString:kImageStateNew] ||
      [image.state isEqualToString:kImageStateProcessing]) {
    label.text = @"";
  } else {
    label.text = [NSString stringWithFormat:@"%.1fs", [image.processing_time floatValue]];
  }
}


- (void)configureActivityIndicatorView:(UIActivityIndicatorView *)view withImage:(Image *)image
{
  ([image.state isEqualToString:kImageStateProcessing]) ? [view startAnimating] : [view stopAnimating];
}


- (void)configureStatusIconView:(UIButton *)iconView withImage:(Image *)image
{
  if ([image.state isEqualToString:kImageStateNew] ||
      [image.state isEqualToString:kImageStateProcessing]) {
    [iconView removeTarget:self action:@selector(cellRefreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    iconView.hidden = YES;
  } else {
    iconView.hidden = NO;
    if (image.text_result == nil ||
        [image.text_result isEqual:[NSNull null]] ||
        [image.text_result isEqualToString:@""]) {
      [iconView setImage:[UIImage imageNamed:@"01-refresh.png"] forState:UIControlStateNormal];
      [iconView addTarget:self action:@selector(cellRefreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    } else {
      [iconView setImage:[UIImage imageNamed:@"258-checkmark.png"] forState:UIControlStateNormal];
    }
  }
}


- (CouchDocument *)documentForIndexPath:(NSIndexPath *)indexPath
{
  CouchQueryRow *row = [self.dataSource rowAtIndex:indexPath.row];
  CouchDocument *doc = [row document];
  return doc;
}


- (Image *)imageForIndexPath:(NSIndexPath *)indexPath
{
  CouchDocument *doc = [self documentForIndexPath:indexPath];
  Image *image = [Image modelForDocument:doc];
  return image;
}


- (Image *)imageForView:(UIView *)view
{
  if (! [view isKindOfClass:[UITableViewCell class]]) {
    // walk up the view hierarchy until we find a table view cell
    return [self imageForView:[view superview]];
  } else {
    UITableViewCell *cell = (UITableViewCell *)view;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Image *image = [self imageForIndexPath:indexPath];
    return image;
  }
}


- (UITableViewCell *)cellForModel:(Image *)image {
  NSIndexPath *indexPath = [self.dataSource indexPathForDocument:image.document];
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
  return cell;
}


- (void)updateCouchImageId:(NSString *)imageId result:(NSString *)result {
  CouchDocument *doc = [self.database documentWithID:imageId];
  NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:doc.properties];
  [props setValue:result forKey:@"text_result"];
  RESTOperation* op = [doc putProperties:props];
  [op onCompletion: ^{
    if (op.error) {
      [self failedWithError:op.error];
    }
	}];
  [op start];
}


- (void)addImage:(UIImage *)image {  
  Image *doc = [[Image alloc] initWithImage:image inDatabase:self.database];
  RESTOperation* op = [doc save];
  [op onCompletion: ^{
    if (op.error) {
      [self failedWithError:op.error];
    }
    [self.dataSource.query start];
  }];
  [op start];
}


- (void)imageCellGestureRecognizerHandler:(UILongPressGestureRecognizer *)recognizer {	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		UIView *cell = recognizer.view;
    [cell becomeFirstResponder];
		Image *image = [self imageForView:cell];
    NSString *imageId = image.image_id;
    UIMenuItem *imageIdMenu = [[UIMenuItem alloc] initWithTitle:imageId action:@selector(imageIdMenu:)];
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
		[menu setMenuItems:[NSArray arrayWithObject:imageIdMenu]];
		[menu setTargetRect:cell.frame inView:cell.superview];
    [menu setMenuVisible:YES animated:YES];
	}
}

- (void)imageIdMenu:(id)sender {
	NSLog(@"Cell was flagged");
}


- (void)failedWithError:(NSError *)error {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"General error dialog title") message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [alert show];
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

  // save couchdb document
    
}


- (IBAction)configButtonPressed:(id)sender {
  ConfigViewController *vc = [[ConfigViewController alloc] initWithNibName:@"ConfigViewController" bundle:nil];
  [self presentViewController:vc animated:YES completion:NULL];
}


- (void)cellRefreshButtonPressed:(id)sender {
  [sender removeTarget:self action:@selector(cellRefreshButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  Image *image = [self imageForView:sender];
  image.state = kImageStateIdle;
  image.processed = nil;
  RESTOperation* op = [image save];
  [op onCompletion: ^{
    if (op.error) {
      [self failedWithError:op.error];
    }
    [self.dataSource.query start];
  }];
  [op start];
}


#pragma mark - CouchUITableDelegate


- (UITableViewCell *)couchTableSource:(CouchUITableSource*)source cellForRowAtIndexPath:(NSIndexPath *)indexPath; {
  Image *image = [self imageForIndexPath:indexPath];
  
  ImageCell *cell = (ImageCell *)[self.tableView dequeueReusableCellWithIdentifier:@"ImageCell"];
  [cell addRecognizerWithTarget:self action:@selector(imageCellGestureRecognizerHandler:)];
  
//  if (image.isInTransition) {
//    [self transitionCell:cell toState:image.state animate:YES];
//    image.isInTransition = NO;
//  } else {
//    [self transitionCell:cell toState:image.state animate:NO];
//  }

  [self configureImageView:(UIImageView *)[cell.contentView viewWithTag:1] withImage:image];
  [self configureTextResultLabel:(UILabel *)[cell.contentView viewWithTag:2] withImage:image];
  [self configureProcessingTimeLabel:(UILabel *)[cell.contentView viewWithTag:3] withImage:image];
  [self configureActivityIndicatorView:(UIActivityIndicatorView *)[cell.contentView viewWithTag:4] withImage:image];
  [self configureStatusIconView:(UIButton *)[cell.contentView viewWithTag:5] withImage:image];
  
  return cell;
}


- (void)couchTableSource:(CouchUITableSource*)source updateFromQuery:(CouchLiveQuery*)query previousRows:(NSArray *)oldRows
{
  BOOL (^isModified)(id, id) = ^ BOOL (id oldObj, id newObj) {
    return ! [[oldObj documentRevision] isEqualToString:[newObj documentRevision]];
  };
  BOOL (^isNewToProcessingStateTransition)(id, id) = ^ BOOL (id oldObj, id newObj) {
    CouchQueryRow *oldRow = oldObj;
    CouchQueryRow *newRow = newObj;
    if ([[oldRow.value objectForKey:@"state"] isEqualToString:kImageStateNew] &&
        [[newRow.value objectForKey:@"state"] isEqualToString:kImageStateProcessing]) {
      return YES;
    } else {
      return NO;
    }
  };
  
  NSArray *newRows = query.rows.allObjects;
  NSArray *addedIndexPaths = [self addedIndexPathsOldRows:oldRows newRows:newRows];
  NSArray *deletedIndexPaths = [self deletedIndexPathsOldRows:oldRows newRows:newRows];
  NSArray *modifiedIndexPaths = [self modifiedIndexPathsOldRows:oldRows newRows:newRows usingBlock:^BOOL(id oldObj, id newObj) {
    if (isModified(oldObj, newObj) &&
        ! isNewToProcessingStateTransition(oldObj, newObj)) {
      return YES;
    } else {
      return NO;
    }
  }];
  NSArray *newToProcessingStateTransitions = [self modifiedIndexPathsOldRows:oldRows newRows:newRows usingBlock:^BOOL(id oldObj, id newObj) {
    if (isModified(oldObj, newObj) &&
        isNewToProcessingStateTransition(oldObj, newObj)) {
      return YES;
    } else {
      return NO;
    }
  }];
  
  [self.tableView beginUpdates];
  [self.tableView insertRowsAtIndexPaths:addedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
  [self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationBottom];
  [self.tableView reloadRowsAtIndexPaths:modifiedIndexPaths withRowAnimation:UITableViewRowAnimationRight];
  [self.tableView reloadRowsAtIndexPaths:newToProcessingStateTransitions withRowAnimation:UITableViewRowAnimationNone];
  [self.tableView endUpdates];
}


- (void)couchTableSource:(CouchUITableSource*)source
         operationFailed:(RESTOperation*)op
{
  [self failedWithError:op.error];
}



#pragma mark - UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kRowHeight;
}


#pragma mark - TouchDB Sync


- (void)updateSyncURL {
  NSLog(@"resetting sync");
  if (!self.database) {
    NSLog(@"no database!");
    return;
  }
  Configuration *conf = [[Constants sharedInstance] currentConfiguration];
  NSLog(@"configuration: %@", conf.displayName);
  NSURL* newRemoteURL = [NSURL URLWithString:conf.remoteUrl];
  
  if (newRemoteURL) {
    [self forgetSync];
    _pull = [self.database pullFromDatabaseAtURL:newRemoteURL];
    _push = [self.database pushToDatabaseAtURL:newRemoteURL];
    _pull.continuous = _push.continuous = YES;
    
    [_pull addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
    [_push addObserver: self forKeyPath: @"completed" options: 0 context: NULL];
  }
}


- (void) forgetSync {
  [_pull removeObserver: self forKeyPath: @"completed"];
  [_pull stop];
  _pull = nil;
  [_push removeObserver: self forKeyPath: @"completed"];
  [_push stop];
  _push = nil;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
  if (object == _pull || object == _push) {
    unsigned completed = _pull.completed + _push.completed;
    unsigned total = _pull.total + _push.total;
    NSLog(@"SYNC progress: %u / %u", completed, total);
//    if (total > 0 && completed < total) {
//      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    } else {
//      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//    }
  }
}


@end
