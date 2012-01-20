//
//  NSMutableArray+QueueAdditions.h
//  Sinma
//
//  Created by Sven A. Schmidt on 17.01.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

@interface NSMutableArray (QueueAdditions)
- (id) dequeue;
- (void) enqueue:(id)obj;
@end
