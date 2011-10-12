//
//  CSCalendarWeek.m
//  CrewBid
//
//  Created by Mark Ackerman on 9/7/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSCalendarWeek.h"

NSString *CSCalendarWeekFirstSundayNotASundayExceptionName = @"CSCalendarWeek First Sunday Not a Sunday Exception";


@implementation CSCalendarWeek

#pragma mark
#pragma mark Class Methods
#pragma mark

+ (NSArray *)calendarWeeksForMonth:(NSCalendarDate *)month
{
    NSMutableArray *calendarWeeks = [NSMutableArray arrayWithCapacity:6];
    NSCalendarDate *firstSunday = [CSCalendarWeek firstSundayForMonth:month];
    // since the first sunday of the month is likely not in current month
    // (unless month starts on a sunday), add the first sunday
    CSCalendarWeek *calWeek = [CSCalendarWeek calendarWeekWithFirstSunday:firstSunday];
    [calendarWeeks addObject:calWeek];
    // now add all calendar weeks for remainder of month
    firstSunday = [CSCalendarWeek nextSundayForSunday:firstSunday];
    int monthOfYear = [month monthOfYear];
    while ([firstSunday monthOfYear] == monthOfYear)
    {
        calWeek = [CSCalendarWeek calendarWeekWithFirstSunday:firstSunday];
        [calendarWeeks addObject:calWeek];
        firstSunday = [CSCalendarWeek nextSundayForSunday:firstSunday];
    }
    // now add first week in next month if the last day of month is within
    // three days of next sunday
    if ([firstSunday dayOfMonth] < 4)
    {
        calWeek = [CSCalendarWeek calendarWeekWithFirstSunday:firstSunday];
        [calendarWeeks addObject:calWeek];
    }
    
    return calendarWeeks;
}

+ (NSCalendarDate *)firstSundayForMonth:(NSCalendarDate *)month
{
    int dayOfWeek = [month dayOfWeek];
    NSCalendarDate *firstSunday = [month 
        dateByAddingYears:0 
        months:0 
        days:-dayOfWeek 
        hours:0 
        minutes:0 
        seconds:0];
    return firstSunday;
}

+ (NSCalendarDate *)nextSundayForSunday:(NSCalendarDate *)sunday
{
    NSCalendarDate *nextSunday = [sunday 
        dateByAddingYears:0 
        months:0 
        days:7 
        hours:0 
        minutes:0 
        seconds:0];
    return nextSunday;
}

#pragma mark
#pragma mark Initialization
#pragma mark

+ (id)calendarWeekWithFirstSunday:(NSCalendarDate *)firstSunday
{
    return [[[CSCalendarWeek alloc] initWithFirstSunday:firstSunday] autorelease];
}

- (id)initWithFirstSunday:(NSCalendarDate *)firstSunday
{
    if (self = [super init])
    {
        [self setFirstSunday:firstSunday];
        [self setLastSaturday:[self nextSaturdayForSunday:firstSunday]];
    }
    return self;
}

#pragma mark
#pragma mark Utility Methods
#pragma mark

- (NSCalendarDate *)nextSaturdayForSunday:(NSCalendarDate *)sunday
{
    NSCalendarDate *nextSaturday = [sunday 
        dateByAddingYears:0 
        months:0 
        days:6 
        hours:0 
        minutes:0 
        seconds:0];
    return nextSaturday;
}

#pragma mark
#pragma mark Copying
#pragma mark

- (id)copyWithZone:(NSZone *)zone
{
   CSCalendarWeek *copy = [[CSCalendarWeek allocWithZone:zone] initWithFirstSunday:[self firstSunday]];
   return copy;
}

#pragma mark
#pragma mark Description
#pragma mark

- (NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"Week beginning %@",
        [[self firstSunday] descriptionWithCalendarFormat:@"%a %d %b %Y"]];
    return description;
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSCalendarDate *)firstSunday {
    return _firstSunday;
}

- (void)setFirstSunday:(NSCalendarDate *)value
{
    // make sure we've got a sunday
    if (0 != [value dayOfWeek])
    {
        NSString *eReason = [NSString stringWithFormat:@"Attempted to create CSCalendarWeek with first Sunday that is not a Sunday: first Sunday = %@, which is a %@",
                [value descriptionWithCalendarFormat:@"%e %b %Y"],
                [value descriptionWithCalendarFormat:@"%A"]];
        NSException *e = [NSException 
            exceptionWithName:CSCalendarWeekFirstSundayNotASundayExceptionName 
            reason:eReason 
            userInfo:nil];
        [e raise];
    }

    if (_firstSunday != value) {
        [_firstSunday release];
        _firstSunday = [value copy];
    }
}

- (NSCalendarDate *)lastSaturday {
    return _lastSaturday;
}

- (void)setLastSaturday:(NSCalendarDate *)value {
    if (_lastSaturday != value) {
        [_lastSaturday release];
        _lastSaturday = [value copy];
    }
}

@end
