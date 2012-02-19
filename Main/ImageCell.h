//
//  ImageCell.h
//  Graf
//
//  Created by Sven A. Schmidt on 10.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCell : UITableViewCell

@property (nonatomic, retain) UIGestureRecognizer *recognizer;

@property (weak, nonatomic) IBOutlet UILabel *textResultBackgroundLabel;

- (void)addRecognizerWithTarget:(id)target action:(SEL)action;

@end
