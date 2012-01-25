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

@class MBProgressHUD;

typedef enum ControllerState {
  kIdle,
  kProcessing
} ControllerState;



@interface VideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, DbcConnectorDelegate> {
  dispatch_source_t _timer;
}

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, retain) DbcConnector *imageProcessor;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, assign) ControllerState state;

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *balanceLabel;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property (nonatomic, retain) MBProgressHUD *progressHud;


- (IBAction)takePicture:(id)sender;

- (void)transitionToState:(ControllerState)newState;


@end
