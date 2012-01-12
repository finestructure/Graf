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

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) ImageProcessor *imageProcessor;
@property (nonatomic, retain) NSArray *pageModeNames;
@property (nonatomic, retain) NSArray *pageModeValues;
@property (nonatomic, retain) AVCaptureStillImageOutput *imageOutput;

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UILabel *imageSizeLabel;
@property (weak, nonatomic) IBOutlet UITextView *textResultView;
@property (weak, nonatomic) IBOutlet UISwitch *numbersOnlySwitch;
@property (weak, nonatomic) IBOutlet UISlider *pageModeSlider;
@property (weak, nonatomic) IBOutlet UILabel *pageModeLabel;
@property (weak, nonatomic) IBOutlet UILabel *processingTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *snapshotPreview;


- (IBAction)valueChanged:(id)sender;
- (IBAction)takePicture:(id)sender;

- (void)startSession;
- (void)stopSession;

@end
