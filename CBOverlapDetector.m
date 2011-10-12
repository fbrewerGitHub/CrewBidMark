//
//  CBOverlapDetector.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/10/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBOverlapDetector.h"
#import "CBDataModel.h"
#import "CBBlockTime.h"
#import "CBAppController.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"

unsigned NUM_OVERLAP_ARRAY_ENTRIES = 9;
unsigned NUM_OVERLAPPING_ENTRIES = 3;

@implementation CBOverlapDetector

#pragma mark INITIALIZATION

- (id)initWithDataModel:(CBDataModel *)inDataModel
{
   if (self = [super init]) {
      dataModel = inDataModel;
   }
   return self;
}

- (void)dealloc
{
   [super dealloc];
}

#pragma mark OVERLAP DETECTION

- (void)detectOverlaps
{
   BOOL lineHasOverlap = NO;
      
   NSMutableArray * combinedBlockTimes = nil;
   
   NSArray * previousMonthOverlapEntries = nil;
   NSCalendarDate * previousMonthReleaseTime = nil;
   
   NSArray * thisMonthLines = nil;
   NSEnumerator * thisMonthLinesEnumerator = nil;
   CBLine * thisMonthLine = nil;
   NSArray * thisMonthBlockTimes = nil;
   NSCalendarDate * thisMonthReportTime = nil;
   unsigned thisMonthReportTimeIndex = 0;
   unsigned index = 0;
   const unsigned NUM_COMBINED_ENTRIES = 2 * NUM_OVERLAP_ARRAY_ENTRIES - NUM_OVERLAPPING_ENTRIES;
   int minutesBetweenDutyPeriods = 0;
   NSDictionary * previousMonthOverlapEntry = nil;
   CBBlockTime * dayBlockTime = nil;
   unsigned consecutiveWorkDays = 0;
   unsigned minutesInSeven = 0;
   CBBlockTime * subtractBlockTime = nil;
   const int MIN_REST_BETWEEN_DUTY_PERIODS = 9 * 60;
   const unsigned MINUTES_PER_24_HOURS = 24 * 60;
   const unsigned MAX_CONSECUTIVE_WORK_DAYS = 6;
   const unsigned MAX_MINUTES_IN_SEVEN_DAYS = 30 * 60;

   combinedBlockTimes = [NSMutableArray arrayWithCapacity:NUM_COMBINED_ENTRIES];

   previousMonthOverlapEntries = [[self dataModel] overlapFormValues];
   previousMonthReleaseTime = [self previousMonthReleaseTimeWithOverlapEntries:previousMonthOverlapEntries];
  
//   previousMonthReleaseTime = [[self dataModel] overlapReleaseTimeValue];
   
   thisMonthLines = [[self dataModel] lines];
   thisMonthLinesEnumerator = [thisMonthLines objectEnumerator];
   while (thisMonthLine = [thisMonthLinesEnumerator nextObject]) {
   
      lineHasOverlap = NO;
      thisMonthBlockTimes = nil;
      thisMonthReportTime = nil;
      thisMonthReportTimeIndex = 0;
      consecutiveWorkDays = 0;
      minutesInSeven = 0;
      [combinedBlockTimes removeAllObjects];
      
      [self getBlockTimes:&thisMonthBlockTimes reportTime:&thisMonthReportTime reportTimeIndex:&thisMonthReportTimeIndex forLine:thisMonthLine];
      
      [thisMonthReportTime years:nil months:nil days:nil hours:nil minutes:&minutesBetweenDutyPeriods seconds:0 sinceDate:previousMonthReleaseTime];
      // test for min rest between previous month release time and this month
      // report time
      if (minutesBetweenDutyPeriods < MIN_REST_BETWEEN_DUTY_PERIODS) {
      
         lineHasOverlap = YES;
      
      } else {
      
         for (index = 0; index < NUM_COMBINED_ENTRIES && !lineHasOverlap; index++) {
         
            if (index < NUM_OVERLAP_ARRAY_ENTRIES && index < thisMonthReportTimeIndex) {
            
               previousMonthOverlapEntry = [previousMonthOverlapEntries objectAtIndex:index];
               dayBlockTime = [previousMonthOverlapEntry objectForKey:CBOverlapEntryBlockTimeKey];
            
            } else if ([thisMonthLine isBlankLine] ) {
            
               dayBlockTime = [CBBlockTime zeroBlockTime];

            } else {
            
               dayBlockTime = [thisMonthBlockTimes objectAtIndex:index - (NUM_OVERLAP_ARRAY_ENTRIES - NUM_OVERLAPPING_ENTRIES)];
            }
            
            [combinedBlockTimes addObject:dayBlockTime];
            
            if (index == thisMonthReportTimeIndex) {
            
               consecutiveWorkDays = minutesBetweenDutyPeriods < MINUTES_PER_24_HOURS ? consecutiveWorkDays + 1 : 0;

            } else {
            
               consecutiveWorkDays = [dayBlockTime isZero] ? 0 : consecutiveWorkDays + 1;
            }
            // test for more than max consecutive work days
            if (consecutiveWorkDays > MAX_CONSECUTIVE_WORK_DAYS) {
            
               lineHasOverlap = YES;

            } else {
            
               minutesInSeven += [dayBlockTime totalMinutes];
               
               if (index > 6) {
               
                  subtractBlockTime = [combinedBlockTimes objectAtIndex:index - 7];
                  minutesInSeven -= [subtractBlockTime totalMinutes];
               }
            }
            // test for exceeded 30 in 7
            if (minutesInSeven > MAX_MINUTES_IN_SEVEN_DAYS) {

               lineHasOverlap = YES;
            }
         }
      }

      [thisMonthLine setHasOverlap:lineHasOverlap];
   }
   
   [[self dataModel] sortLines];
}

- (NSCalendarDate *)previousMonthReleaseTimeWithOverlapEntries:(NSArray *)entries
{
   NSCalendarDate * previousMonthReleaseTime = nil;

   NSEnumerator * entriesEnumerator = nil;
   NSDictionary * entry = nil;
   CBBlockTime * entryBlockTime = nil;
   
   // find the release time for the first (in reverse order) non-zero
   // block time entry
   entriesEnumerator = [entries reverseObjectEnumerator];
   while ((!previousMonthReleaseTime) && (entry = [entriesEnumerator nextObject])) {
   
      entryBlockTime = [entry objectForKey:CBOverlapEntryBlockTimeKey];

      if (![entryBlockTime isZero]) {
      
         previousMonthReleaseTime = [entry objectForKey:CBOverlapEntryReleaseTimeKey];
      }
   }
   // if all entries have zero block time, use release time for first entry
   if (!previousMonthReleaseTime) {
   
      previousMonthReleaseTime = [[entries objectAtIndex:0] objectForKey:CBOverlapEntryReleaseTimeKey];
   }
   
   return previousMonthReleaseTime;
}

- (void)getBlockTimes:(NSArray **)blockTimes reportTime:(NSCalendarDate **)reportTime reportTimeIndex:(unsigned *)reportTimeIndex forLine:(CBLine *)line
{
   NSCalendarDate * month = nil;
   unsigned startIndex = 0;
   NSMutableArray * lineBlockTimes = nil;
   unsigned index = 0;
   NSDictionary * calendarObject = nil;
   CBTrip * trip = nil;
   NSCalendarDate * tripStartDate = nil;
   NSCalendarDate * tripDayDate = nil;
   int tripDayIndex = 0;
   CBTripDay * tripDay = nil;
   CBBlockTime * tripDayBlockTime = nil;
   NSCalendarDate * lineReportTime = nil;
   unsigned lineReportTimeIndex = 0;
   
   month = [[self dataModel] month];
   startIndex = [month dayOfWeek];
   lineBlockTimes = [NSMutableArray arrayWithCapacity:NUM_OVERLAP_ARRAY_ENTRIES];
   lineReportTimeIndex = NUM_OVERLAP_ARRAY_ENTRIES;
   
   for (index = startIndex; index < startIndex + NUM_OVERLAP_ARRAY_ENTRIES; index++) {
   
      calendarObject = [[line lineCalendarObjects] objectAtIndex:index];

      if ((NSNull *)calendarObject != [NSNull null]) {
      
         trip = [calendarObject objectForKey:CBLineTripNumberKey];
         tripStartDate = [calendarObject objectForKey:CBLineTripDateKey];
         tripDayDate = [month dateByAddingYears:0 months:0 days:(index - startIndex) hours:0 minutes:0 seconds:0];
         [tripDayDate years:nil months:nil days:&tripDayIndex hours:0 minutes:0 seconds:0 sinceDate:tripStartDate];
         tripDay = [[trip days] objectAtIndex:tripDayIndex];
         
         if ([trip isReserve]) {
            tripDayBlockTime = [CBBlockTime blockTimeWithMinutes:([[trip days] count] > 3 ? (5 * 60) : (6 * 60))];
         } else {
            tripDayBlockTime = [CBBlockTime blockTimeWithMinutes:[tripDay block]];
         }
         
         if (!lineReportTime) {
         
            lineReportTime = [tripDayDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:[tripDay reportTime] seconds:0];
            lineReportTimeIndex = (index - startIndex) + (NUM_OVERLAP_ARRAY_ENTRIES - NUM_OVERLAPPING_ENTRIES);

            if ([trip isReserve]) {
            
               lineReportTime = [lineReportTime dateByAddingYears:0 months:0 days:0 hours:-7 minutes:0 seconds:0];
            }
         }

      } else {
      
         tripDayBlockTime = [CBBlockTime zeroBlockTime];
      }
      
      [lineBlockTimes addObject:tripDayBlockTime];
   }
   
   *blockTimes = [NSArray arrayWithArray:lineBlockTimes];
   *reportTime = lineReportTime;
   *reportTimeIndex = lineReportTimeIndex;
}

#pragma mark ACCESSORS

- (CBDataModel *)dataModel { return dataModel; }

@end
