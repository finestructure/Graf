//
//  VideoViewController.h
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DbcConnector.h"


@interface VideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, DbcConnectorDelegate>

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, retain) DbcConnector *imageProcessor;

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UILabel *imageSizeLabel;
@property (weak, nonatomic) IBOutlet UITextView *textResultView;
@property (weak, nonatomic) IBOutlet UILabel *processingTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *snapshotPreview;
@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *imageIdLabel;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;


- (IBAction)takePicture:(id)sender;

- (void)startSession;
- (void)stopSession;

@end
