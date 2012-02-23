//
//  VideoViewController+Helpers.h
//  Graf
//
//  Created by Sven A. Schmidt on 23.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController (Helpers)

-(NSArray *)deletedIndexPathsOldRows:(NSArray *)oldRows newRows:(NSArray *)newRows;
-(NSArray *)addedIndexPathsOldRows:(NSArray *)oldRows newRows:(NSArray *)newRows;
-(NSArray *)modifiedIndexPathsOldRows:(NSArray *)oldRows newRows:(NSArray *)newRows;

@end
