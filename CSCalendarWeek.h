//
//  CSCalendarWeek.h
//  CrewBid
//
//  Created by Mark Ackerman on 9/7/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSCalendarWeek : NSObject
{
    NSCalendarDate *_firstSunday;
    NSCalendarDate *_lastSaturday;
}

#pragma mark
#pragma mark Class Methods
#pragma mark

+ (NSArray *)calendarWeeksForMonth:(NSCalendarDate *)month;
+ (NSCalendarDate *)firstSundayForMonth:(NSCalendarDate *)month;
+ (NSCalendarDate *)nextSundayForSunday:(NSCalendarDate *)sunday;

#pragma mark
#pragma mark Initialization
#pragma mark

+ (id)calendarWeekWithFirstSunday:(NSCalendarDate *)firstSunday;
- (id)initWithFirstSunday:(NSCalendarDate *)firstSunday;

#pragma mark
#pragma mark Utility Methods
#pragma mark

- (NSCalendarDate *)nextSaturdayForSunday:(NSCalendarDate *)sunday;

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSCalendarDate *)firstSunday;
- (void)setFirstSunday:(NSCalendarDate *)value;

- (NSCalendarDate *)lastSaturday;
- (void)setLastSaturday:(NSCalendarDate *)value;

@end

extern NSString *CSCalendarWeekFirstSundayNotASundayExceptionName;