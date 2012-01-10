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
@property (nonatomic, retain) NSArray *pageModeNames;
@property (nonatomic, retain) NSArray *pageModeValues;

@property (weak, nonatomic) IBOutlet UIImageView *snapShotView;
@property (weak, nonatomic) IBOutlet UILabel *imageSizeLabel;
@property (weak, nonatomic) IBOutlet UITextView *textResultView;

@property (weak, nonatomic) IBOutlet UISwitch *numbersOnlySwitch;
@property (weak, nonatomic) IBOutlet UISlider *pageModeSlider;
@property (weak, nonatomic) IBOutlet UILabel *pageModeLabel;

@property (weak, nonatomic) IBOutlet UISwitch *runOcrSwitch;

- (IBAction)done:(id)sender;
- (IBAction)valueChanged:(id)sender;

@end
