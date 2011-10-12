//
//  CBDaysOfMonthTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 24 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"

NSString *CBDataModelDaysOfMonthSelectValuesChangedNotification = @"Data Model Days of Month Select Values Changed Notification";
NSString *CBDataModelDaysOfMonthPointsValuesChangedNotification = @"Data Model Days of Month Points Values Changed Notification";
NSString *CBDataModelDaysOfWeekSelectValuesChangedNotification = @"Data Model Days of Week Select Values Changed Notification";
NSString *CBDataModelDaysOfWeekPointsValuesChangedNotification = @"Data Model Days of Week Points Values Changed Notification";


@implementation CBDataModel ( CBDaysOfMonthTabDataModel )

- (BOOL)daysOfMonthSelectCheckboxValue { return daysOfMonthSelectCheckboxValue; }
- (void)setDaysOfMonthSelectCheckboxValue:(BOOL)inValue
{
    daysOfMonthSelectCheckboxValue = inValue;
    if (sortingEnabled) {
        [self selectLinesByDaysOfMonth];
        [self sortLines];
    }
}

// days of month select values are NSCalendarDate(s) that correspond to days
// wanted off
- (NSSet *)daysOfMonthSelectValues { return daysOfMonthSelectValues; }
- (void)setDaysOfMonthSelectValues:(NSSet *)inValue
{
    if (daysOfMonthSelectValues != inValue) {
        daysOfMonthSelectValues = [inValue copy];
      
        [[NSNotificationCenter defaultCenter]
            postNotificationName:CBDataModelDaysOfMonthSelectValuesChangedNotification 
            object:self 
            userInfo:[NSDictionary dictionaryWithObject:daysOfMonthSelectValues forKey:CBDataModelDaysOfMonthSelectValuesChangedNotification]];

        if (sortingEnabled && [self daysOfMonthSelectCheckboxValue] == YES) {
            [self selectLinesByDaysOfMonth];
            [self sortLines];
        }
    }
}

- (BOOL)daysOfMonthPointsCheckboxValue { return daysOfMonthPointsCheckboxValue; }
- (void)setDaysOfMonthPointsCheckboxValue:(BOOL)inValue
{
    daysOfMonthPointsCheckboxValue = inValue;
    if (sortingEnabled) {
        [self adjustPointsForLines];
    }
}

// days of month points values have key of NSCalendarDate and object an NSNumber
// (float value) that corresponds to points for that date
- (NSDictionary *)daysOfMonthPointsValues { return daysOfMonthPointsValues; }
- (void)setDaysOfMonthPointsValues:(NSDictionary *)inValue
{
    if (daysOfMonthPointsValues != inValue) {
        daysOfMonthPointsValues = [inValue copy];

        [[NSNotificationCenter defaultCenter]
            postNotificationName:CBDataModelDaysOfMonthPointsValuesChangedNotification 
            object:self 
            userInfo:[NSDictionary dictionaryWithObject:daysOfMonthPointsValues forKey:CBDataModelDaysOfMonthPointsValuesChangedNotification]];

        if (sortingEnabled && [self daysOfMonthPointsCheckboxValue] == YES) {
            [self adjustPointsForLines];
        }
    }
}

// day of week select values are NSNumber(s) that represent day of week (0-6)
- (NSSet *)daysOfWeekSelectValues { return daysOfWeekSelectValues; }
- (void)setDaysOfWeekSelectValues:(NSSet *)inValue
{   
	if (daysOfWeekSelectValues != inValue) {
		NSSet *newSelectValues = inValue;
		NSMutableSet *allSelectValues = [daysOfWeekSelectValues mutableCopy];
		[allSelectValues unionSet:newSelectValues];
		// add days of month select values that have been selected and
		// remove days of month select values that have been deselected
		int monthDayOfWeek = [[self firstBidDate] dayOfWeek];
		NSMutableSet *monthSelectValues = [[self daysOfMonthSelectValues] mutableCopy];
		NSEnumerator *allSelectDatesEnumerator = [allSelectValues objectEnumerator];
		NSNumber *dayOfWeekNumber = nil;
		while (dayOfWeekNumber = [allSelectDatesEnumerator nextObject])
		{
			int day = [dayOfWeekNumber intValue] - monthDayOfWeek;
			day = day < 0 ? day + 7 : day;
			NSCalendarDate *dateToAdd = [[self firstBidDate] dateByAddingYears:0 months:0 days:day hours:0 minutes:0 seconds:0];
			while ([dateToAdd timeIntervalSinceReferenceDate] >= [[self firstBidDate] timeIntervalSinceReferenceDate] && [dateToAdd timeIntervalSinceReferenceDate] <= [[self lastBidDate] timeIntervalSinceReferenceDate])
			{
				if ([newSelectValues containsObject:dayOfWeekNumber])
				{
					[monthSelectValues addObject:dateToAdd];
				}
				else
				{
					[monthSelectValues removeObject:dateToAdd];
				}
				dateToAdd = [dateToAdd dateByAddingYears:0 months:0 days:7 hours:0 minutes:0 seconds:0];
			}
		}		
        // set new value and post notification
        daysOfWeekSelectValues = [inValue copy];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:CBDataModelDaysOfWeekSelectValuesChangedNotification 
            object:self 
            userInfo:[NSDictionary 
                dictionaryWithObject:daysOfWeekSelectValues 
                forKey:CBDataModelDaysOfWeekSelectValuesChangedNotification]];
        // set days of month select values
        [self setDaysOfMonthSelectValues:monthSelectValues];
        [monthSelectValues release];
        [allSelectValues release];
        // don't need to sort because days of month select values are
        // also set by the action method
   }
}

// day of week points values are NSNumber(s) (float value) correspond to 
// points for day of week
- (NSDictionary *)daysOfWeekPointsValues { return daysOfWeekPointsValues; }
- (void)setDaysOfWeekPointsValues:(NSDictionary *)inValue
{
   if (daysOfWeekPointsValues != inValue) {
		NSDictionary *newPointsValues = inValue;
		NSMutableDictionary *allPointsValues = [daysOfWeekPointsValues mutableCopy];
		[allPointsValues addEntriesFromDictionary:newPointsValues];
		// add days of month select values that have been selected and
		// remove days of month select values that have been deselected
		int monthDayOfWeek = [[self firstBidDate] dayOfWeek];
		NSMutableDictionary *monthPointsValues = [[self daysOfMonthPointsValues] mutableCopy];
		NSEnumerator *allKeysEnumerator = [allPointsValues keyEnumerator];
		NSNumber *dayOfWeekNumber = nil;
		while (dayOfWeekNumber = [allKeysEnumerator nextObject])
		{
			NSNumber *datePoints = [allPointsValues objectForKey:dayOfWeekNumber];
			int day = [dayOfWeekNumber intValue] - monthDayOfWeek;
			day = day < 0 ? day + 7 : day;
			NSCalendarDate *dateToAdd = [[self firstBidDate] dateByAddingYears:0 months:0 days:day hours:0 minutes:0 seconds:0];
			while ([dateToAdd timeIntervalSinceReferenceDate] >= [[self firstBidDate] timeIntervalSinceReferenceDate] && [dateToAdd timeIntervalSinceReferenceDate] <= [[self lastBidDate] timeIntervalSinceReferenceDate])
			{
				if ([newPointsValues objectForKey:dayOfWeekNumber])
				{
					[monthPointsValues setObject:datePoints forKey:dateToAdd];
				}
				else
				{
					[monthPointsValues removeObjectForKey:dateToAdd];
				}
				dateToAdd = [dateToAdd dateByAddingYears:0 months:0 days:7 hours:0 minutes:0 seconds:0];
			}
		}		
    // set new value and post notification
    daysOfWeekPointsValues = [inValue copy];
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:CBDataModelDaysOfWeekPointsValuesChangedNotification 
        object:self 
        userInfo:[NSDictionary 
            dictionaryWithObject:daysOfWeekPointsValues 
            forKey:CBDataModelDaysOfWeekPointsValuesChangedNotification]];
    
    [allPointsValues release];
    
    // set days of month select values
    [self setDaysOfMonthPointsValues:[NSDictionary dictionaryWithDictionary:monthPointsValues]];
    [monthPointsValues release];
      // don't need to adjust points because days of month points values are
      // also set by the action method
   }
}

@end
