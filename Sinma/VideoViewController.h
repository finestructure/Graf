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

@interface VideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) ImageProcessor *imageProcessor;

@property (weak, nonatomic) IBOutlet UIImageView *snapShotView;
@property (weak, nonatomic) IBOutlet UILabel *imageSizeLabel;
@property (weak, nonatomic) IBOutlet UITextView *textResultView;

- (IBAction)done:(id)sender;

@end
