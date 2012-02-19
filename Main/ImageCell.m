//
//  ImageCell.m
//  Graf
//
//  Created by Sven A. Schmidt on 10.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation ImageCell

@synthesize recognizer = _recognizer;
@synthesize textResultBackgroundView = _textResultBackgroundView;


- (void)awakeFromNib
{
  self.textResultBackgroundView.backgroundColor = [UIColor clearColor];
  self.textResultBackgroundView.layer.backgroundColor=[UIColor colorWithWhite:85./255. alpha:0.7].CGColor;
  self.textResultBackgroundView.layer.cornerRadius = 8;
  self.textResultBackgroundView.layer.masksToBounds = NO;
  self.textResultBackgroundView.layer.shouldRasterize = YES;

}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (BOOL)canBecomeFirstResponder {
  return YES;
}


- (void)addRecognizerWithTarget:(id)target action:(SEL)action {
  if (self.recognizer == nil) {
    // only add a recognizer if we don't have one yet
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:recognizer];
    self.recognizer = recognizer;
  }
}


@end
