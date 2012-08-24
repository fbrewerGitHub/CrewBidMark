//
//  CBFALineFileReader.m
//  CrewBid
//
//  Created by Mark on 2/22/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import "CBFALineFileReader.h"
#import "CBLine.h"

@implementation CBFALineFileReader

#pragma mark FILE READING
- (NSArray *)readLines
{
   NSMutableArray *lines = [[NSMutableArray alloc] init];
   CBLine *line = nil;
   int lineNum = 0;
   float linePay = 0.0;
   float lineBlk = 0.0;
   NSRange tripNumRange = {0, 0};
   NSRange tripDateRange = {0, 0};
   NSCalendarDate *tripDate = nil;
   NSInteger tripStartDay = 0;
   NSRange tripPosRange = {0, 0};
   NSRange tripResvStartRange = {0, 0};
   NSRange tripResvEndRange = {0, 0};
   NSString *tripNum = nil;
   NSNumber *tripDay = nil;
   NSString *tripPos = nil;
   NSString *tripResvStart = nil;
   NSString *tripResvEnd = nil;
   NSMutableArray *tripsArray = nil;
   
   tripsArray = [[NSMutableArray alloc] init];

   while ([self nextLine])
   {
      // start new line
      if ([fileLine hasPrefix:@"C"])
      {
         // not the first line
         if (lineNum)
         {
            line = [[CBLine alloc] initWithNumber:lineNum credit:linePay block:lineBlk trips:[NSArray arrayWithArray:tripsArray]];
            [lines addObject:line];
            [line release];
            [tripsArray removeAllObjects];
         }
         lineNum = [[fileLine substringWithRange:NSMakeRange(4, 3)] intValue];
         linePay = [[fileLine substringWithRange:NSMakeRange(12, 5)] floatValue] / 100;
         lineBlk = [[fileLine substringWithRange:NSMakeRange(17, 3)] floatValue] +
            [[fileLine substringWithRange:NSMakeRange(20, 2)] floatValue] / 60;
//         lineBlk = [[fileLine substringWithRange:NSMakeRange(17, 5)] floatValue] / 100;
      }
      // add trip to trips array - non-reserve trip
      else if ([fileLine hasPrefix:@"T"])
      {
         tripNumRange.location = 12;
         tripNumRange.length = 4;
		 tripDateRange.location = 16;
		 tripDateRange.length = 7;
         tripPosRange.location = 30;
         tripPosRange.length = 1;
         while (tripNumRange.location < 69)
         {
            tripNum = [fileLine substringWithRange:tripNumRange];
            if (![tripNum hasPrefix:@" "])
            {
				tripDate = [NSCalendarDate dateWithString:[fileLine substringWithRange:tripDateRange] calendarFormat:@"%d%b%y"];
				[tripDate years:NULL months:NULL days:&tripStartDay hours:NULL minutes:NULL seconds:NULL sinceDate:[self bidMonth]];
				tripStartDay++;
				tripDay = [NSNumber numberWithInt:tripStartDay];
				tripPos = [fileLine substringWithRange:tripPosRange];
				[tripsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					tripNum, CBLineTripNumberKey,
					tripDay, CBLineTripDateKey, 
					tripPos, CBLineTripPositionKey, nil]];
            }
            tripNumRange.location += 19;
			tripDateRange.location += 19;
            tripPosRange.location += 19;
         }
      }
      // add trip to trips array - reserve trip
      else if ([fileLine hasPrefix:@"A"])
      {
			tripNumRange.location = 12;
			tripNumRange.length = 4;
			tripDateRange.location = 17;
			tripDateRange.length = 7;
			tripResvStartRange.location = 24;
			tripResvStartRange.length = 4;
			tripResvEndRange.location = 35;
			tripResvEndRange.length = 4;
			tripNum = [fileLine substringWithRange:tripNumRange];
			tripDate = [NSCalendarDate dateWithString:[fileLine substringWithRange:tripDateRange] calendarFormat:@"%d%b%y"];
			[tripDate years:NULL months:NULL days:&tripStartDay hours:NULL minutes:NULL seconds:NULL sinceDate:[self bidMonth]];
			tripStartDay++;
			tripDay = [NSNumber numberWithInt:tripStartDay];
			tripResvStart = [fileLine substringWithRange:tripResvStartRange];
			tripResvEnd = [fileLine substringWithRange:tripResvEndRange];
			[tripsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				tripNum, CBLineTripNumberKey,
				tripDay, CBLineTripDateKey, 
				tripResvStart, CBLineTripReserveStartTimeKey,
				tripResvEnd, CBLineTripReserveEndTimeKey, nil]];
      }
   }
   
   // add last line
   line = [[CBLine alloc] initWithNumber:lineNum credit:linePay block:lineBlk trips:[NSArray arrayWithArray:tripsArray]];
   [lines addObject:line];
   [line release];
   
   [tripsArray release];
   
   return [NSArray arrayWithArray:[lines autorelease]];
}

#pragma mark Accessors

- (NSCalendarDate *)bidMonth {
    return [[bidMonth retain] autorelease];
}

- (void)setBidMonth:(NSCalendarDate *)value {
    if (bidMonth != value) {
        [bidMonth release];
        bidMonth = [value copy];
    }
}

@end
