//
//  Test_CouchUITableSource.m
//  CouchCocoa
//
//  Created by Sven A. Schmidt on 17.02.12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>
#import <GHUnitIOS/GHUnit.h>

#import "VideoViewController+Helpers.h"

@interface MockRow : CouchQueryRow

+ (id)rowWithResult:(id)result;
- (id)initWithResult:(id)result;

@end

@implementation MockRow

+ (id)rowWithResult:(id)result {
  return [[MockRow alloc] initWithResult:result];
}


- (id)initWithResult:(id)result {
  CouchQuery *query = [[CouchQuery alloc] init];
  self = [super performSelector:@selector(initWithQuery:result:) withObject:query withObject:result];
  return self;
}

@end


@interface Test_CouchUITableSource : GHTestCase

@property (nonatomic, retain) VideoViewController *vvc;

@end


@implementation Test_CouchUITableSource

@synthesize vvc = _vvc;


- (void)setUp {
  self.vvc = [[VideoViewController alloc] init];
}


- (void)tearDown {
  self.vvc = nil;
}


- (void)test_newRows {
  NSArray *old = [NSArray array];
  NSDictionary *doc1 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_1", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *doc2 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_2", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *doc3 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_3", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *row1 = [NSDictionary dictionaryWithObjectsAndKeys:doc1, @"doc", nil];
  NSDictionary *row2 = [NSDictionary dictionaryWithObjectsAndKeys:doc2, @"doc", nil];
  NSDictionary *row3 = [NSDictionary dictionaryWithObjectsAndKeys:doc3, @"doc", nil];
  NSArray *new = [NSArray arrayWithObjects:[MockRow rowWithResult:row1], [MockRow rowWithResult:row2], [MockRow rowWithResult:row3], nil];
  
  NSArray *deletedIndexPaths = [self.vvc performSelector:@selector(deletedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([deletedIndexPaths count], 0u, nil);

  NSArray *newIndexPaths = [self.vvc performSelector:@selector(addedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([newIndexPaths count], 3u, nil);
  NSSet *expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                         [NSIndexPath indexPathForRow:0 inSection:0],
                                         [NSIndexPath indexPathForRow:1 inSection:0],
                                         [NSIndexPath indexPathForRow:2 inSection:0],
                                         nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:newIndexPaths]], nil);
  
  // add more rows
  old = new;
  NSDictionary *doc2a = [NSDictionary dictionaryWithObjectsAndKeys:@"id_2a", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *doc2b = [NSDictionary dictionaryWithObjectsAndKeys:@"id_2b", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *row2a = [NSDictionary dictionaryWithObjectsAndKeys:doc2a, @"doc", nil];
  NSDictionary *row2b = [NSDictionary dictionaryWithObjectsAndKeys:doc2b, @"doc", nil];
  new = [NSArray arrayWithObjects:[MockRow rowWithResult:row1], [MockRow rowWithResult:row2], [MockRow rowWithResult:row2a], [MockRow rowWithResult:row2b], [MockRow rowWithResult:row3], nil];
  
  deletedIndexPaths = [self.vvc performSelector:@selector(deletedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([deletedIndexPaths count], 0u, nil);

  newIndexPaths = [self.vvc performSelector:@selector(addedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([newIndexPaths count], 2u, nil);
  expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                  [NSIndexPath indexPathForRow:2 inSection:0],
                                  [NSIndexPath indexPathForRow:3 inSection:0],
                                  nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:newIndexPaths]], nil);
  
  // now remove some rows
  old = new;
  new = [NSArray arrayWithObjects:[MockRow rowWithResult:row1], [MockRow rowWithResult:row2b], [MockRow rowWithResult:row3], nil];

  deletedIndexPaths = [self.vvc performSelector:@selector(deletedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([deletedIndexPaths count], 2u, nil);
  expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                  [NSIndexPath indexPathForRow:1 inSection:0],
                                  [NSIndexPath indexPathForRow:2 inSection:0],
                                  nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:deletedIndexPaths]], nil);

  newIndexPaths = [self.vvc performSelector:@selector(addedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([newIndexPaths count], 0u, nil);
  
  // finally, change some rows
  old = [NSArray arrayWithObjects:[MockRow rowWithResult:row1], [MockRow rowWithResult:row2], [MockRow rowWithResult:row3], nil];
  NSDictionary *doc2v2 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_2", @"_id", @"rev_2", @"_rev", nil];
  NSDictionary *row2v2 = [NSDictionary dictionaryWithObjectsAndKeys:doc2v2, @"doc", nil];
  NSDictionary *doc3v2 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_3", @"_id", @"rev_2", @"_rev", nil];
  NSDictionary *row3v2 = [NSDictionary dictionaryWithObjectsAndKeys:doc3v2, @"doc", nil];
  new = [NSArray arrayWithObjects:[MockRow rowWithResult:row1], [MockRow rowWithResult:row2v2], [MockRow rowWithResult:row3v2], nil];

  deletedIndexPaths = [self.vvc performSelector:@selector(deletedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([deletedIndexPaths count], 0u, nil);

  newIndexPaths = [self.vvc performSelector:@selector(addedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([newIndexPaths count], 0u, nil);
  
  NSArray *modifiedIndexPaths = [self.vvc performSelector:@selector(modifiedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([modifiedIndexPaths count], 2u, nil);
  expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                  [NSIndexPath indexPathForRow:1 inSection:0],
                                  [NSIndexPath indexPathForRow:2 inSection:0],
                                  nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:modifiedIndexPaths]], nil);
  
  // combine both
  NSDictionary *doc0 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_0", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *doc4 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_4", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *doc5 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_5", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *doc6 = [NSDictionary dictionaryWithObjectsAndKeys:@"id_6", @"_id", @"rev_1", @"_rev", nil];
  NSDictionary *row0 = [NSDictionary dictionaryWithObjectsAndKeys:doc0, @"doc", nil];
  NSDictionary *row4 = [NSDictionary dictionaryWithObjectsAndKeys:doc4, @"doc", nil];
  NSDictionary *row5 = [NSDictionary dictionaryWithObjectsAndKeys:doc5, @"doc", nil];
  NSDictionary *row6 = [NSDictionary dictionaryWithObjectsAndKeys:doc6, @"doc", nil];
  old = [NSArray arrayWithObjects:
         [MockRow rowWithResult:row0],
         [MockRow rowWithResult:row1],
         [MockRow rowWithResult:row2],
         [MockRow rowWithResult:row3],
         [MockRow rowWithResult:row4],
         [MockRow rowWithResult:row5],
         nil];
  new = [NSArray arrayWithObjects:
         [MockRow rowWithResult:row2a],
         [MockRow rowWithResult:row2b],
         [MockRow rowWithResult:row0],
         [MockRow rowWithResult:row1],
         [MockRow rowWithResult:row3],
         [MockRow rowWithResult:row2v2],
         [MockRow rowWithResult:row4],
         [MockRow rowWithResult:row6],
         [MockRow rowWithResult:row3v2],
         nil];

  deletedIndexPaths = [self.vvc performSelector:@selector(deletedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([deletedIndexPaths count], 1u, nil);
  expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                  [NSIndexPath indexPathForRow:5 inSection:0],
                                  nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:deletedIndexPaths]], nil);

  newIndexPaths = [self.vvc performSelector:@selector(addedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([newIndexPaths count], 3u, nil);
  expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                  [NSIndexPath indexPathForRow:0 inSection:0],
                                  [NSIndexPath indexPathForRow:1 inSection:0],
                                  [NSIndexPath indexPathForRow:7 inSection:0],
                                  nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:newIndexPaths]], nil);

  modifiedIndexPaths = [self.vvc performSelector:@selector(modifiedIndexPathsOldRows:newRows:) withObject:old withObject:new];
  GHAssertEquals([modifiedIndexPaths count], 2u, nil);
  expected = [NSSet setWithArray:[NSArray arrayWithObjects:
                                  [NSIndexPath indexPathForRow:5 inSection:0],
                                  [NSIndexPath indexPathForRow:8 inSection:0],
                                  nil]];
  GHAssertTrue([expected isEqualToSet:[NSSet setWithArray:modifiedIndexPaths]], nil);
}


@end
