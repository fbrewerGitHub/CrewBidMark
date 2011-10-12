//
//  CBBlockOfDaysOffTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jan 20 2005.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"

@implementation CBDataModel ( CBBlockOfDaysOffTabDataModel )

#pragma mark ACCESSORS

- (BOOL)blockOfDaysOffSelectCheckboxValue { return blockOfDaysOffSelectCheckboxValue; }
- (void)setBlockOfDaysOffSelectCheckboxValue:(BOOL)inValue
{
   blockOfDaysOffSelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByBlockOfDaysOff];
      [self sortLines];
   }
}

- (int)blockOfDaysOffSelectTriggerValue { return blockOfDaysOffSelectTriggerValue; }
- (void)setBlockOfDaysOffSelectTriggerValue:(int)inValue
{
   blockOfDaysOffSelectTriggerValue = inValue;

   if ([self blockOfDaysOffSelectCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self selectLinesByBlockOfDaysOff];
         [self sortLines];
      }
   }
}

- (BOOL)blockOfDaysOffPointsCheckboxValue { return blockOfDaysOffPointsCheckboxValue; }
- (void)setBlockOfDaysOffPointsCheckboxValue:(BOOL)inValue
{
   blockOfDaysOffPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (int)blockOfDaysOffPointsTriggerValue { return blockOfDaysOffPointsTriggerValue; }
- (void)setBlockOfDaysOffPointsTriggerValue:(int)inValue
{
   blockOfDaysOffPointsTriggerValue = inValue;

   if ([self blockOfDaysOffPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

- (float)blockOfDaysOffPointsValue { return blockOfDaysOffPointsValue; }
- (void)setBlockOfDaysOffPointsValue:(float)inValue
{
   blockOfDaysOffPointsValue = inValue;

   if ([self blockOfDaysOffPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}


@end
