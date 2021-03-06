//
//  VideoViewController.h
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@class Image;
@class CouchDatabase;
@class CouchReplication;
#import <CouchCocoa/CouchUITableSource.h>


@interface VideoViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, CouchUITableDelegate> {
  CouchReplication* _pull;
  CouchReplication* _push;
}

@property (nonatomic, retain) AVCaptureSession *session;
@property (nonatomic, retain) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, retain) CouchDatabase *database;

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, retain) IBOutlet CouchUITableSource* dataSource;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *configurationLabel;

- (IBAction)takePicture:(id)sender;
- (IBAction)configButtonPressed:(id)sender;

- (void)failedWithError:(NSError *)error;

- (void)updateSyncURL;
- (void)forgetSync;

@end
