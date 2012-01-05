//
//  ImageProcessor.m
//  Sinma
//
//  Created by Sven A. Schmidt on 05.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "ImageProcessor.h"
#import "SettingsViewController.h"

#include "baseapi.h"

#include "environ.h"
#import "pix.h"


@interface ImageProcessor () {
  tesseract::TessBaseAPI *tesseract;
  uint32_t *pixels;
}
@end


@implementation ImageProcessor

@synthesize dataPath = _dataPath;


- (id)init {
  self = [super init];
  if (self) {
    // Set up the tessdata path. This is included in the application bundle
    // but is copied to the Documents directory on the first run.
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    self.dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:self.dataPath]) {
      // get the path to the app bundle (with the tessdata dir)
      NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
      NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
      if (tessdataPath) {
        [fileManager copyItemAtPath:tessdataPath toPath:self.dataPath error:NULL];
      }
    }
    
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);

    // init the tesseract engine.
    tesseract = new tesseract::TessBaseAPI();
    tesseract->Init([self.dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
    
    // configure "numbers only", if selected
    NSNumber *numbersOnly = [[NSUserDefaults standardUserDefaults] valueForKey:kNumbersOnlyDefault];
    if ([numbersOnly boolValue] == YES) {
      tesseract->SetVariable("tessedit_char_whitelist", "0123456789");
    }
  }
  return self;
}


- (NSString *)processImage:(UIImage *)image
{
  [self setTesseractImage:image];
  
  tesseract->Recognize(NULL);
  char* utf8Text = tesseract->GetUTF8Text();
  
  NSString *result = @"";
  if (utf8Text != nil) {
    result = [NSString stringWithUTF8String:utf8Text];
  }
  delete [] utf8Text;
  
  return result;
}


- (NSString *)processSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
  // Get a CMSampleBuffer's Core Video image buffer for the media data
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
  // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0); 
  
  // Get the number of bytes per row for the pixel buffer
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
  // Get the pixel buffer width and height
  size_t width = CVPixelBufferGetWidth(imageBuffer); 
  size_t height = CVPixelBufferGetHeight(imageBuffer);

  tesseract->SetImage((const unsigned char *)baseAddress, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
  
  tesseract->Recognize(NULL);
  char* utf8Text = tesseract->GetUTF8Text();
  
  NSString *result = @"";
  if (utf8Text != nil) {
    result = [NSString stringWithUTF8String:utf8Text];
  }
  delete [] utf8Text;
  
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

  return result;
}


- (void)setTesseractImage:(UIImage *)image
{
  free(pixels);
  pixels = NULL;
  
  CGSize size = [image size];
  int width = size.width;
  int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
  // the pixels will be painted to this array
  pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
  // clear the pixels so any transparency is preserved
  memset(pixels, 0, width * height * sizeof(uint32_t));
	
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
  // create a context with RGBA pixels
  CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, 
                                               kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
  // paint the bitmap to our context which will fill in the pixels array
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}



@end
