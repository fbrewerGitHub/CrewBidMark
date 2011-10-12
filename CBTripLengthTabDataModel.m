//
//  CBTripLengthTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 24 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"

@implementation CBDataModel ( CBTripLengthTabDataModel )

#pragma mark TURNS

- (BOOL)turnSelectCheckboxValue { return turnSelectCheckboxValue; }
- (void)setTurnSelectCheckboxValue:(BOOL)inValue
{
   turnSelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByTurns];
      [self sortLines];
   }
}

- (int)turnSelectTriggerValue { return turnSelectTriggerValue; }
- (void)setTurnSelectTriggerValue:(int)inValue
{
   turnSelectTriggerValue = inValue;

   if ([self turnSelectCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self selectLinesByTurns];
         [self sortLines];
      }
   }
}

- (BOOL)turnPointsCheckboxValue { return turnPointsCheckboxValue; }
- (void)setTurnPointsCheckboxValue:(BOOL)inValue
{
   turnPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (float)turnPointsValue { return turnPointsValue; }
- (void)setTurnPointsValue:(float)inValue
{
   turnPointsValue = inValue;

   if ([self turnPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

#pragma mark TWO-DAYS

- (BOOL)twoDaySelectCheckboxValue { return twoDaySelectCheckboxValue; }
- (void)setTwoDaySelectCheckboxValue:(BOOL)inValue
{
   twoDaySelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByTwoDays];
      [self sortLines];
   }
}

- (int)twoDaySelectTriggerValue { return twoDaySelectTriggerValue; }
- (void)setTwoDaySelectTriggerValue:(int)inValue
{
   twoDaySelectTriggerValue = inValue;

   if ([self twoDaySelectCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self selectLinesByTwoDays];
         [self sortLines];
      }
   }
}

- (BOOL)twoDayPointsCheckboxValue { return twoDayPointsCheckboxValue; }
- (void)setTwoDayPointsCheckboxValue:(BOOL)inValue
{
   twoDayPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (float)twoDayPointsValue { return twoDayPointsValue; }
- (void)setTwoDayPointsValue:(float)inValue
{
   twoDayPointsValue = inValue;

   if ([self twoDayPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

#pragma mark THREE-DAYS

- (BOOL)threeDaySelectCheckboxValue { return threeDaySelectCheckboxValue; }
- (void)setThreeDaySelectCheckboxValue:(BOOL)inValue
{
   threeDaySelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByThreeDays];
      [self sortLines];
   }
}

- (int)threeDaySelectTriggerValue { return threeDaySelectTriggerValue; }
- (void)setThreeDaySelectTriggerValue:(int)inValue
{
   threeDaySelectTriggerValue = inValue;

   if ([self threeDaySelectCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self selectLinesByThreeDays];
         [self sortLines];
      }
   }
}

- (BOOL)threeDayPointsCheckboxValue { return threeDayPointsCheckboxValue; }
- (void)setThreeDayPointsCheckboxValue:(BOOL)inValue
{
   threeDayPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (float)threeDayPointsValue  { return threeDayPointsValue; }
- (void)setThreeDayPointsValue:(float)inValue
{
   threeDayPointsValue = inValue;

   if ([self threeDayPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

#pragma mark FOUR-DAYS

- (BOOL)fourDaySelectCheckboxValue { return fourDaySelectCheckboxValue; }
- (void)setFourDaySelectCheckboxValue:(BOOL)inValue
{
   fourDaySelectCheckboxValue = inValue;

   if (sortingEnabled) {
      [self selectLinesByFourDays];
      [self sortLines];
   }
}

- (int)fourDaySelectTriggerValue { return fourDaySelectTriggerValue; }
- (void)setFourDaySelectTriggerValue:(int)inValue
{
   fourDaySelectTriggerValue = inValue;

   if ([self fourDaySelectCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self selectLinesByFourDays];
         [self sortLines];
      }
   }
}

- (BOOL)fourDayPointsCheckboxValue { return fourDayPointsCheckboxValue; }
- (void)setFourDayPointsCheckboxValue:(BOOL)inValue
{
   fourDayPointsCheckboxValue = inValue;

   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

- (float)fourDayPointsValue { return fourDayPointsValue; }
- (void)setFourDayPointsValue:(float)inValue
{
   fourDayPointsValue = inValue;

   if ([self fourDayPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

@end
