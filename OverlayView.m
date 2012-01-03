//
//  OverlayView.m
//  TesseractSample
//
//  Created by Sven A. Schmidt on 22.12.11.
//  Copyright (c) 2011 abstracture GmbH & Co. KG. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}


- (void)drawRect:(CGRect)rect
{
  CGContextRef currentContext = UIGraphicsGetCurrentContext();
  CGContextSaveGState(currentContext);
  CGContextSetRGBStrokeColor(currentContext, 0.0f, 1.0f, 0.0f, 1.0f);

  UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
  path.lineWidth = 8;
  [path stroke];
  
  CGContextRestoreGState(currentContext);
}


@end
