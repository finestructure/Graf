//
//  ViewController.h
//  Sinma
//
//  Created by Sven A. Schmidt on 02.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;

namespace tesseract {
  class TessBaseAPI;
};


@interface ViewController : UIViewController
{
  tesseract::TessBaseAPI *tesseract;
  uint32_t *pixels;
}

@property (nonatomic, retain) NSString *dataPath;
@property (nonatomic, retain) NSDate *start;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, retain) MBProgressHUD *progressHud;
@property (weak, nonatomic) IBOutlet UILabel *imageSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *imageScaleLabel;
@property (weak, nonatomic) IBOutlet UILabel *numbersOnlyLabel;
@property (weak, nonatomic) IBOutlet UILabel *processingTimeLabel;

- (IBAction)takePicture:(id)sender;
- (IBAction)showSettings:(id)sender;

- (UIImage *)cropImage:(UIImage *)image toFrame:(CGRect)rect;
- (UIImage *)resizeImage:(UIImage *)img toWidth:(CGFloat)width;
- (void)setTesseractImage:(UIImage *)image;
- (void)defaultsChanged:(NSDictionary *)userInfo;
- (void)updateLabels;

@end
