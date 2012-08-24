//
//  CBVacationTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on 9/7/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"

#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CSCalendarWeek.h"


@implementation CBDataModel (CBVacationTabDataModel)

#pragma mark
#pragma mark Initialization
#pragma mark

- (void)initializeVacationTabDataModel
{
   [self setVacationWeeks:[CSCalendarWeek calendarWeeksForMonth:[self month]]];
}

#pragma mark
#pragma mark Selecting
#pragma mark

- (void)selectLinesByVacation
{
    BOOL selects = [self vacationSelects] && 
                   [self selectedVacationWeekIndexes] && 
                   [[self selectedVacationWeekIndexes] count] > 0;
    CSCalendarWeek *calWeek = nil;
    if (selects)
    {
        calWeek = [[self vacationWeeks] objectAtIndex:[[self selectedVacationWeekIndexes] firstIndex]];
    }

    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
    CBLine *line = nil;
    while (line = [lineEnum nextObject])
    {
        if (selects)
        {
            BOOL shouldSelectLine = NO;
            switch ([self vacationEndSelect])
            {
                case CSVacationSelectAtBothEnds:
                    shouldSelectLine = [self line:line hasTripsThatTouchCalendarWeekAtBothEnds:calWeek];
                    break;
                case CSVacationSelectAtEitherEnd:
                    shouldSelectLine = 
                        [self line:line hasTripThatTouchesCalendarWeekAtStart:calWeek nextLineTripIndex:NULL] ||
                        [self line:line hasTripThatTouchesCalendarWeekAtEnd:calWeek lineTripStartIndex:0];
                    break;
                case CSVacationSelectAtStart:
                    shouldSelectLine = [self line:line hasTripThatTouchesCalendarWeekAtStart:calWeek nextLineTripIndex:NULL];
                    break;
                case CSVacationSelectAtEnd:
                    shouldSelectLine = [self line:line hasTripThatTouchesCalendarWeekAtEnd:calWeek lineTripStartIndex:0];
                    break;
                default:
                    break;
            }
            if (shouldSelectLine)
            {
                [line clearDeselectedFlag:CBVacationDeselectedMask];
            }
            else
            {
                [line setDeselectedFlag:CBVacationDeselectedMask];
            }
        }
        else
        {
            [line clearDeselectedFlag:CBVacationDeselectedMask];
        }
    }
}

- (BOOL)line:(CBLine *)line hasTripsThatTouchCalendarWeekAtBothEnds:(CSCalendarWeek *)calendarWeek
{
    BOOL hasTripsThatTouchCalendarWeekAtBothEnds = NO;
    unsigned nextLineTripIndex = 0;
    hasTripsThatTouchCalendarWeekAtBothEnds = 
        [self line:line hasTripThatTouchesCalendarWeekAtStart:calendarWeek nextLineTripIndex:&nextLineTripIndex] &&
        [self line:line hasTripThatTouchesCalendarWeekAtEnd:calendarWeek lineTripStartIndex:nextLineTripIndex];
    return hasTripsThatTouchCalendarWeekAtBothEnds;
}

- (BOOL)line:(CBLine *)line hasTripThatTouchesCalendarWeekAtStart:(CSCalendarWeek *)calendarWeek nextLineTripIndex:(unsigned *)nextIndexPtr
{
    BOOL hasTripThatTouchesCalendarWeekAtStart = NO;
    NSArray *lineTrips = [line trips];
    unsigned lineTripsCount = lineTrips ? [lineTrips count] : 0;
    unsigned lineTripIdx = 0;
    for (lineTripIdx = 0; lineTripIdx < lineTripsCount && !hasTripThatTouchesCalendarWeekAtStart; lineTripIdx++)
    {
        NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
        hasTripThatTouchesCalendarWeekAtStart = [self lineTrip:lineTrip touchesCalendarWeekAtStart:calendarWeek];
    }
    
    // index of next line trip to be used in determining if line has trip that
    // touches calendar week at end
    if (nextIndexPtr)
    {
        if (lineTripIdx < lineTripsCount - 1)
        {
            *nextIndexPtr = lineTripIdx;
        }
        else
        {
            *nextIndexPtr = NSNotFound;
        }
    }
    
    return hasTripThatTouchesCalendarWeekAtStart;
}

- (BOOL)line:(CBLine *)line hasTripThatTouchesCalendarWeekAtEnd:(CSCalendarWeek *)calendarWeek lineTripStartIndex:(unsigned)startIndex
{
    BOOL hasTripThatTouchesCalendarWeekAtEnd = NO;
    if (NSNotFound != startIndex)
    {
        NSArray *lineTrips = [line trips];
        unsigned lineTripsCount = lineTrips ? [lineTrips count] : 0;
        unsigned lineTripIdx = 0;
        for (lineTripIdx = startIndex; lineTripIdx < lineTripsCount && !hasTripThatTouchesCalendarWeekAtEnd; lineTripIdx++)
        {
            NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
            hasTripThatTouchesCalendarWeekAtEnd = [self lineTrip:lineTrip touchesCalendarWeekAtEnd:calendarWeek];
        }
    }
    
    return hasTripThatTouchesCalendarWeekAtEnd;
}

#pragma mark
#pragma mark Vacation Pay
#pragma mark

- (void)computeVacationPay
{
    if ([self selectedVacationWeekIndexes] && [[self selectedVacationWeekIndexes] count] > 0)
    {
        CSCalendarWeek *calWeek = [[self vacationWeeks] objectAtIndex:[[self selectedVacationWeekIndexes] firstIndex]];
        NSEnumerator *lineEnum = [[self lines] objectEnumerator];
        CBLine *line = nil;
        while (line = [lineEnum nextObject])
        {
            float vacPay = [self vacationPayForLine:line calendarWeek:calWeek];
//            vacPay = vacPay > 26.25 ? vacPay : 26.25;
            [line setValue:[NSNumber numberWithFloat:vacPay] forKey:@"vacationPay"];
        }
    }
}

- (float)vacationPayForLine:(CBLine *)line calendarWeek:(CSCalendarWeek *)calendarWeek
{
    float vacationPayForLine = 0.0;
    float maxVacDrop = 0.0;
    BOOL moreTrips = YES;
    NSCalendarDate *firstSunday = [calendarWeek firstSunday];
    NSCalendarDate *lastSaturday = [calendarWeek lastSaturday];
    NSEnumerator *lineTripEnum = [[line trips] objectEnumerator];
    NSDictionary *lineTrip = nil;
    while (moreTrips && (lineTrip = [lineTripEnum nextObject]))
    {
        NSCalendarDate *tripStartDate = [self tripStartDateForLineTrip:lineTrip];
        // trip may have days in calendar week if it starts on or before
        // the last saturday in the calendar week
        if (NSOrderedDescending != [tripStartDate compare:lastSaturday])
        {
            NSCalendarDate *tripEndDate = [self tripEndDateForLineTrip:lineTrip];
            // trip will have days in trip only if it ends on or after the first
            // sunday in the calendar week
            if (NSOrderedAscending != [tripEndDate compare:firstSunday])
            {
                CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
                unsigned dayIdx = 0;
                NSArray *tripDays = [trip days];
                unsigned daysCount = [tripDays count];
                for (dayIdx = 0; dayIdx < daysCount; dayIdx++)
                {
                    CBTripDay *tripDay = [tripDays objectAtIndex:dayIdx];
                    NSCalendarDate *dayDate = [tripStartDate 
                        dateByAddingYears:0 
                        months:0 
                        days:dayIdx 
                        hours:0 
                        minutes:0 
                        seconds:0];
                    // add vacation drop if day date is on or after the first
                    // sunday and is on or before the last saturday of the 
                    // calendar week
                    if (NSOrderedAscending != [dayDate compare:firstSunday] &&
                        NSOrderedDescending != [dayDate compare:lastSaturday])
                    {
                        vacationPayForLine += [tripDay credit];
                    }
                    else
                    {
                        maxVacDrop += [tripDay credit];
                    }
                }
            }
        }
        // no more trips possible in calendar week once the trip start date is
        // beyond last saturday in calendar week
        else
        {
            moreTrips = NO;
        }
    }
    [line setValue:[NSNumber numberWithFloat:maxVacDrop] forKey:@"vacationDrop"];
    
    int lineVacDaysOff = [self vacationDaysOffForLine:line calendarWeek:calendarWeek];
    [line setValue:[NSNumber numberWithInt:lineVacDaysOff] forKey:@"vacationDaysOff"];
//    NSLog(@"Line %3d vacation pay: %2.2f max vacation drop: %2.2f", [line number], vacationPayForLine, maxVacDrop);

    float linePayWithVacation = [line credit] - maxVacDrop;
    if (vacationPayForLine < 26.25)
    {
        linePayWithVacation += 26.25 - vacationPayForLine;
    }
    [line setValue:[NSNumber numberWithFloat:linePayWithVacation] forKey:@"payWithVacation"];
    
    return vacationPayForLine;
}

#pragma mark
#pragma mark Vacation Days Off
#pragma mark

- (int)vacationDaysOffForLine:(CBLine *)line calendarWeek:(CSCalendarWeek *)calendarWeek
{
    NSInteger vacationDaysOff = 0;
    NSCalendarDate *lastTripDateBefore = [self lastTripDateForLine:line beforeCalendarWeek:calendarWeek];
    NSCalendarDate *firstTripDateAfter = [self firstTripDateForLine:line afterCalendarWeek:calendarWeek];
    if (![line isBlankLine])
    {
        [firstTripDateAfter years:NULL months:NULL days:&vacationDaysOff hours:NULL minutes:NULL seconds:NULL sinceDate:lastTripDateBefore];
        vacationDaysOff--;
    }
    
//    NSLog(@"Line %3d last date before: %@ first date after: %@", [line number], [lastTripDateBefore descriptionWithCalendarFormat:@"%d %b"], [firstTripDateAfter descriptionWithCalendarFormat:@"%d %b"]);

    return vacationDaysOff;
}

#pragma mark
#pragma mark Utility Methods
#pragma mark

- (NSCalendarDate *)lastTripDateForLine:(CBLine *)line beforeCalendarWeek:(CSCalendarWeek *)calendarWeek
{
    NSCalendarDate *endOfPreviousMonth = [[self month] dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
    NSCalendarDate *lastTripDateBefore = endOfPreviousMonth;
    BOOL isPilotSecondRoundBid = [self isPilotSecondRoundBid];
    NSCalendarDate *firstSunday = [calendarWeek firstSunday];
    // If the first sunday of the calendar week on or before the end of the 
    // previous month, then the last trip date before the calendar must be the 
    // end of the previous month. In that case, we need do nothing since the
    // last trip date before the calendar week has already been set to the
    // end of the previous month.
    if (NSOrderedDescending == [firstSunday compare:endOfPreviousMonth])
    {
        NSEnumerator *lineTripEnum = [[line trips] objectEnumerator];
        NSDictionary *lineTrip = nil;
        NSDictionary *previousLineTrip = nil;
        while (lineTrip = [lineTripEnum nextObject])
        {
            // Stop when the first trip with an end date on or after the first
            // sunday in the week is found.
            NSCalendarDate *tripEndDate = [self tripEndDateForLineTrip:lineTrip];
            if (NSOrderedAscending != [tripEndDate compare:firstSunday])
            {
                // If the trip is a pilot second round reserve trip, then it
                // must be determined if the trip starts before the first
                // sunday of the week; if so, then the first date before the
                // first sunday will be the last trip date before the calendar
                // week.
                NSCalendarDate *tripStartDate = [self tripStartDateForLineTrip:lineTrip];
                if (isPilotSecondRoundBid && 
                    [self isReserveLineTrip:lineTrip] &&
                    NSOrderedAscending == [tripStartDate compare:firstSunday])
                {
                    lastTripDateBefore = [firstSunday 
                        dateByAddingYears:0 
                        months:0 
                        days:-1 
                        hours:0 
                        minutes:0 
                        seconds:0];
                }
                // NEED SOME COMMENTS HERE
                else if (previousLineTrip)
                {
                    lastTripDateBefore = [self tripEndDateForLineTrip:previousLineTrip];
                }
                break;
            }
            previousLineTrip = lineTrip;
        }
        // If we haven't found a trip with end date on or after the first sunday
        // in the calendar week (i.e., we've reached the end of the array of
        // line trips and therefore lineTrip is nil, then the end date of the 
        // last trip in the list (previousLineTrip) will be the last trip date
        // before the calendar week
        if (nil == lineTrip)
        {
            lastTripDateBefore = [self tripEndDateForLineTrip:previousLineTrip];
        }
    }
    return lastTripDateBefore;
}

- (NSCalendarDate *)firstTripDateForLine:(CBLine *)line afterCalendarWeek:(CSCalendarWeek *)calendarWeek
{
    NSCalendarDate *startOfNextMonth = [[self month] dateByAddingYears:0 months:1 days:0 hours:0 minutes:0 seconds:0];
    NSCalendarDate *firstTripDateAfter = startOfNextMonth;
    NSCalendarDate *lastSaturday = [calendarWeek lastSaturday];
    BOOL isPilotSecondRoundBid = [self isPilotSecondRoundBid];
    if (NSOrderedAscending == [lastSaturday compare:startOfNextMonth])
    {
        NSEnumerator *lineTripEnum = [[line trips] reverseObjectEnumerator];
        NSDictionary *lineTrip = nil;
        NSDictionary *nextLineTrip = nil;
        while (lineTrip = [lineTripEnum nextObject])
        {
            NSCalendarDate *tripStartDate = [self tripStartDateForLineTrip:lineTrip];
            // trip starts on or before first saturday
            if (NSOrderedDescending != [tripStartDate compare:lastSaturday])
            {
                NSCalendarDate *tripEndDate = [self tripEndDateForLineTrip:lineTrip];
                if (isPilotSecondRoundBid &&
                    [self isReserveLineTrip:lineTrip] &&
                    NSOrderedDescending == [tripEndDate compare:lastSaturday])
                {
                    firstTripDateAfter = [lastSaturday 
                        dateByAddingYears:0 
                        months:0 
                        days:1 
                        hours:0 
                        minutes:0 
                        seconds:0];
                }
                else if (nextLineTrip)
                {
                    firstTripDateAfter = [self tripStartDateForLineTrip:nextLineTrip];
                }
                break;
            }
            nextLineTrip = lineTrip;
        }
    }
    return firstTripDateAfter;
}

- (BOOL)lineTrip:(NSDictionary *)lineTrip touchesCalendarWeekAtStart:(CSCalendarWeek *)calendarWeek
{
    NSCalendarDate *tripStartDate = [self tripStartDateForLineTrip:lineTrip];
    NSCalendarDate *tripEndDate = [self tripEndDateForLineTrip:lineTrip];
    // trip touches calendar week at start if trip starts before calendar
    // week's first sunday and trip ends on or after calendar week's first
    // sunday
    BOOL touchesCalendarWeekAtStart = 
        NSOrderedAscending == [tripStartDate compare:[calendarWeek firstSunday]] &&
        NSOrderedAscending != [tripEndDate compare:[calendarWeek firstSunday]];
    return touchesCalendarWeekAtStart;
}

- (BOOL)lineTrip:(NSDictionary *)lineTrip touchesCalendarWeekAtEnd:(CSCalendarWeek *)calendarWeek
{
    NSCalendarDate *tripStartDate = [self tripStartDateForLineTrip:lineTrip];
    NSCalendarDate *tripEndDate = [self tripEndDateForLineTrip:lineTrip];
    // trip touches calendar week at end if trip starts on or before
    // calendar week's last saturday and ends after calendar week's
    // last saturday
    BOOL touchesCalendarWeekAtEnd = 
        NSOrderedDescending != [tripStartDate compare:[calendarWeek lastSaturday]] &&
        NSOrderedDescending == [tripEndDate compare:[calendarWeek lastSaturday]];
    return touchesCalendarWeekAtEnd;
}

- (NSCalendarDate *)tripStartDateForLineTrip:(NSDictionary *)lineTrip
{
    int day = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
    NSCalendarDate *tripStartDate = [[self month] 
        dateByAddingYears:0 
        months:0 
        days:day - 1 
        hours:0 
        minutes:0 
        seconds:0];
    return tripStartDate;
}

- (NSCalendarDate *)tripEndDateForLineTrip:(NSDictionary *)lineTrip
{
    int day = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
    CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
    int tripLen = [trip dutyPeriods];
    NSCalendarDate *tripEndDate = [[self month] 
        dateByAddingYears:0 
        months:0 
        days:day + tripLen - 2 
        hours:0 
        minutes:0 
        seconds:0];
    return tripEndDate;
}

- (BOOL)isReserveLineTrip:(NSDictionary *)lineTrip
{
    CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
    BOOL isReserveTrip = [trip isReserve];
    return isReserveTrip;
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSArray *)vacationWeeks {
    return vacationWeeks;
}

- (void)setVacationWeeks:(NSArray *)value {
    if (vacationWeeks != value) {
        [vacationWeeks release];
        vacationWeeks = [value copy];
    }
}

- (NSIndexSet *)selectedVacationWeekIndexes {
    return selectedVacationWeekIndexes;
}

- (void)setSelectedVacationWeekIndexes:(NSIndexSet *)value {
    if (selectedVacationWeekIndexes != value) {
        [selectedVacationWeekIndexes release];
        selectedVacationWeekIndexes = [value copy];
        
        if (value)
        {
            [self computeVacationPay];
            
            if ([self vacationSelects])
            {
                [self selectLinesByVacation];
            }
            
            if (sortingEnabled)
            {
                [self sortLines];
            }
        }
    }
}

- (BOOL)vacationSelects {
    return vacationSelects;
}

- (void)setVacationSelects:(BOOL)value {
    if (vacationSelects != value) {
        vacationSelects = value;
        
        [self selectLinesByVacation];

        if (sortingEnabled)
        {
            [self sortLines];
        }
    }
}

- (CSVacationSelectEndChoice)vacationEndSelect {
    return vacationEndSelect;
}

- (void)setVacationEndSelect:(CSVacationSelectEndChoice)value {
    if (vacationEndSelect != value) {
        vacationEndSelect = value;
        
        [self selectLinesByVacation];

        if (sortingEnabled)
        {
            [self sortLines];
        }
    }
}

@end
