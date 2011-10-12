//
//  CBTripDay.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBTripDay.h"
#import "CBTripDayLeg.h"

@implementation CBTripDay

#pragma mark INITIALIZATION

- (id)initWithCredit:(float)inCredit legs:(NSArray *)inLegs {
   if (self = [super init]) {
      [self setCredit:inCredit];
		[self setLegs:inLegs];
   }
   return self;
}

- (void)initializeDerivedValues
{
	NSArray * dayLegs = [self legs];
   CBTripDayLeg * firstLeg = nil;
   CBTripDayLeg * lastLeg = nil;
   int dayReportTime = 0;
   int dayReleaseTime = 0;
   int dayBlock = 0;
   NSEnumerator * legsEnumerator = nil;
   CBTripDayLeg * leg = nil;
	// report time and release time
	if ([dayLegs count] > 0) {
		firstLeg = [dayLegs objectAtIndex:0];
		lastLeg = [dayLegs lastObject];
      if ([firstLeg isReserve] && ![firstLeg isPilotSecondRoundLeg]) {
         dayReportTime = [firstLeg departureTime];
         dayReleaseTime = [lastLeg arrivalTime];
      } else {
         dayReportTime = [firstLeg departureTime] - ([self isFirstDay] ? 60 : 30);
         dayReleaseTime = [lastLeg arrivalTime] + 30;
      }
		[self setReportTime:dayReportTime];
		[self setReleaseTime:dayReleaseTime];
	}
	// block time
	legsEnumerator = [dayLegs objectEnumerator];
	while (leg = [legsEnumerator nextObject]) {
		if (![leg isReserve] && ![leg isDeadhead] && ![leg isPilotSecondRoundLeg]) {
			int legBlock = [leg arrivalTime] - [leg departureTime];
			dayBlock += legBlock;
		}
	}
	[self setBlock:dayBlock];
}

- (void)dealloc
{
   [legs release];
   [super dealloc];
}

#pragma mark STORAGE

static NSString * CBTripDayCreditKey = @"Trip Day Credit";
static NSString * CBTripDayLegsKey = @"Trip Day Legs";
static NSString * CBTripDayIsFirstDayKey = @"Trip Day Is First Day";

- (void)encodeWithCoder:(NSCoder *)encoder
{
   if ([encoder allowsKeyedCoding]) {
      [encoder encodeFloat:[self credit] forKey:CBTripDayCreditKey];
      [encoder encodeObject:[self legs] forKey:CBTripDayLegsKey];
      [encoder encodeBool:[self isFirstDay] forKey:CBTripDayIsFirstDayKey];
   } else {
      [encoder encodeValueOfObjCType:@encode(float) at:&credit];
      [encoder encodeObject:legs];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&isFirstDay];
   }
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super init];
   if ([decoder allowsKeyedCoding]) {
      [self setCredit:[decoder decodeFloatForKey:CBTripDayCreditKey]];
      [self setLegs:[decoder decodeObjectForKey:CBTripDayLegsKey]];
      [self setIsFirstDay:[decoder decodeBoolForKey:CBTripDayIsFirstDayKey]];
   } else {
      [decoder decodeValueOfObjCType:@encode(float) at:&credit];
      [self setLegs:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&isFirstDay];
   }
   [self initializeDerivedValues];
   return self;
}

#pragma mark ACCESSORS

- (float)credit { return credit; }
- (void)setCredit:(float)inValue { credit = inValue; }

- (NSArray *)legs { return legs; }
- (void)setLegs:(NSArray *)inValue
{
   if (legs != inValue) {
      [legs release];
      legs = [inValue copy];
   }
}

- (BOOL)isFirstDay { return isFirstDay; }
- (void)setIsFirstDay:(BOOL)inValue { isFirstDay = inValue; }
- (int)reportTime { return reportTime; }
- (void)setReportTime:(int)inValue { reportTime = inValue; }
- (int)releaseTime { return releaseTime; }
- (void)setReleaseTime:(int)inValue { releaseTime = inValue; }

- (int)block { return block; }
- (void)setBlock:(int)inValue { block = inValue; }

#pragma mark DESCRIPTION

- (NSString *)shortCalendarText
{
    NSString * shortCalendarText = nil;
    NSArray * dayLegs = [self legs];
    if (dayLegs && [dayLegs count] > 0)
    {
        CBTripDayLeg * firstLeg = [dayLegs objectAtIndex:0];
        CBTripDayLeg * lastLeg = [dayLegs lastObject];
        NSCalendarDate * date = [NSCalendarDate dateWithYear:2004 month:1 day:1 hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-21600]];
        NSCalendarDate * depDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:[firstLeg  departureTime] seconds:0];
        NSCalendarDate * arrDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:[lastLeg arrivalTime] seconds:0];
        NSString * depTimeString = [depDate descriptionWithCalendarFormat:@"%H%M"];
        NSString * arrTimeString = [arrDate descriptionWithCalendarFormat:@"%H%M"];
        // second round trip day has 0 for departure/arrival times for legs
        shortCalendarText = [NSString stringWithFormat:@"%@\n%@\n%@", 
            [firstLeg departureTime] > 0 ? depTimeString : @"", 
            [lastLeg arrivalCity], 
            [lastLeg arrivalTime] > 0 ? arrTimeString : @""];
    }
    return shortCalendarText;
}

- (NSString *)printCalendarText
{
   NSString *printCalendarText = nil;
   NSArray *dayLegs = [self legs];
   if (dayLegs && [dayLegs count] > 0)
   {
        CBTripDayLeg *firstLeg = [dayLegs objectAtIndex:0];
        CBTripDayLeg *lastLeg = [dayLegs lastObject];
        NSCalendarDate *date = [NSCalendarDate dateWithYear:2004 month:1 day:1 hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-21600]];
        NSCalendarDate *depDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:[firstLeg  departureTime] seconds:0];
        NSCalendarDate *arrDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:[lastLeg arrivalTime] seconds:0];
        NSString *depTimeString = [depDate descriptionWithCalendarFormat:@"%H%M"];
        NSString *arrTimeString = [arrDate descriptionWithCalendarFormat:@"%H%M"];
        // second round trip day has 0 for departure/arrival times for legs
        printCalendarText = [NSString stringWithFormat:@"%@ %@\n%@ %@", 
            [firstLeg departureCity], 
            [firstLeg departureTime] > 0 ? depTimeString : @"", 
            [lastLeg arrivalCity], 
            [lastLeg arrivalTime] > 0 ? arrTimeString : @""];
    }
    return printCalendarText;
}

- (NSString *)descriptionWithDate:(NSCalendarDate *)date tripDay:(int)day generic:(BOOL)generic
{
    NSMutableString * descriptionString = [NSMutableString stringWithCapacity:1];
    CBTripDayLeg * leg = nil;
    BOOL isPilot2ndRndDay = NO;
    NSEnumerator * legsEnumerator = [[self legs] objectEnumerator];
    while (leg = [legsEnumerator nextObject])
    {
        if ([leg isPilotSecondRoundLeg]) 
        {
            isPilot2ndRndDay = YES;
        }
        NSString * legDescriptionString = [leg descriptionWithDate:date tripDay:day generic:generic];
        [descriptionString appendString:legDescriptionString];
    }
    if (!isPilot2ndRndDay)
    {
        NSString * summaryString = [NSString stringWithFormat:@"             Rpt %@ Rls %@ %@ %@ %@ %@\n", [self reportTimeWithDate:date], [self releaseTimeWithDate:date], [self layoverString], [self blockString], [self dutyString], [self payString]];
        [descriptionString appendString:summaryString];
    }
       return [NSString stringWithString:descriptionString];
}

- (NSString *)clipboardTextWithDate:(NSCalendarDate *)date
{
   NSMutableString *clipboardText = [NSMutableString string];
   CBTripDayLeg * leg = nil;
   NSEnumerator * legsEnumerator = [[self legs] objectEnumerator];
   while (leg = [legsEnumerator nextObject]) {
      if (![leg isDeadhead] && ![leg isReserve]) {
         [clipboardText appendString:[leg clipboardTextWithDate:date]];
      }
   }
   return [NSString stringWithString:clipboardText];
}

- (NSString *)reportTimeWithDate:(NSCalendarDate *)date
{
	NSCalendarDate * reportTimeDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:[self reportTime] seconds:0];
	NSString	* reportTimeString = [reportTimeDate descriptionWithCalendarFormat:@"%H%M"];
   return reportTimeString;
}

- (NSString *)releaseTimeWithDate:(NSCalendarDate *)date
{
 	NSCalendarDate * releaseTimeDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:[self releaseTime] seconds:0];
	NSString * releaseTimeString = [releaseTimeDate descriptionWithCalendarFormat:@"%H%M"];
   return releaseTimeString;
}

- (NSString *)layoverString
{
   NSString * layoverString = nil;
	NSArray * dayLegs = [self legs];
	if (dayLegs && [dayLegs count] > 0) {
		CBTripDayLeg * lastLeg = [dayLegs lastObject];
		NSString * legLayoverString = [lastLeg layoverTimeString];
		int groundTime = [lastLeg groundTime];
		if (0 == groundTime) {
			layoverString = @"            ";
		} else {
			layoverString = [NSString stringWithFormat:@"L/O %@ %@", [lastLeg arrivalCity], legLayoverString];
		}
	}
   return layoverString;
}

- (NSString *)blockString
{
	NSString * blockString = nil;
	int dayBlock = [self block];
	if (dayBlock > 0) {
		int hours = dayBlock / 60;
		int minutes = dayBlock % 60;
		blockString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
	} else {
		blockString = @"    ";
	}
	return blockString;
}

- (NSString *)dutyString
{
	NSString * dutyString = nil;
	int dutyTime = [self releaseTime] - [self reportTime];
	if (dutyTime > 0) {
		int hours = dutyTime / 60;
		int minutes = dutyTime % 60;
		dutyString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
	} else {
		dutyString = @"    ";
	}
	return dutyString;
}
- (NSString *)payString
{
	NSString * payString = nil;
	float dayPay = [self credit];
	if (dayPay > 0) {
		int payIntegerPart = (int)dayPay;
		float payFractionPart = (dayPay - payIntegerPart) * 100;
		payString = [NSString stringWithFormat:@"%2d%02.0f", payIntegerPart, payFractionPart];
	} else {
		payString = @"    ";
	}
	return payString;
}

- (NSString *)description
{
   return [NSString stringWithFormat:@"\n%1.2f\n%@", credit, legs];
}

@end
