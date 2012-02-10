//
//  ImageCell.m
//  Graf
//
//  Created by Sven A. Schmidt on 10.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageCell.h"

@implementation ImageCell

@synthesize recognizer = _recognizer;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
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
