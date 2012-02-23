//
//  VideoViewController+Helpers.m
//  Graf
//
//  Created by Sven A. Schmidt on 23.02.12.
//  Copyright (c) 2012 abstracture GmbH & Co. KG. All rights reserved.
//

#import "VideoViewController+Helpers.h"
#import <CouchCocoa/CouchQuery.h>

@implementation VideoViewController (Helpers)


#pragma mark - Table view update helpers


-(NSDictionary *)indexMapForRows:(NSArray *)rows {
  NSMutableDictionary *indexMap = [[NSMutableDictionary alloc] initWithCapacity:[rows count]];
  for (int index = 0; index < [rows count]; ++index) {
    CouchQueryRow *row = [rows objectAtIndex:index];
    [indexMap setObject:[NSIndexPath indexPathForRow:index inSection:0] forKey:[row documentID]];
  }
  return indexMap;
}


-(NSArray *)deletedIndexPathsOldRows:(NSArray *)oldRows newRows:(NSArray *)newRows {
  NSDictionary *oldIndexMap = [self indexMapForRows:oldRows];
  NSDictionary *newIndexMap = [self indexMapForRows:newRows];
  
  NSMutableSet *remainder = [NSMutableSet setWithArray:oldIndexMap.allKeys];
  NSSet *newIds = [NSSet setWithArray:newIndexMap.allKeys];
  [remainder minusSet:newIds];
  NSArray *deletedIds = remainder.allObjects;
  
  NSArray *deletedIndexPaths = [oldIndexMap objectsForKeys:deletedIds notFoundMarker:[NSNull null]];  
  return deletedIndexPaths;
}


-(NSArray *)addedIndexPathsOldRows:(NSArray *)oldRows newRows:(NSArray *)newRows {
  NSDictionary *oldIndexMap = [self indexMapForRows:oldRows];
  NSDictionary *newIndexMap = [self indexMapForRows:newRows];
  
  NSMutableSet *remainder = [NSMutableSet setWithArray:newIndexMap.allKeys];
  NSSet *oldIds = [NSSet setWithArray:oldIndexMap.allKeys];
  [remainder minusSet:oldIds];
  NSArray *addedIds = remainder.allObjects;
  
  NSArray *addedIndexPaths = [newIndexMap objectsForKeys:addedIds notFoundMarker:[NSNull null]];  
  return addedIndexPaths;
}


-(NSArray *)modifiedIndexPathsOldRows:(NSArray *)oldRows newRows:(NSArray *)newRows usingBlock:(BOOL (^)(id, id))isModified {
  NSDictionary *oldIndexMap = [self indexMapForRows:oldRows];
  NSDictionary *newIndexMap = [self indexMapForRows:newRows];
  
  NSMutableSet *intersection = [NSMutableSet setWithArray:oldIndexMap.allKeys];
  [intersection intersectSet:[NSSet setWithArray:newIndexMap.allKeys]];
  NSArray *intersectionIds = intersection.allObjects;
  
  NSArray *intersectionOldIndexPaths = [oldIndexMap objectsForKeys:intersectionIds notFoundMarker:[NSNull null]];
  NSArray *intersectionNewIndexPaths = [newIndexMap objectsForKeys:intersectionIds notFoundMarker:[NSNull null]];
  NSAssert([intersectionIds count] == [intersectionOldIndexPaths count] &&
           [intersectionIds count] == [intersectionNewIndexPaths count],
           @"intersection index counts must be equal");
  
  NSMutableArray *modifiedIndexPaths = [NSMutableArray array];
  for (NSUInteger index = 0; index < [intersectionIds count]; ++index) {
    NSIndexPath *oldIndexPath = [intersectionOldIndexPaths objectAtIndex:index];
    NSIndexPath *newIndexPath = [intersectionNewIndexPaths objectAtIndex:index];
    CouchQueryRow *oldRow = [oldRows objectAtIndex:oldIndexPath.row];
    CouchQueryRow *newRow = [newRows objectAtIndex:newIndexPath.row];
    NSLog(@"===========================================");
//    NSLog(@"old: %@", oldRow);
//    NSLog(@"new: %@", newRow);
    NSLog(@"-------------------------------------------");
    NSAssert([[oldRow documentID] isEqualToString:[newRow documentID]],
             @"document ids must be equal for objects in intersection");
    if (isModified(oldRow, newRow)) {
      [modifiedIndexPaths addObject:newIndexPath];
    }
  }
  
  return modifiedIndexPaths;
}


@end
