//
//  ViewController.h
//  Sinma
//
//  Created by Sven A. Schmidt on 02.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) MBProgressHUD *progressHud;

- (IBAction)takePicture:(id)sender;

- (UIImage *)cropImage:(UIImage *)image toFrame:(CGRect)rect;
- (UIImage *)resizeImage:(UIImage *)img toWidth:(CGFloat)width;

@end
