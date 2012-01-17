//
//  NSMutableArray+QueueAdditions.m
//  Sinma
//
//  Created by Sven A. Schmidt on 17.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "NSMutableArray+QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

- (id)dequeue {
  // if ([self count] == 0) return nil;
  id headObject = [self objectAtIndex:0];
  if (headObject != nil) {
    [self removeObjectAtIndex:0];
  }
  return headObject;
}

- (void)enqueue:(id)anObject {
  [self addObject:anObject];
}
@end
