//
//  NSMutableArray+MAArrayUtilities.m
//  CrewBid
//
//  Created by Mark on 5/15/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import "NSMutableArray+MAArrayUtilities.h"


@implementation NSMutableArray (MAArrayUtilities)

- (void)moveObjectAtIndex:(unsigned)oldIndex toIndex:(unsigned)newIndex
{
   // do nothing if the moving to same index
   if (oldIndex == newIndex) return;
   // raise exception for bad arguments
   if (oldIndex < 0 || newIndex < 0 ||
       oldIndex > [self count] - 1 || newIndex > [self count] - 1) {
      NSException *exception = [NSException 
         exceptionWithName:NSInvalidArgumentException 
         reason:@"Index(es) outside bounds of array in \"moveObjectAtIndex:toIndex\" method of NSMutableArray+MAArrayUtilities category." 
         userInfo:nil];
      [exception raise];
   }
   // create subarray within which the object will be moved
   NSRange moveRange;
   NSMutableArray *moveArray;
   id obj;
   // if moving down in the array, first remove object at top of subarray, then
   //  reinsert at end
   if (oldIndex < newIndex) {
      moveRange = NSMakeRange(oldIndex, newIndex - oldIndex + 1);
      moveArray = [[self subarrayWithRange:moveRange] mutableCopy];
      obj = [[moveArray objectAtIndex:0] retain];
      [moveArray removeObjectAtIndex:0];
      [moveArray addObject:obj];
      [obj release];
   // if moving up in the array, first remove object at end of subarray, then
   // reinsert at top
   } else {
      moveRange = NSMakeRange(newIndex, oldIndex - newIndex + 1);
      moveArray = [[self subarrayWithRange:moveRange] mutableCopy];
      obj = [[moveArray lastObject] retain];
      [moveArray removeLastObject];
      [moveArray insertObject:obj atIndex:0];
      [obj release];
   }
   // replace objects in moved range
   [self replaceObjectsInRange:moveRange withObjectsFromArray:moveArray];
}

- (void)moveObjectsAtIndexes:(NSArray *)oldIndexes toIndexes:(NSArray *)newIndexes
{
   // do nothing if either array is nil, the index arrays are the same, or the
   // arrays are empty
   unsigned indexCount = [oldIndexes count];
   if (!oldIndexes || !newIndexes || oldIndexes == newIndexes || 0 == indexCount || 0 == [newIndexes count]) return;
   // raise exception if index arrays are not the same size
   if (indexCount != [newIndexes count]) {
      NSException *exception = [NSException 
         exceptionWithName:NSInvalidArgumentException 
         reason:@"Unequal argument array sizes in \"moveObjectsAtIndexes:toIndexes\" method of NSMutableArray+MAArrayUtilities category." 
         userInfo:nil];
      [exception raise];
   }
   // move each object from position in old indexes to position in new indexes
   unsigned i;
   id fromNum;
   id toNum;
   unsigned fromIdx = 0;
   unsigned toIdx = 0;
   unsigned smallerIdx = 0;
   unsigned largerIdx = 0;
   unsigned minIdx = [self count];
   unsigned maxIdx = 0;
   // determine subarray range
   for (i = 0; i < indexCount; ++i) {
      fromNum = [oldIndexes objectAtIndex:i];
      toNum = [newIndexes objectAtIndex:i];
      if (![fromNum respondsToSelector:@selector(intValue)] ||
          ![toNum respondsToSelector:@selector(intValue)]) {
         NSException *exception = [NSException 
            exceptionWithName:NSInvalidArgumentException 
            reason:@"Object(s) in argument array(s) do not respond to \"intValue\" selector in \"moveObjectsAtIndexes:toIndexes\" method of NSMutableArray+MAArrayUtilities category." 
            userInfo:nil];
         [exception raise];
      }
      fromIdx = [fromNum intValue];
      toIdx = [toNum intValue];
      smallerIdx = fromIdx < toIdx ? fromIdx : toIdx;
      largerIdx = fromIdx > toIdx ? fromIdx : toIdx;
      minIdx = smallerIdx < minIdx ? smallerIdx : minIdx;
      maxIdx = largerIdx > maxIdx ? largerIdx : maxIdx;
   }
   // create subarrays
   NSRange subrange = NSMakeRange(minIdx, maxIdx - minIdx + 1);
   NSMutableArray *subarray = [[self subarrayWithRange:subrange] mutableCopy];
   NSMutableArray *newPositions = [NSMutableArray arrayWithCapacity:subrange.length];
   for (i = 0; i < subrange.length; ++i) {
      [newPositions addObject:[NSNull null]];
   }
   
   // place objects in new positions and remove from subarray 
   for (i = 0; i < indexCount; ++i) {
      fromNum = [oldIndexes objectAtIndex:i];
      toNum = [newIndexes objectAtIndex:i];
      fromIdx = [fromNum intValue];
      toIdx = [toNum intValue];
      [newPositions replaceObjectAtIndex:toIdx - minIdx withObject:[self objectAtIndex:fromIdx]];
      [subarray replaceObjectAtIndex:fromIdx - minIdx withObject:[NSNull null]];
   }
   // replace nulls with replaced objects
   unsigned subarrayIndex = 0;
   for (i = 0; i < subrange.length; ++i) {
      if ([[newPositions objectAtIndex:i] isEqualTo:[NSNull null]]) {
         while ([[subarray objectAtIndex:subarrayIndex] isEqualTo:[NSNull null]]) {
            subarrayIndex++;
         }
         [newPositions replaceObjectAtIndex:i withObject:[subarray objectAtIndex:subarrayIndex]];
         subarrayIndex++;
      }
   }
   [self replaceObjectsInRange:subrange withObjectsFromArray:newPositions];
}

@end
