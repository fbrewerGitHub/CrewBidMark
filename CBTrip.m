//
//  CBTrip.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"

@implementation CBTrip

#pragma mark INITIALIZATION

+ (void)initialize {

   static BOOL initialized = NO;
   if (!initialized && (self == [CBTrip class])) {
      [self setVersion:2];
      initialized = YES;
   }
}

- (id)initWithNumber:(NSString *)inNumber departureStation:(NSString *)inDepartureStation departureTime:(int)inDepartureTime returnTime:(int)inReturnTime isAMTrip:(BOOL)inIsAMTrip totalBlock:(int)inTotalBlock dutyPeriods:(int)inDutyPeriods
{
   if (self = [super init]) {
      [self setNumber:inNumber];
      [self setDepartureStation:inDepartureStation];
      [self setDepartureTime:inDepartureTime];
      [self setReturnTime:inReturnTime];
      [self setIsAMTrip:inIsAMTrip];
      [self setTotalBlock:inTotalBlock];
      [self setDutyPeriods:inDutyPeriods];
   }
   return self;
}

- (void)initializeDerivedValues
{
	NSArray * tripDays = [self days];
	// tafb
	if ([tripDays count] > 0) {
		CBTripDay * firstDay = [tripDays objectAtIndex:0];
		CBTripDay * lastDay = [tripDays lastObject];
		int tripTafb = [lastDay releaseTime] - [firstDay reportTime];
		[self setTafb:tripTafb];
	}
	float tripCredit = 0.0;
	int tripBlock = 0;
	int tripDuty = 0;
   int tripReserveDayBlock = ([tripDays count] > 3 ? (5 * 60) : (6 * 60));
	NSEnumerator * daysEnumerator = [tripDays objectEnumerator];
	CBTripDay * day = nil;
	while (day = [daysEnumerator nextObject]) {
		tripCredit += [day credit];
      if ([self isReserve]) {
         tripBlock += tripReserveDayBlock;
      } else {
         tripBlock += [day block];
      }
		tripDuty += ([day releaseTime] - [day reportTime]);
	}
   // fix for case where trip's credit is greater than sum of days' credits
   if (tripCredit > credit)
   {
      [self setCredit:tripCredit];
   }
	[self setBlock:tripBlock];
	[self setDuty:tripDuty];
}

- (void)initializeDepartureAndReturnTimes
{
   // proceed only if departure and return times have not been initialized
   if (0 == [self departureTime] && 0 == [self returnTime])
   {
      CBTripDayLeg *firstLeg = [self firstLeg];
      CBTripDayLeg *lastLeg = [self lastLeg];
      int departMinutes = [firstLeg departureTime];
      int returnMinutes = [lastLeg arrivalTime];
      NSCalendarDate *arbitraryDate = [NSCalendarDate dateWithYear:2005 month:1 day:1 hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-21600]];
      NSCalendarDate *departDate = [arbitraryDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:departMinutes seconds:0];
      NSCalendarDate *returnDate = [arbitraryDate dateByAddingYears:0 months:0 days:0 hours:0 minutes:returnMinutes seconds:0];
      int depTime = [departDate hourOfDay] * 100 + [departDate minuteOfHour];
      int retTime = [returnDate hourOfDay] * 100 + [returnDate minuteOfHour];
      [self setDepartureTime:depTime];
      [self setReturnTime:retTime];
   }
}

- (void)dealloc
{
    [self setNumber:nil];
    [self setDepartureStation:nil];
    [self setDays:nil];
    [super dealloc];
}

#pragma mark STORAGE

static NSString * CBTripNumberKey = @"Trip Number";
static NSString * CBTripDepartureStationKey = @"Trip Departure Station";
static NSString * CBTripDepartureTimeKey = @"Trip Departure Time";
static NSString * CBTripReturnTimeKey = @"Trip Return Time";
static NSString * CBTripIsAmTripKey = @"Trip Is AM Trip";
static NSString * CBTripTotalBlockKey = @"Trip Total Block";
static NSString * CBTripDutyPeriodsKey = @"Trip Duty Periods";
static NSString * CBTripDaysKey = @"Trip Days";
static NSString * CBTripCreditKey = @"Trip Credit";

- (void)encodeWithCoder:(NSCoder *)encoder
{
   unsigned version = [encoder versionForClassName:@"CBTrip"];

   if ([encoder allowsKeyedCoding]) {
      [encoder encodeObject:[self number] forKey:CBTripNumberKey];
      [encoder encodeObject:[self departureStation] forKey:CBTripDepartureStationKey];
      [encoder encodeInt:[self departureTime] forKey:CBTripDepartureTimeKey];
      [encoder encodeInt:[self returnTime] forKey:CBTripReturnTimeKey];
      [encoder encodeBool:[self isAMTrip] forKey:CBTripIsAmTripKey];
      [encoder encodeInt:[self totalBlock] forKey:CBTripTotalBlockKey];
      [encoder encodeInt:[self dutyPeriods] forKey:CBTripDutyPeriodsKey];
      [encoder encodeObject:[self days] forKey:CBTripDaysKey];
      [encoder encodeFloat:[self credit] forKey:CBTripCreditKey];
   } else {
      if (version < [CBTrip version]) {
         [encoder encodeValueOfObjCType:@encode(int) at:&number];
      } else {
         [encoder encodeObject:number];
      }
      [encoder encodeObject:departureStation];
      [encoder encodeValueOfObjCType:@encode(int) at:&departureTime];
      [encoder encodeValueOfObjCType:@encode(int) at:&returnTime];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&isAMTrip];
      [encoder encodeValueOfObjCType:@encode(int) at:&totalBlock];
      [encoder encodeValueOfObjCType:@encode(int) at:&dutyPeriods];
      [encoder encodeObject:days];
      if (version > 1)
      {
         [encoder encodeValueOfObjCType:@encode(float) at:&credit];
      }
   }
}

- (id)initWithCoder:(NSCoder *)decoder
{
   unsigned version = [decoder versionForClassName:@"CBTrip"];
   int tripNumber = 0;

   self = [super init];
   if ([decoder allowsKeyedCoding]) {
      [self setNumber:[decoder decodeObjectForKey:CBTripNumberKey]];
      [self setDepartureStation:[decoder decodeObjectForKey:CBTripDepartureStationKey]];
      [self setDepartureTime:[decoder decodeIntForKey:CBTripDepartureTimeKey]];
      [self setReturnTime:[decoder decodeIntForKey:CBTripReturnTimeKey]];
      [self setIsAMTrip:[decoder decodeBoolForKey:CBTripIsAmTripKey]];
      [self setTotalBlock:[decoder decodeIntForKey:CBTripTotalBlockKey]];
      [self setDutyPeriods:[decoder decodeIntForKey:CBTripDutyPeriodsKey]];
      [self setDays:[decoder decodeObjectForKey:CBTripDaysKey]];
      [self setCredit:[decoder decodeFloatForKey:CBTripCreditKey]];
   } else {
      if (version > 0) {
         [self setNumber:[decoder decodeObject]];
      } else {
         [decoder decodeValueOfObjCType:@encode(int) at:&tripNumber];
         [self setNumber:[NSString stringWithFormat:@"%d", tripNumber]];
      }
      [self setDepartureStation:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(int) at:&departureTime];
      [decoder decodeValueOfObjCType:@encode(int) at:&returnTime];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&isAMTrip];
      [decoder decodeValueOfObjCType:@encode(int) at:&totalBlock];
      [decoder decodeValueOfObjCType:@encode(int) at:&dutyPeriods];
      [self setDays:[decoder decodeObject]];
      if (version > 1)
      {
         [decoder decodeValueOfObjCType:@encode(float) at:&credit];
      }
   }

   [self initializeDerivedValues];
   
   return self;
}

#pragma mark ACCESSORS

- (NSString *)number { return number; }
- (void)setNumber:(NSString *)inValue
{
   if (number != inValue) {
      [number release];
      number = [inValue copy];
   }
}

- (NSString *)departureStation { return departureStation; }
- (void)setDepartureStation:(NSString *)inValue
{
   if (departureStation != inValue) {
      [departureStation release];
      departureStation = [inValue copy];
   }
}

- (int)departureTime { return departureTime; }
- (void)setDepartureTime:(int)inValue
{
    departureTime = inValue;
    
    // yet another unsavory hack for pilot 2nd round bids
    // set first leg departure time and last leg arrival time, if the legs
    // array exists (the legs array should exist only if the trip's 
    // departure/return times are being set for second round trips that are 
    // missing data
    CBTripDayLeg *firstLeg = [self firstLeg];
    if (firstLeg)
    {
        div_t divResults = div(departureTime, 100);
        int firstLegDepartureTime = divResults.quot * 60 + divResults.rem;
        [firstLeg setDepartureTime:firstLegDepartureTime];
    }
}

- (int)returnTime { return returnTime; }
- (void)setReturnTime:(int)inValue
{
    returnTime = inValue;

    // yet another unsavory hack for pilot 2nd round bids
    // set first leg departure time and last leg arrival time, if the legs
    // array exists (the legs array should exist only if the trip's 
    // departure/return times are being set for second round trips that are 
    // missing data
    CBTripDayLeg *lastLeg = [self lastLeg];
    if (lastLeg)
    {
        div_t divResults = div(returnTime, 100);
        int lastLegArrivalTime = ([self dutyPeriods] - 1) * 24 * 60 + divResults.quot * 60 + divResults.rem;
        [lastLeg setArrivalTime:lastLegArrivalTime];
    }
}

- (BOOL)isAMTrip { return isAMTrip; }
- (void)setIsAMTrip:(BOOL)inValue
{
//    unsigned result = 0;
//    NSString *num = [self number];
//    result = [num rangeOfString:@"FAR"].location;
//    if (NSNotFound != result)
//    {
//        NSLog(@"Setting isAMTrip to %@ for Trip %@", inValue ? @"YES" : @"NO", num);
//    }
    isAMTrip = inValue;
}

- (int)totalBlock { return totalBlock; }
- (void)setTotalBlock:(int)inValue { totalBlock = inValue; }

- (int)dutyPeriods { return dutyPeriods; }
- (void)setDutyPeriods:(int)inValue { dutyPeriods = inValue; }

- (NSArray *)days { return days; }
- (void)setDays:(NSArray *)inValue
{
   if (days != inValue) {
      [days release];
      days = [inValue copy];
   }
}

#pragma mark DERIVED ACCESSORS

- (float)credit { return credit; }
- (void)setCredit:(float)inValue { credit = inValue; }

- (int)block { return block; }
- (void)setBlock:(int)inValue { block = inValue; }

- (int)duty { return duty; }
- (void)setDuty:(int)inValue { duty = inValue; }

- (int)tafb { return tafb; }
- (void)setTafb:(int)inValue { tafb = inValue; }

- (BOOL)isReserve
{
   // reserve trips have number with second character from W to Z
	
   // NOTE: this no longer works; some second round trips now have 'W' (and
   // possibly other chars >= 'W') as the second char of the trip number
	
   // can't use this with the old trip numbering system, so use whether
   // first leg is a reserve leg
//   char isReserveChar = [number characterAtIndex:1];
//   return (isReserveChar >= 'W'/* && isReserveChar <= 'Z'*/);
   // this doesn't work either, because it may be called while reading trip
   // file before trip's days and legs are set
//   CBTripDay * firstDay = [[self days] objectAtIndex:0];
//   CBTripDayLeg * firstLeg = [[firstDay legs] objectAtIndex:0];
//   return [firstLeg isReserve];
   // this should work
   return (0 == [self totalBlock]);
}

- (CBTripDayLeg *)firstLeg
{
	CBTripDayLeg *firstLeg = nil;
	if (days && [days count])
	{
		CBTripDay *firstDay = [days objectAtIndex:0];
		NSArray *firstDayLegs = [firstDay legs];
		if (firstDayLegs && [firstDayLegs count])
		{
			firstLeg = [firstDayLegs objectAtIndex:0];
		}
	}
	return firstLeg;
}

- (CBTripDayLeg *)lastLeg
{
 	CBTripDayLeg *lastLeg = nil;
	if (days && [days count])
	{
		CBTripDay *lastDay = [days lastObject];
		NSArray *lastDayLegs = [lastDay legs];
		if (lastDayLegs && [lastDayLegs count])
		{
			lastLeg = [lastDayLegs lastObject];
		}
	}
	return lastLeg;
}

- (void)setIsAmWithDefaultAmDepartTime:(int)defaultDepartTime arrivalTime:(int)defaultArrivalTime
{
    if (NSNotFound != [[self number] rangeOfString:@"FAR"].location)
    {
        [self setIsAMTrip:YES];
    }
    else if (NSNotFound != [[self number] rangeOfString:@"FPR"].location)
    {
        [self setIsAMTrip:NO];
    }
    else if ([self departureTime] <= defaultDepartTime && [self returnTime] <= defaultArrivalTime)
    {
        [self setIsAMTrip:YES];
    }
    else
    {
        [self setIsAMTrip:NO];
    }
}

#pragma mark DESCRIPTION

- (NSString *)descriptionWithDate:(NSCalendarDate *)date generic:(BOOL)generic faPosition:(NSString *)faPosition
{
   // adds flight attendant position to trip number
   NSMutableString *ms = [NSMutableString stringWithString:[self descriptionWithDate:date generic:generic]];
   NSRange r = [ms rangeOfString:@"Trip"];
   r.location += 10;
   r.length = 1;
   [ms replaceCharactersInRange:r withString:faPosition];
   return [NSString stringWithString:ms];
//   return [NSString stringWithFormat:@"Position %@%@", faPosition, [[self descriptionWithDate:date generic:generic] substringFromIndex:10]];
}

- (NSString *)descriptionWithDate:(NSCalendarDate *)date generic:(BOOL)generic
{
   // TEMP FIX FOR FLIGHT ATTENDANT SECOND ROUND RESERVE TRIP
   if (days && 1 == [days count]) {
      CBTripDay *firstDay = [days objectAtIndex:0];
      if (0 == [[firstDay legs] count]) {
         return [NSString stringWithFormat:@"                 Trip  %@  dated  %@", [self number], [date descriptionWithCalendarFormat:@"%d%b%y"]];
      }
   }

   // if generic is YES, then use trip day
   int tripDay = 1;
   NSString * headerString = nil;
   if (generic) {
      headerString = [NSString stringWithFormat:@"                        Trip  %@          \n Date Flight  Depart   Arrive   Eq Blk Grnd  Blk Duty Cred\n", [self number]/*, [date descriptionWithCalendarFormat:@"%d%b%y"]*/];
   } else {
      headerString = [NSString stringWithFormat:@"                 Trip  %@  dated  %@\n Date Flight  Depart   Arrive   Eq Blk Grnd  Blk Duty Cred\n", [self number], [date descriptionWithCalendarFormat:@"%d%b%y"]];
   }
   NSMutableString * daysDescriptionString = [NSMutableString stringWithCapacity:1];
   CBTripDay * day = nil;
   NSEnumerator * daysEnumerator = [[self days] objectEnumerator];
   while (day = [daysEnumerator nextObject]) {
      [daysDescriptionString appendString:[day descriptionWithDate:date tripDay:tripDay generic:generic]];
      tripDay++;
   }
   // summary
   BOOL isPilot2ndRndTrip = [self firstLeg] && [[self firstLeg] isPilotSecondRoundLeg];
   NSString * summaryString = [NSString stringWithFormat:@"             TAFB %@               Totals %@ %@ %@", 
        [self tafbString], 
        isPilot2ndRndTrip ? @"    " : [self blockString], 
        isPilot2ndRndTrip ? @"    " : [self dutyString], 
        [self payString]];
   // complete description
   NSString * descriptionString = [NSString stringWithFormat:@"%@%@%@", headerString, daysDescriptionString, summaryString];
	return descriptionString;
}

- (NSString *)clipboardTextWithStartDate:(NSCalendarDate *)startDate
{
   NSMutableString * clipboardText = [NSMutableString string];
   NSCalendarDate *date = startDate;
   CBTripDay * day = nil;
   NSEnumerator * daysEnumerator = [[self days] objectEnumerator];
   while (day = [daysEnumerator nextObject]) {
      [clipboardText appendString:[day clipboardTextWithDate:date]];
      date = [date dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
   }
   return [NSString stringWithString:clipboardText];
}

- (NSString *)tafbString
{
	NSString * tafbString = nil;
	int tripTafb = [self tafb];
	if (tripTafb > 0) {
		int hours = tripTafb / 60;
		int minutes = tripTafb % 60;
		tafbString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
	} else {
		tafbString = @"    ";
	}
	return tafbString;
}

- (NSString *)blockString
{
	NSString * blockString = nil;
	int tripBlock = [self block];
	if (tripBlock > 0) {
		int hours = tripBlock / 60;
		int minutes = tripBlock % 60;
		blockString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
	} else {
		blockString = @"    ";
	}
	return blockString;
}

- (NSString *)dutyString
{
	NSString * dutyString = nil;
	int dutyTime = [self duty];
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
	float tripPay = [self credit];
	if (tripPay > 0) {
		int payIntegerPart = (int)tripPay;
		float payFractionPart = (tripPay - payIntegerPart) * 100;
		payString = [NSString stringWithFormat:@"%2d%02.0f", payIntegerPart, payFractionPart];
	} else {
		payString = @"    ";
	}
	return payString;
}

- (NSString *)description
{
   return [NSString stringWithFormat:@"\n%@\t\t%@\t\t%4d\t\t%4d\t\t%@\t\t%4d\t\t%2d\n%@", number, departureStation, departureTime, returnTime, (isAMTrip ? @"AM" : @"PM"), totalBlock, dutyPeriods, days];
}

- (NSString *)pilotSecondRoundTripDescriptionWithDate:(NSCalendarDate *)date
{
    return [NSString string];
}

@end
