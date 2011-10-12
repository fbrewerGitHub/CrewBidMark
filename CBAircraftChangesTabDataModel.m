//
//  CBAircraftChangesTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 24 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"

@implementation CBDataModel ( CBAircraftChangesTabDataModel )

#pragma mark ACCESSORS

- (BOOL)aircraftChangesSelectCheckboxValue { return aircraftChangesSelectCheckboxValue; }
- (void)setAircraftChangesSelectCheckboxValue:(BOOL)inValue
{
   aircraftChangesSelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByAircraftChanges];
      [self sortLines];
   }
}

- (int)aircraftChangesSelectTriggerValue { return aircraftChangesSelectTriggerValue; }
- (void)setAircraftChangesSelectTriggerValue:(int)inValue
{
   aircraftChangesSelectTriggerValue = inValue;

   if ([self aircraftChangesSelectCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self selectLinesByAircraftChanges];
         [self sortLines];
      }
   }
}

- (BOOL)aircraftChangesPointsCheckboxValue { return aircraftChangesPointsCheckboxValue; }
- (void)setAircraftChangesPointsCheckboxValue:(BOOL)inValue
{
   aircraftChangesPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (float)aircraftChangesPointsValue { return aircraftChangesPointsValue; }
- (void)setAircraftChangesPointsValue:(float)inValue
{
   aircraftChangesPointsValue = inValue;

   if ([self aircraftChangesPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}


@end
