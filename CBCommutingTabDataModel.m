//
//  CBCommutingTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/12/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"
#import "CBBlockTime.h"
#import "CBLine.h"
#import "CBTrip.h"

@implementation CBDataModel (CBCommutingTabDataModel)

#pragma mark Initialization

- (void)initializeCommutingTabDataModel
{
    CBBlockTime *defaultCommuteBlockTime = [CBBlockTime blockTimeWithMinutes:3 * 60];
    if ([self commuteWeekdayStartValue] == nil)
    {
        [self setCommuteWeekdayStartValue:defaultCommuteBlockTime];
    }
    if ([self commuteFridayStartValue] == nil)
    {
        [self setCommuteFridayStartValue:defaultCommuteBlockTime];
    }
    if ([self commuteSaturdayStartValue] == nil)
    {
        [self setCommuteSaturdayStartValue:defaultCommuteBlockTime];
    }
    if ([self commuteSundayStartValue] == nil)
    {
        [self setCommuteSundayStartValue:defaultCommuteBlockTime];
    }
    if ([self commuteWeekdayEndValue] == nil)
    {
        [self setCommuteWeekdayEndValue:defaultCommuteBlockTime];
    }
    if ([self commuteFridayEndValue] == nil)
    {
        [self setCommuteFridayEndValue:defaultCommuteBlockTime];
    }
    if ([self commuteSaturdayEndValue] == nil)
    {
        [self setCommuteSaturdayEndValue:defaultCommuteBlockTime];
    }
    if ([self commuteSundayEndValue] == nil)
    {
        [self setCommuteSundayEndValue:defaultCommuteBlockTime];
    }
    
    [self setLinesCommutesRequiredCount];
    [self setLinesOvernightsInDomicileCount];
}

#pragma mark Actions

- (void)fillDownCommuteTimes
{
    CBBlockTime *start = [self commuteWeekdayStartValue];
    CBBlockTime *end = [self commuteWeekdayEndValue];
    BOOL startTimeChanged = NO;
    BOOL endTimeChanged = NO;
    BOOL needsSorting = NO;
    [self setSortingEnabled:NO];
    if (![[self commuteFridayStartValue] isEqualToBlockTime:start])
    {
        [self setCommuteFridayStartValue:start];
        startTimeChanged = YES;
    }
    if (![[self commuteSaturdayStartValue] isEqualToBlockTime:start])
    {
        [self setCommuteSaturdayStartValue:start];
        startTimeChanged = YES;
    }
    if (![[self commuteSundayStartValue] isEqualToBlockTime:start])
    {
        [self setCommuteSundayStartValue:start];
        startTimeChanged = YES;
    }
    if (![[self commuteFridayEndValue] isEqualToBlockTime:end])
    {
        [self setCommuteFridayEndValue:end];
        endTimeChanged = YES;
    }
    if (![[self commuteSaturdayEndValue] isEqualToBlockTime:end])
    {
        [self setCommuteSaturdayEndValue:end];
        endTimeChanged = YES;
    }
    if (![[self commuteSundayEndValue] isEqualToBlockTime:end])
    {
        [self setCommuteSundayEndValue:end];
        endTimeChanged = YES;
    }
    // select lines if necessary
    if (startTimeChanged || endTimeChanged)
    {
        [self setLinesOvernightsInDomicileCount];
        needsSorting = YES;
        if ([self commuteSelectsByOvernightsInDomicile])
        {
            [self selectLinesByOvernightsInDomicile];
        }
    }
    // adjust points if necesssary
    if ((startTimeChanged || endTimeChanged) && 
        ([self commuteAssignsPointsForCommutesRequired] ||
         [self commuteAssignsPointsForOvernightsInDomicile]))
    {
        [self adjustPointsForLines];
        // Don't need to sort now, since adjusting points causes lines to be
        // sorted
        needsSorting = NO;
    }
    if (needsSorting)
    {
        [self sortLines];
    }
    [self setSortingEnabled:YES];
}

#pragma mark Selecting

- (void)selectLinesByCommutesRequired
{
    BOOL selectsForCommutesRequired = [self commuteSelectsByCommutesRequired];
    int commutesRequiredTrigger = [self commuteSelectsByCommutesRequiredTrigger];
    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
    CBLine *line = nil;
    while (line = [lineEnum nextObject])
    {
        if (selectsForCommutesRequired && [line commutesRequiredCount] > commutesRequiredTrigger)
        {
            [line setDeselectedFlag:CBCommuteCommutesRequiredDeselectedMask];
        }
        else
        {
            [line clearDeselectedFlag:CBCommuteCommutesRequiredDeselectedMask];
        }
    }
}

- (void)selectLinesByOvernightsInDomicile
{
    BOOL selectsForOIDs = [self commuteSelectsByOvernightsInDomicile];
    int oidsTrigger = [self commuteSelectsByOvernightsInDomicileTrigger];
    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
    CBLine *line = nil;
    while (line = [lineEnum nextObject])
    {
        if (selectsForOIDs && [line overnightsInDomicileCount] > oidsTrigger)
        {
            [line setDeselectedFlag:CBCommuteOvernightsInDomicileDeselectedMask];
        }
        else
        {
            [line clearDeselectedFlag:CBCommuteOvernightsInDomicileDeselectedMask];
        }
    }
}

- (void)setLinesCommutesRequiredCount
{
    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
    BOOL adjacentTripsRequireCommute = ![self considerAdjacentTripsNotCommutable];
    CBLine *line = nil;
    while (line = [lineEnum nextObject])
    {
        int commutesRequiredCount = 0;
        NSArray *lineTrips = [line trips];
        unsigned lineTripsCount = [lineTrips count];
        unsigned lineTripIdx = 0;
        for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
        {
            NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
            
            NSDictionary *prevLineTrip = nil;
            if (lineTripIdx != 0)
            {
                prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
            }
            // If trip does not have an adjacent trip before, then it requires a 
            // commute
            if (adjacentTripsRequireCommute || ![self lineTrip:prevLineTrip isAdjacentToNextLineTrip:lineTrip])
            {
                commutesRequiredCount++;
            }
        }
        
        // set commutes required for line
        [line setCommutesRequiredCount:commutesRequiredCount];
    }
}

- (void)setLinesOvernightsInDomicileCount
{
    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
    CBLine *line = nil;
    while (line = [lineEnum nextObject])
    {
        int overnightsInDomicileRequiredCount = 0;
        NSArray *lineTrips = [line trips];
        unsigned lineTripsCount = [lineTrips count];
        unsigned lineTripIdx = 0;
        for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
        {
            NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
            
            NSDictionary *prevLineTrip = nil;
            if (lineTripIdx != 0)
            {
                prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
            }
            // If trip is not commutable at start, then it requires an overnight
            // in domicile
            if (![self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip])
            {
                overnightsInDomicileRequiredCount++;
            }
            // If trip does not have an adjacent trip after and is not commutable
            // at end, then it requires an overnight in domicile
            NSDictionary *nextLineTrip = nil;
            if (lineTripIdx < lineTripsCount - 1)
            {
                nextLineTrip = [lineTrips objectAtIndex:lineTripIdx + 1];
            }
            if (![self lineTrip:lineTrip isAdjacentToNextLineTrip:nextLineTrip] &&
                ![self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip])
            {
                overnightsInDomicileRequiredCount++;
            }
        }
        
        // set overnights in domicile for line
        [line setOvernightsInDomicileCount:overnightsInDomicileRequiredCount];
    }
}

//- (void)selectLinesByCommutableAtStart
//{
//    BOOL selectsForCommuteAtStart = [self commuteSelectStartCheckboxValue];
//    BOOL needsAllTripsCommutable = [self commuteSelectStartAllTripsValue];
//    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
//    CBLine *line = nil;
//    while (line = [lineEnum nextObject])
//    {
//        if (!selectsForCommuteAtStart)
//        {
//            [line clearDeselectedFlag:CBCommuteAtStartDeselectMask];
//        }
//        else
//        {
//            BOOL isCommutableLine = NO;
//            NSEnumerator *tripEnum = [[line trips] objectEnumerator];
//            NSDictionary *lineTrip = nil;
//            NSDictionary *prevLineTrip = nil;
//            while (lineTrip = [tripEnum nextObject])
//            {
//                BOOL isCommutableTrip = [self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip];
//                // if all trips must be commutable, stop when we reach the 
//                // first trip that is not commutable
//                if (needsAllTripsCommutable)
//                {
//                    if (!isCommutableTrip)
//                    {
//                        isCommutableLine = NO;
//                        break;
//                    }
//                    else
//                    {
//                        isCommutableLine = YES;
//                    }
//                }
//                // if only one trip need be commutable, stop when we reach the
//                // first trip that is commutable
//                else
//                {
//                    if (isCommutableTrip)
//                    {
//                        isCommutableLine = YES;
//                        break;
//                    }
//                }
//                prevLineTrip = lineTrip;
//            }
//            if (isCommutableLine)
//            {
//                [line clearDeselectedFlag:CBCommuteAtStartDeselectMask];
//            }
//            else
//            {
//                [line setDeselectedFlag:CBCommuteAtStartDeselectMask];
//            }
//        }
//    }
//}
//
//- (void)selectLinesByCommutableAtEnd
//{
//    BOOL selectsForCommuteAtEnd = [self commuteSelectEndCheckboxValue];
//    BOOL needsAllTripsCommutable = [self commuteSelectEndAllTripsValue];
//    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
//    CBLine *line = nil;
//    while (line = [lineEnum nextObject])
//    {
//        if (!selectsForCommuteAtEnd)
//        {
//            [line clearDeselectedFlag:CBCommuteAtEndDeselectMask];
//        }
//        else
//        {
//            BOOL isCommutableLine = NO;
//            NSEnumerator *tripEnum = [[line trips] reverseObjectEnumerator];
//            NSDictionary *lineTrip = nil;
//            NSDictionary *nextLineTrip = nil;
//            while (lineTrip = [tripEnum nextObject])
//            {
//                BOOL isCommutableTrip = [self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip];
//                // if all trips must be commutable, stop when we reach the 
//                // first trip that is not commutable
//                if (needsAllTripsCommutable)
//                {
//                    if (!isCommutableTrip)
//                    {
//                        isCommutableLine = NO;
//                        break;
//                    }
//                    else
//                    {
//                        isCommutableLine = YES;
//                    }
//                }
//                // if only one trip need be commutable, stop when we reach the
//                // first trip that is commutable
//                else
//                {
//                    if (isCommutableTrip)
//                    {
//                        isCommutableLine = YES;
//                        break;
//                    }
//                }
//                nextLineTrip = lineTrip;
//            }
//            if (isCommutableLine)
//            {
//                [line clearDeselectedFlag:CBCommuteAtEndDeselectMask];
//            }
//            else
//            {
//                [line setDeselectedFlag:CBCommuteAtEndDeselectMask];
//            }
//        }
//    }
//}
//
//- (void)selectLinesByCommutableAtBothEnds
//{
//    BOOL selectsForCommuteAtBothEnds = [self commuteSelectBothEndsCheckboxValue];
//    BOOL needsAllTripsCommutable = [self commuteSelectBothEndsAllTripsValue];
//    NSEnumerator *lineEnum = [[self lines] objectEnumerator];
//    CBLine *line = nil;
//    while (line = [lineEnum nextObject])
//    {
//        if (!selectsForCommuteAtBothEnds)
//        {
//            [line clearDeselectedFlag:CBCommuteAtBothEndsDeselectMask];
//        }
//        else
//        {
//            BOOL isCommutableLine = NO;
//            NSArray *lineTrips = [line trips];
//            unsigned lineTripsCount = [lineTrips count];
//            unsigned lineTripIdx = 0;
//            for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
//            {
//                NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
//                NSDictionary *prevLineTrip = nil;
//                if (lineTripIdx != 0)
//                {
//                    prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
//                }
//                NSDictionary *nextLineTrip = nil;
//                if (lineTripIdx < lineTripsCount - 1)
//                {
//                    nextLineTrip = [lineTrips objectAtIndex:lineTripIdx + 1];
//                }
//                BOOL isCommutableTrip = 
//                    [self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip] && 
//                    [self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip];
//                // if all trips must be commutable, stop when we reach the 
//                // first trip that is not commutable
//                if (needsAllTripsCommutable)
//                {
//                    if (!isCommutableTrip)
//                    {
//                        isCommutableLine = NO;
//                        break;
//                    }
//                    else
//                    {
//                        isCommutableLine = YES;
//                    }
//                }
//                // if only one trip need be commutable, stop when we reach the
//                // first trip that is commutable
//                else
//                {
//                    if (isCommutableTrip)
//                    {
//                        isCommutableLine = YES;
//                        break;
//                    }
//                }
//            }
//            if (isCommutableLine)
//            {
//                [line clearDeselectedFlag:CBCommuteAtBothEndsDeselectMask];
//            }
//            else
//            {
//                [line setDeselectedFlag:CBCommuteAtBothEndsDeselectMask];
//            }
//        }
//    }
//}

#pragma mark Points Assignment

//- (float)commuteAtStartPointsForLine:(CBLine *)line
//{
//    int commutableTripsCount = 0;
//    NSEnumerator *tripEnum = [[line trips] objectEnumerator];
//    NSDictionary *lineTrip = nil;
//    NSDictionary *prevLineTrip = nil;
//    while (lineTrip = [tripEnum nextObject])
//    {
//        // Enumerate trips for line, counting number of trips that are
//        // commutable at start
//        if ([self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip])
//        {
//            commutableTripsCount++;
//        }
//        prevLineTrip = lineTrip;
//    }
//    float commutableAtStartPoints = commutableTripsCount * [self commutePointsStartValue];
//    return commutableAtStartPoints;
//}
//
//- (float)commuteAtEndPointsForLine:(CBLine *)line
//{
//    int commutableTripsCount = 0;
//    NSEnumerator *tripEnum = [[line trips] reverseObjectEnumerator];
//    NSDictionary *lineTrip = nil;
//    NSDictionary *nextLineTrip = nil;
//    while (lineTrip = [tripEnum nextObject])
//    {
//        // Enumerate trips for line, counting number of trips that are
//        // commutable at start
//        if ([self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip])
//        {
//            commutableTripsCount++;
//        }
//        nextLineTrip = lineTrip;
//    }
//    float commutableAtEndPoints = commutableTripsCount * [self commutePointsEndValue];
//    return commutableAtEndPoints;
//}
//
//- (float)commuteAtBothEndsPointsForLine:(CBLine *)line
//{
//    int commutableTripsCount = 0;
//    NSArray *lineTrips = [line trips];
//    unsigned lineTripsCount = [lineTrips count];
//    unsigned lineTripIdx = 0;
//    for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
//    {
//        NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
//        NSDictionary *prevLineTrip = nil;
//        if (lineTripIdx != 0)
//        {
//            prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
//        }
//        NSDictionary *nextLineTrip = nil;
//        if (lineTripIdx < lineTripsCount - 1)
//        {
//            nextLineTrip = [lineTrips objectAtIndex:lineTripIdx + 1];
//        }
//        if ([self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip] && 
//            [self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip])
//        {
//            commutableTripsCount++;
//        }
//    }
//    float commutableAtBothEndsPoints = commutableTripsCount * [self commutePointsBothEndsValue];
//    return commutableAtBothEndsPoints;
//}
//
//- (float)commuteNotAtStartPointsForLine:(CBLine *)line
//{
//    int notCommutableTripsCount = 0;
//    NSEnumerator *tripEnum = [[line trips] objectEnumerator];
//    NSDictionary *lineTrip = nil;
//    NSDictionary *prevLineTrip = nil;
//    while (lineTrip = [tripEnum nextObject])
//    {
//        // Enumerate trips for line, counting number of trips that are
//        // commutable at start
//        if (![self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip])
//        {
//            notCommutableTripsCount++;
//        }
//        prevLineTrip = lineTrip;
//    }
//    float commuteNotAtStartPoints = notCommutableTripsCount * [self commutePointsNotStartValue];
//    return commuteNotAtStartPoints;
//}
//
//- (float)commuteNotAtEndPointsForLine:(CBLine *)line
//{
//    int notCommutableTripsCount = 0;
//    NSEnumerator *tripEnum = [[line trips] reverseObjectEnumerator];
//    NSDictionary *lineTrip = nil;
//    NSDictionary *nextLineTrip = nil;
//    while (lineTrip = [tripEnum nextObject])
//    {
//        // Enumerate trips for line, counting number of trips that are
//        // commutable at start
//        if (![self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip])
//        {
//            notCommutableTripsCount++;
//        }
//        nextLineTrip = lineTrip;
//    }
//    float commuteNotAtEndPoints = notCommutableTripsCount * [self commutePointsNotEndValue];
//    return commuteNotAtEndPoints;
//}
//
//- (float)commuteNotAtBothEndsPointsForLine:(CBLine *)line
//{
//    int notCommutableTripsCount = 0;
//    NSArray *lineTrips = [line trips];
//    unsigned lineTripsCount = [lineTrips count];
//    unsigned lineTripIdx = 0;
//    for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
//    {
//        NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
//        NSDictionary *prevLineTrip = nil;
//        if (lineTripIdx != 0)
//        {
//            prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
//        }
//        NSDictionary *nextLineTrip = nil;
//        if (lineTripIdx < lineTripsCount - 1)
//        {
//            nextLineTrip = [lineTrips objectAtIndex:lineTripIdx + 1];
//        }
//        if (![self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip] || 
//            ![self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip])
//        {
//            notCommutableTripsCount++;
//        }
//    }
//    float commuteNotAtBothEndsPoints = notCommutableTripsCount * [self commutePointsNotBothEndsValue];
//    return commuteNotAtBothEndsPoints;
//}
//
//- (float)commutesRequiredPointsForLine:(CBLine *)line
//{
//    int commutesRequiredCount = 0;
//    NSArray *lineTrips = [line trips];
//    unsigned lineTripsCount = [lineTrips count];
//    unsigned lineTripIdx = 0;
//    for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
//    {
//        NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
//        
//        NSDictionary *prevLineTrip = nil;
//        if (lineTripIdx != 0)
//        {
//            prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
//        }
//        // If trip does not have an adjacent trip before, then it requires a 
//        // commute
//        if (![self lineTrip:prevLineTrip isAdjacentToNextLineTrip:lineTrip])
//        {
//            commutesRequiredCount++;
//        }
//    }
//    
//    // set commutes required for line
//    [line setCommutesRequiredCount:commutesRequiredCount];
//    
//    float commutesRequiredPoints = commutesRequiredCount * commutePointsForCommutesRequired;
//    return commutesRequiredPoints;
//}
//
//- (float)overnightsInDomicileRequiredPointsForLine:(CBLine *)line
//{
//    int overnightsInDomicileRequiredCount = 0;
//    NSArray *lineTrips = [line trips];
//    unsigned lineTripsCount = [lineTrips count];
//    unsigned lineTripIdx = 0;
//    for (lineTripIdx = 0; lineTripIdx < lineTripsCount; lineTripIdx++)
//    {
//        NSDictionary *lineTrip = [lineTrips objectAtIndex:lineTripIdx];
//        
//        NSDictionary *prevLineTrip = nil;
//        if (lineTripIdx != 0)
//        {
//            prevLineTrip = [lineTrips objectAtIndex:lineTripIdx - 1];
//        }
//        // If trip is not commutable at start, then it requires an overnight
//        // in domicile
//        if (![self lineTrip:lineTrip isCommutableAtStartWithPreviousLineTrip:prevLineTrip])
//        {
//            overnightsInDomicileRequiredCount++;
//        }
//        // If trip does not have an adjacent trip after and is not commutable
//        // at end, then it requires an overnight in domicile
//        NSDictionary *nextLineTrip = nil;
//        if (lineTripIdx < lineTripsCount - 1)
//        {
//            nextLineTrip = [lineTrips objectAtIndex:lineTripIdx + 1];
//        }
//        if (![self lineTrip:lineTrip isAdjacentToNextLineTrip:nextLineTrip] &&
//            ![self lineTrip:lineTrip isCommutableAtEndWithNextLineTrip:nextLineTrip])
//        {
//            overnightsInDomicileRequiredCount++;
//        }
//    }
//    
//    // set overnights in domicile for line
//    [line setOvernightsInDomicileCount:overnightsInDomicileRequiredCount];
//    
//    float overnightsInDomicileRequiredPoints = overnightsInDomicileRequiredCount * commutePointsForOvernightsInDomicile;
//    return overnightsInDomicileRequiredPoints;
//}

#pragma mark Helper Methods

- (BOOL)lineTrip:(NSDictionary *)lineTrip isCommutableAtStartWithPreviousLineTrip:(NSDictionary *)prevLineTrip
{
    BOOL isCommutableAtStart = 
        ![self considerAdjacentTripsNotCommutable] ||
        ![self lineTrip:prevLineTrip isAdjacentToNextLineTrip:lineTrip];
    if (isCommutableAtStart)
    {
        CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
        int tripStart = [trip departureTime];
        int commuteStart = [self commuteStartTimeForLineTrip:lineTrip];
        isCommutableAtStart = commuteStart <= tripStart;
    }
    return isCommutableAtStart;
}

- (BOOL)lineTrip:(NSDictionary *)lineTrip isCommutableAtEndWithNextLineTrip:(NSDictionary *)nextLineTrip
{
    BOOL isCommutableAtEnd = 
        ![self considerAdjacentTripsNotCommutable] ||
        ![self lineTrip:lineTrip isAdjacentToNextLineTrip:nextLineTrip];
    if (isCommutableAtEnd)
    {
        CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
        int tripEnd = [trip returnTime];
        // adjust trip end time if it ends the next day before 3:00am
        if (tripEnd <= 300)
        {
            tripEnd += 2400;
        }
        int commuteEnd = [self commuteEndTimeForLineTrip:lineTrip];
        // adjust commute end time if it is before 3:00am
        if (commuteEnd <= 300)
        {
            commuteEnd += 2400;
        }
        isCommutableAtEnd = commuteEnd >= tripEnd;
    }
    return isCommutableAtEnd;
}

- (BOOL)lineTrip:(NSDictionary *)lineTrip isAdjacentToNextLineTrip:(NSDictionary *)nextLineTrip
{
    BOOL isAdjacentToNextLineTrip = NO;
    // if either line trip is nil, then they can't be adjacent
    if (lineTrip && nextLineTrip)
    {
        int tripStartDay = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
        CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
        int tripLen = [trip dutyPeriods];
        int tripEndDay = tripStartDay + tripLen - 1;
        int nextTripStartDay = [[nextLineTrip objectForKey:CBLineTripDateKey] intValue];
        // line trip is adjacent if next line trip starts on day after line trip
        // end day
        if (tripEndDay + 1 == nextTripStartDay)
        {
            isAdjacentToNextLineTrip = YES;
        }
    }
    return isAdjacentToNextLineTrip;
}

- (int)commuteStartTimeForLineTrip:(NSDictionary *)lineTrip
{
    CBBlockTime *commuteBlockTime = nil;
    int day = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
    NSCalendarDate *date = [[self month] dateByAddingYears:0 months:0 days:day - 1 hours:0 minutes:0 seconds:0];
    int dayOfWeek = [date dayOfWeek];
    switch (dayOfWeek)
    {
        case 0: // Sunday
            commuteBlockTime = [self commuteSundayStartValue];
            break;
        case 5: // Friday
            commuteBlockTime = [self commuteFridayStartValue];
            break;
        case 6: // Saturday
            commuteBlockTime = [self commuteSaturdayStartValue];
            break;
        default: // Weekday (Mon-Thu)
            commuteBlockTime = [self commuteWeekdayStartValue];
            break;
    }
    int commuteStartTime = [commuteBlockTime hours] * 100 + [commuteBlockTime minutes];
    return commuteStartTime;
}

- (int)commuteEndTimeForLineTrip:(NSDictionary *)lineTrip
{
    CBBlockTime *commuteBlockTime = nil;
    CBTrip *trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
    int day = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
    int tripLen = [trip dutyPeriods];
    NSCalendarDate *date = [[self month] dateByAddingYears:0 months:0 days:day + tripLen - 2 hours:0 minutes:0 seconds:0];
    int dayOfWeek = [date dayOfWeek];
    switch (dayOfWeek)
    {
        case 0: // Sunday
            commuteBlockTime = [self commuteSundayEndValue];
            break;
        case 5: // Friday
            commuteBlockTime = [self commuteFridayEndValue];
            break;
        case 6: // Saturday
            commuteBlockTime = [self commuteSaturdayEndValue];
            break;
        default: // Weekday (Mon-Thu)
            commuteBlockTime = [self commuteWeekdayEndValue];
            break;
    }
    int commuteEndTime = [commuteBlockTime hours] * 100 + [commuteBlockTime minutes];
    return commuteEndTime;
}

#pragma mark Accessors

//- (BOOL)commuteSelectStartCheckboxValue {
//    return commuteSelectStartCheckboxValue;
//}
//
//- (void)setCommuteSelectStartCheckboxValue:(BOOL)value {
//    if (commuteSelectStartCheckboxValue != value) {
//        commuteSelectStartCheckboxValue = value;
//
//        if (sortingEnabled)
//        {
//            [self selectLinesByCommutableAtStart];
//            [self sortLines];
//        }
//    }
//}
//
//- (BOOL)commuteSelectStartAllTripsValue {
//    return commuteSelectStartAllTripsValue;
//}
//
//- (void)setCommuteSelectStartAllTripsValue:(BOOL)value {
//    if (commuteSelectStartAllTripsValue != value) {
//        commuteSelectStartAllTripsValue = value;
//
//        if (sortingEnabled && commuteSelectStartCheckboxValue)
//        {
//            [self selectLinesByCommutableAtStart];
//            [self sortLines];
//        }
//    }
//}

- (CBBlockTime *)commuteWeekdayStartValue {
    return commuteWeekdayStartValue;
}

- (void)setCommuteWeekdayStartValue:(CBBlockTime *)value {
    if (commuteWeekdayStartValue != value) {
        [commuteWeekdayStartValue release];
        commuteWeekdayStartValue = [value copy];

        if (sortingEnabled && commuteWeekdayStartValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteFridayStartValue {
    return commuteFridayStartValue;
}

- (void)setCommuteFridayStartValue:(CBBlockTime *)value {
    if (commuteFridayStartValue != value) {
        [commuteFridayStartValue release];
        commuteFridayStartValue = [value copy];

        if (sortingEnabled && commuteFridayStartValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteSaturdayStartValue {
    return commuteSaturdayStartValue;
}

- (void)setCommuteSaturdayStartValue:(CBBlockTime *)value {
    if (commuteSaturdayStartValue != value) {
        [commuteSaturdayStartValue release];
        commuteSaturdayStartValue = [value copy];

        if (sortingEnabled && commuteSaturdayStartValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteSundayStartValue {
    return commuteSundayStartValue;
}

- (void)setCommuteSundayStartValue:(CBBlockTime *)value {
    if (commuteSundayStartValue != value) {
        [commuteSundayStartValue release];
        commuteSundayStartValue = [value copy];

        if (sortingEnabled && commuteSundayStartValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteWeekdayEndValue {
    return commuteWeekdayEndValue;
}

- (void)setCommuteWeekdayEndValue:(CBBlockTime *)value {
    if (commuteWeekdayEndValue != value) {
        [commuteWeekdayEndValue release];
        commuteWeekdayEndValue = [value copy];

        if (sortingEnabled && commuteWeekdayEndValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteFridayEndValue {
    return commuteFridayEndValue;
}

- (void)setCommuteFridayEndValue:(CBBlockTime *)value {
    if (commuteFridayEndValue != value) {
        [commuteFridayEndValue release];
        commuteFridayEndValue = [value copy];

        if (sortingEnabled && commuteFridayEndValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteSaturdayEndValue {
    return commuteSaturdayEndValue;
}

- (void)setCommuteSaturdayEndValue:(CBBlockTime *)value {
    if (commuteSaturdayEndValue != value) {
        [commuteSaturdayEndValue release];
        commuteSaturdayEndValue = [value copy];

        if (sortingEnabled && commuteSaturdayEndValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (CBBlockTime *)commuteSundayEndValue {
    return commuteSundayEndValue;
}

- (void)setCommuteSundayEndValue:(CBBlockTime *)value {
    if (commuteSundayEndValue != value) {
        [commuteSundayEndValue release];
        commuteSundayEndValue = [value copy];

        if (sortingEnabled && commuteSundayEndValue)
        {
            BOOL needsSorting = YES;
            [self setLinesOvernightsInDomicileCount];
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

- (BOOL)considerAdjacentTripsNotCommutable {
    return considerAdjacentTripsNotCommutable;
}

- (void)setConsiderAdjacentTripsNotCommutable:(BOOL)value {
    if (considerAdjacentTripsNotCommutable != value) {
        considerAdjacentTripsNotCommutable = value;
        
        if (sortingEnabled)
        {
            BOOL needsSorting = YES;
            
            // update commutes required and overnights in domicile counts
            [self setLinesCommutesRequiredCount];
            [self setLinesOvernightsInDomicileCount];
            // select lines if needed
            if ([self commuteSelectsByCommutesRequired])
            {
                [self selectLinesByCommutesRequired];
            }
            if ([self commuteSelectsByOvernightsInDomicile])
            {
                [self selectLinesByOvernightsInDomicile];
            }

            // adjust points for lines if needed
            if ([self commuteAssignsPointsForCommutesRequired] ||
                [self commuteAssignsPointsForOvernightsInDomicile])
            {
                [self adjustPointsForLines];
                needsSorting = NO;
            }
            if (needsSorting)
            {
                [self sortLines];
            }
        }
    }
}

//- (BOOL)commuteSelectEndCheckboxValue {
//    return commuteSelectEndCheckboxValue;
//}
//
//- (void)setCommuteSelectEndCheckboxValue:(BOOL)value {
//    if (commuteSelectEndCheckboxValue != value) {
//        commuteSelectEndCheckboxValue = value;
//
//        if (sortingEnabled)
//        {
//            [self selectLinesByCommutableAtEnd];
//            [self sortLines];
//        }
//    }
//}
//
//- (BOOL)commuteSelectEndAllTripsValue {
//    return commuteSelectEndAllTripsValue;
//}
//
//- (void)setCommuteSelectEndAllTripsValue:(BOOL)value {
//    if (commuteSelectEndAllTripsValue != value) {
//        commuteSelectEndAllTripsValue = value;
//
//        if (sortingEnabled && commuteSelectEndCheckboxValue)
//        {
//            [self selectLinesByCommutableAtEnd];
//            [self sortLines];
//        }
//    }
//}
//
//- (BOOL)commutePointsStartCheckboxValue {
//    return commutePointsStartCheckboxValue;
//}
//
//- (void)setCommutePointsStartCheckboxValue:(BOOL)value {
//    if (commutePointsStartCheckboxValue != value) {
//        commutePointsStartCheckboxValue = value;
//        
//        if (sortingEnabled)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (float)commutePointsStartValue {
//    return commutePointsStartValue;
//}
//
//- (void)setCommutePointsStartValue:(float)value {
//    if (commutePointsStartValue != value) {
//        commutePointsStartValue = value;
//        
//        if (sortingEnabled && commutePointsStartCheckboxValue)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (BOOL)commutePointsEndCheckboxValue {
//    return commutePointsEndCheckboxValue;
//}
//
//- (void)setCommutePointsEndCheckboxValue:(BOOL)value {
//    if (commutePointsEndCheckboxValue != value) {
//        commutePointsEndCheckboxValue = value;
//        
//        if (sortingEnabled)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (float)commutePointsEndValue {
//    return commutePointsEndValue;
//}
//
//- (void)setCommutePointsEndValue:(float)value {
//    if (commutePointsEndValue != value) {
//        commutePointsEndValue = value;
//        
//        if (sortingEnabled && commutePointsEndCheckboxValue)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (BOOL)commuteSelectBothEndsCheckboxValue {
//    return commuteSelectBothEndsCheckboxValue;
//}
//
//- (void)setCommuteSelectBothEndsCheckboxValue:(BOOL)value {
//    if (commuteSelectBothEndsCheckboxValue != value) {
//        commuteSelectBothEndsCheckboxValue = value;
//
//        if (sortingEnabled)
//        {
//            [self selectLinesByCommutableAtBothEnds];
//            [self sortLines];
//        }
//    }
//}
//
//- (BOOL)commuteSelectBothEndsAllTripsValue {
//    return commuteSelectBothEndsAllTripsValue;
//}
//
//- (void)setCommuteSelectBothEndsAllTripsValue:(BOOL)value {
//    if (commuteSelectBothEndsAllTripsValue != value) {
//        commuteSelectBothEndsAllTripsValue = value;
//
//        if (sortingEnabled && commuteSelectBothEndsCheckboxValue)
//        {
//            [self selectLinesByCommutableAtBothEnds];
//            [self sortLines];
//        }
//    }
//}
//
//- (BOOL)commutePointsBothEndsCheckboxValue {
//    return commutePointsBothEndsCheckboxValue;
//}
//
//- (void)setCommutePointsBothEndsCheckboxValue:(BOOL)value {
//    if (commutePointsBothEndsCheckboxValue != value) {
//        commutePointsBothEndsCheckboxValue = value;
//        
//        if (sortingEnabled)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (float)commutePointsBothEndsValue {
//    return commutePointsBothEndsValue;
//}
//
//- (void)setCommutePointsBothEndsValue:(float)value {
//    if (commutePointsBothEndsValue != value) {
//        commutePointsBothEndsValue = value;
//        
//        if (sortingEnabled && commutePointsBothEndsCheckboxValue)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (BOOL)commutePointsNotStartCheckboxValue {
//    return commutePointsNotStartCheckboxValue;
//}
//
//- (void)setCommutePointsNotStartCheckboxValue:(BOOL)value {
//    if (commutePointsNotStartCheckboxValue != value) {
//        commutePointsNotStartCheckboxValue = value;
//        
//        if (sortingEnabled)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (float)commutePointsNotStartValue {
//    return commutePointsNotStartValue;
//}
//
//- (void)setCommutePointsNotStartValue:(float)value {
//    if (commutePointsNotStartValue != value) {
//        commutePointsNotStartValue = value;
//        
//        if (sortingEnabled && commutePointsNotStartCheckboxValue)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (BOOL)commutePointsNotEndCheckboxValue {
//    return commutePointsNotEndCheckboxValue;
//}
//
//- (void)setCommutePointsNotEndCheckboxValue:(BOOL)value {
//    if (commutePointsNotEndCheckboxValue != value) {
//        commutePointsNotEndCheckboxValue = value;
//        
//        if (sortingEnabled)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (float)commutePointsNotEndValue {
//    return commutePointsNotEndValue;
//}
//
//- (void)setCommutePointsNotEndValue:(float)value {
//    if (commutePointsNotEndValue != value) {
//        commutePointsNotEndValue = value;
//    }
//        
//        if (sortingEnabled && commutePointsNotEndCheckboxValue)
//        {
//            [self adjustPointsForLines];
//        }
//}
//
//- (BOOL)commutePointsNotBothEndsCheckboxValue {
//    return commutePointsNotBothEndsCheckboxValue;
//}
//
//- (void)setCommutePointsNotBothEndsCheckboxValue:(BOOL)value {
//    if (commutePointsNotBothEndsCheckboxValue != value) {
//        commutePointsNotBothEndsCheckboxValue = value;
//        
//        if (sortingEnabled)
//        {
//            [self adjustPointsForLines];
//        }
//    }
//}
//
//- (float)commutePointsNotBothEndsValue {
//    return commutePointsNotBothEndsValue;
//}
//
//- (void)setCommutePointsNotBothEndsValue:(float)value {
//    if (commutePointsNotBothEndsValue != value) {
//        commutePointsNotBothEndsValue = value;
//    }
//        
//        if (sortingEnabled && commutePointsNotBothEndsCheckboxValue)
//        {
//            [self adjustPointsForLines];
//        }
//}

- (BOOL)commuteSelectsByCommutesRequired {
    return commuteSelectsByCommutesRequired;
}

- (void)setCommuteSelectsByCommutesRequired:(BOOL)value {
    if (commuteSelectsByCommutesRequired != value) {
        commuteSelectsByCommutesRequired = value;
        
        if (sortingEnabled)
        {
            [self selectLinesByCommutesRequired];
            [self sortLines];
        }
    }
}

- (int)commuteSelectsByCommutesRequiredTrigger {
    return commuteSelectsByCommutesRequiredTrigger;
}

- (void)setCommuteSelectsByCommutesRequiredTrigger:(int)value {
    if (commuteSelectsByCommutesRequiredTrigger != value) {
        commuteSelectsByCommutesRequiredTrigger = value;
        
        if (sortingEnabled && [self commuteSelectsByCommutesRequired])
        {
            [self selectLinesByCommutesRequired];
            [self sortLines];
        }
    }
}

- (BOOL)commuteSelectsByOvernightsInDomicile {
    return commuteSelectsByOvernightsInDomicile;
}

- (void)setCommuteSelectsByOvernightsInDomicile:(BOOL)value {
    if (commuteSelectsByOvernightsInDomicile != value) {
        commuteSelectsByOvernightsInDomicile = value;
        
        if (sortingEnabled)
        {
            [self selectLinesByOvernightsInDomicile];
            [self sortLines];
        }
    }
}

- (int)commuteSelectsByOvernightsInDomicileTrigger {
    return commuteSelectsByOvernightsInDomicileTrigger;
}

- (void)setCommuteSelectsByOvernightsInDomicileTrigger:(int)value {
    if (commuteSelectsByOvernightsInDomicileTrigger != value) {
        commuteSelectsByOvernightsInDomicileTrigger = value;
        
        if (sortingEnabled && [self commuteSelectsByOvernightsInDomicile])
        {
            [self selectLinesByOvernightsInDomicile];
            [self sortLines];
        }
    }
}

- (BOOL)commuteAssignsPointsForCommutesRequired {
    return commuteAssignsPointsForCommutesRequired;
}

- (void)setCommuteAssignsPointsForCommutesRequired:(BOOL)value {
    if (commuteAssignsPointsForCommutesRequired != value) {
        commuteAssignsPointsForCommutesRequired = value;
        
        if (sortingEnabled)
        {
            [self adjustPointsForLines];
        }
    }
}

- (float)commutePointsForCommutesRequired {
    return commutePointsForCommutesRequired;
}

- (void)setCommutePointsForCommutesRequired:(float)value {
    if (commutePointsForCommutesRequired != value) {
        commutePointsForCommutesRequired = value;
        
        if (sortingEnabled && commuteAssignsPointsForCommutesRequired)
        {
            [self adjustPointsForLines];
        }
    }
}

- (BOOL)commuteAssignsPointsForOvernightsInDomicile {
    return commuteAssignsPointsForOvernightsInDomicile;
}

- (void)setCommuteAssignsPointsForOvernightsInDomicile:(BOOL)value {
    if (commuteAssignsPointsForOvernightsInDomicile != value) {
        commuteAssignsPointsForOvernightsInDomicile = value;
        
        if (sortingEnabled)
        {
            [self adjustPointsForLines];
        }
    }
}

- (float)commutePointsForOvernightsInDomicile {
    return commutePointsForOvernightsInDomicile;
}

- (void)setCommutePointsForOvernightsInDomicile:(float)value {
    if (commutePointsForOvernightsInDomicile != value) {
        commutePointsForOvernightsInDomicile = value;
        
        if (sortingEnabled && commuteAssignsPointsForOvernightsInDomicile)
        {
            [self adjustPointsForLines];
        }
    }
}

@end
