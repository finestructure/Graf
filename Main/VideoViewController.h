//
//  VideoViewController.h
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ImageProcessor.h"


@class Image;


@interface VideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, ImageProcessorDelegate>

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, retain) ImageProcessor *imageProcessor;
@property (nonatomic, retain) NSMutableArray *images;

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (void)startProcessingImage:(Image *)image;

- (IBAction)takePicture:(id)sender;
- (void)refreshButtonPressed:(id)sender;


@end
