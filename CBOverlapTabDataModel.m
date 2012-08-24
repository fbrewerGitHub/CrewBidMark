//
//  CBOverlapTabDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/12/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBBlockTime.h"
#import "CBOverlapDetector.h"

NSString * CBDataModelOverlapFormValuesChangedNotification = @"CBDataModel Overlap Form Values Changed Notification";
NSString * CBDataModelOverlapReleaseTimeValueChangedNotification = @"CBDataModel Overlap Release Time Value Changed Notification";
NSString * CBOverlapEntryBlockTimeKey = @"CBOverlap Entry Block Time";
NSString * CBOverlapEntryReleaseTimeKey = @"CBOverlap Entry Release Time";
NSString * CBOverlapEntryDateKey = @"CBOverlap Entry Date";
int CBOverlapNextDayHour = 3;

@implementation CBDataModel ( CBOverlapTabDataModel )

#pragma mark INITIALIZATION

// builds an array of dictionary objects that represent the block time,
// release time, and date that is used to detect overlaps and for display
// in the overlap form of the overlap tab of the main window
// 
// bulds an array where the dictionary objects represent zero block time
// and the release time is midnight on the date represented
//
// the first date represented is six days prior to the first date of the
// month of the bid period
- (NSArray *)zeroOverlapValues
{
   NSMutableArray * overlapValues = nil;
   NSCalendarDate * date = nil;
   NSDictionary * overlapValue = nil;
   unsigned index = 0;
      
   overlapValues = [NSMutableArray arrayWithCapacity:NUM_OVERLAP_ARRAY_ENTRIES];
   date = [[self month] dateByAddingYears:0 months:0 days:-6 hours:0 minutes:0 seconds:0];
   
   for (index = 0; index < NUM_OVERLAP_ARRAY_ENTRIES; index++) {

      overlapValue = [NSDictionary dictionaryWithObjectsAndKeys:[CBBlockTime zeroBlockTime], CBOverlapEntryBlockTimeKey, [date dateByAddingYears:0 months:0 days:0 hours:CBOverlapNextDayHour minutes:0 seconds:0], CBOverlapEntryReleaseTimeKey, date, CBOverlapEntryDateKey, nil];
      [overlapValues addObject:overlapValue];
      date = [date dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
   }
   
   return [NSArray arrayWithArray:overlapValues];
}

- (NSCalendarDate *)initialReleaseTime
{
   NSCalendarDate * initialReleaseTime = nil;
   NSCalendarDate * previousMonth = nil;
   int daysInMonth = 0;

   previousMonth = [[self month] dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
   // date of first cell
   daysInMonth = [[previousMonth dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0] dayOfMonth];
   initialReleaseTime = [previousMonth dateByAddingYears:0 months:0 days:(daysInMonth - 6) hours:0 minutes:0 seconds:0];
   return initialReleaseTime;
}

#pragma mark OVERLAP METHODS

- (void)detectOverlaps
{
   CBOverlapDetector * detector = nil;
   detector = [[CBOverlapDetector alloc] initWithDataModel:self];
   [detector detectOverlaps];
   [detector release];
}

- (void)setOverlapFormValuesWithPreviousMonthFile:(NSString *)path line:(int)lineNumber numberOfEntries:(unsigned)numberOfEntries
{
   NSData * fileData = nil;
   CBDataModel * previousMonthDataModel = nil;
   NSCalendarDate * previousMonth = nil;
   NSCalendarDate * lastDateOfPreviousMonth = nil;
   NSCalendarDate * startDate = nil;
   unsigned startIndex = 0;
   CBLine * line = nil;
   NSEnumerator * linesEnumerator = nil;
   NSArray * lineOverlapEntries = nil;

   fileData = [NSData dataWithContentsOfFile:path];
   previousMonthDataModel = [NSUnarchiver unarchiveObjectWithData:fileData];
   
   if (lineNumber < [[previousMonthDataModel lines] count]) {
   
      previousMonth = [previousMonthDataModel month];
      lastDateOfPreviousMonth = [previousMonth dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0];
      startDate = [lastDateOfPreviousMonth dateByAddingYears:0 months:0 days:-5 hours:0 minutes:0 seconds:0];
      startIndex = [previousMonth dayOfWeek] + [lastDateOfPreviousMonth dayOfMonth] - 6;
   
      linesEnumerator = [[previousMonthDataModel lines] objectEnumerator];

      // find line
      while ((line = [linesEnumerator nextObject]) && (lineNumber != [line number]));
      
      lineOverlapEntries = [[line lineCalendarObjects] subarrayWithRange:NSMakeRange(startIndex, numberOfEntries)];
      [self setOverlapFormValues:[self previousMonthLineOverlapEntriesWithLineCalendarObjects:lineOverlapEntries startDate:startDate]];
   }
}

- (NSArray *)previousMonthLineOverlapEntriesWithLineCalendarObjects:(NSArray *)lineCalendarObjects startDate:(NSCalendarDate *)startDate
{
   NSMutableArray * overlapEntries = nil;
   NSEnumerator * lineCalendarObjectsEnumerator = nil;
   NSDictionary * lineCalendarObject = nil;
   NSDictionary * overlapEntry = nil;
//   CBBlockTime * overlapEntryBlockTime = nil;
//   NSCalendarDate * releaseTime = nil;

   overlapEntries = [NSMutableArray arrayWithCapacity:[lineCalendarObjects count]];
   lineCalendarObjectsEnumerator = [lineCalendarObjects objectEnumerator];
//   releaseTime = startDate;
   
   while (lineCalendarObject = [lineCalendarObjectsEnumerator nextObject]) {

      overlapEntry = [self overlapEntryForLineCalendarObject:lineCalendarObject date:startDate];
      [overlapEntries addObject:overlapEntry];

//      overlapEntryBlockTime = [overlapEntry objectForKey:CBOverlapEntryBlockTimeKey];
      
//      if (![overlapEntryBlockTime isZero]) {
      
//         releaseTime = [overlapEntry objectForKey:CBOverlapEntryReleaseTimeKey];
//      }
      startDate = [startDate dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
   }
//   [self setOverlapReleaseTimeValue:releaseTime];
   
   return [NSArray arrayWithArray:overlapEntries];
}

- (NSDictionary *)overlapEntryForLineCalendarObject:(NSDictionary *)object date:(NSCalendarDate *)date
{
   NSDictionary * overlapEntry = nil;

   CBTrip * trip = nil;
   NSCalendarDate * tripStartDate = nil;
   NSInteger tripDayIndex = 0;
   CBTripDay * tripDay = nil;
   NSCalendarDate * releaseTime = nil;
   CBBlockTime * blockTime = nil;

   if ((NSNull *)object == [NSNull null]) {
      overlapEntry = [NSDictionary dictionaryWithObjectsAndKeys:[CBBlockTime zeroBlockTime], CBOverlapEntryBlockTimeKey, [date dateByAddingYears:0 months:0 days:0 hours:CBOverlapNextDayHour minutes:0 seconds:0], CBOverlapEntryReleaseTimeKey, nil];
   } else {
      trip = [object objectForKey:CBLineTripNumberKey];
      tripStartDate = [object objectForKey:CBLineTripDateKey];
      [date years:NULL months:NULL days:&tripDayIndex hours:NULL minutes:NULL seconds:NULL sinceDate:tripStartDate];
      tripDay = [[trip days] objectAtIndex:tripDayIndex];
      releaseTime = [tripStartDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:[tripDay releaseTime] seconds:0];
      
      if ([trip isReserve]) {
         blockTime = [CBBlockTime blockTimeWithMinutes:([[trip days] count] > 3 ? (5 * 60) : (6 * 60))];
         releaseTime = [releaseTime dateByAddingYears:0 months:0 days:0 hours:7 minutes:0 seconds:0];
      } else {
         blockTime = [CBBlockTime blockTimeWithMinutes:[tripDay block]];
      }
      
      overlapEntry = [NSDictionary dictionaryWithObjectsAndKeys:blockTime, CBOverlapEntryBlockTimeKey, releaseTime, CBOverlapEntryReleaseTimeKey, nil];
   }
   
   return overlapEntry;
}
/*
- (NSCalendarDate *)previousMonthOverlapEntriesStartDate
{
   NSCalendarDate * previousMonth = nil;
   NSCalendarDate * lastDateOfPreviousMonth = nil;
   NSCalendarDate * startDate = nil;
   unsigned startIndex = 0;

   previousMonth = [[self month];
   lastDateOfPreviousMonth = [previousMonth dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0];
   startDate = [lastDateOfPreviousMonth dateByAddingYears:0 months:0 days:-6 hours:0 minutes:0 seconds:0];
   startIndex = [previousMonth dayOfWeek] + [lastDateOfPreviousMonth dayOfMonth] - 6;
}

- (unsigned)previousMonthLineCalendarObjectsStartIndex
{}
*/
#pragma mark ACCESSORS

- (NSArray *)overlapFormValues { return overlapFormValues; }
- (void)setOverlapFormValues:(NSArray *)inValue
{
   if (overlapFormValues != inValue) {
      [overlapFormValues release];
      overlapFormValues = [inValue retain];
     
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelOverlapFormValuesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:overlapFormValues forKey:CBDataModelOverlapFormValuesChangedNotification]];
   }
}
/*
- (NSCalendarDate *)overlapReleaseTimeValue { return overlapReleaseTimeValue; }
- (void)setOverlapReleaseTimeValue:(NSCalendarDate *)inValue
{
   if (overlapReleaseTimeValue != inValue) {
      [overlapReleaseTimeValue release];
      overlapReleaseTimeValue = [inValue retain];
     
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelOverlapReleaseTimeValueChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:overlapReleaseTimeValue forKey:CBDataModelOverlapReleaseTimeValueChangedNotification]];
   }
}
*/
- (BOOL)noOverlapSelectCheckboxValue
{
   return noOverlapSelectCheckboxValue;
}
- (void)setNoOverlapSelectCheckboxValue:(BOOL)inValue
{
   noOverlapSelectCheckboxValue = inValue;
   if (sortingEnabled) {
      [self selectLinesByNoOverlap];
      [self sortLines];
   }
}
- (BOOL)noOverlapPointsCheckboxValue
{
   return noOverlapPointsCheckboxValue;
}
- (void)setNoOverlapPointsCheckboxValue:(BOOL)inValue
{
   noOverlapPointsCheckboxValue = inValue;
   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}
- (float)noOverlapPointsValue
{
   return noOverlapPointsValue;
}
- (void)setNoOverlapPointsValue:(float)inValue
{
   noOverlapPointsValue = inValue;
   if ([self noOverlapPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}
- (BOOL)overlapPointsCheckboxValue
{
   return overlapPointsCheckboxValue;
}
- (void)setOverlapPointsCheckboxValue:(BOOL)inValue
{
   overlapPointsCheckboxValue = inValue;
   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}
- (float)overlapPointsValue
{
   return overlapPointsValue;
}
- (void)setOverlapPointsValue:(float)inValue
{
   overlapPointsValue = inValue;
   if ([self overlapPointsCheckboxValue] == YES) {
      if (sortingEnabled) {
         [self adjustPointsForLines];
      }
   }
}

@end
