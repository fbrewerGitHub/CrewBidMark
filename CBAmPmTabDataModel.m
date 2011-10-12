//
//  CBAmPmTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 24 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"

@implementation CBDataModel ( CBAmPmTabDataModel )

- (BOOL)amSelectCheckboxValue { return amSelectCheckboxValue; }
- (void)setAmSelectCheckboxValue:(BOOL)inValue
{
   amSelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByAm];
      [self sortLines];
   }
}

- (BOOL)pmSelectCheckboxValue { return pmSelectCheckboxValue; }
- (void)setPmSelectCheckboxValue:(BOOL)inValue
{
   pmSelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByPm];
      [self sortLines];
   }
}

- (BOOL)amPointsCheckboxValue { return amPointsCheckboxValue; }
- (void)setAmPointsCheckboxValue:(BOOL)inValue
{
   amPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (BOOL)amPointsValue { return amPointsValue; }
- (void)setAmPointsValue:(float)inValue
{
   amPointsValue = inValue;

   if ([self amPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

- (BOOL)pmPointsCheckboxValue { return pmPointsCheckboxValue; }
- (void)setPmPointsCheckboxValue:(BOOL)inValue
{
   pmPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (BOOL)pmPointsValue { return pmPointsValue; }
- (void)setPmPointsValue:(float)inValue
{
   pmPointsValue = inValue;

   if ([self pmPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}


@end
