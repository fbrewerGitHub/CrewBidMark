//
//  CBTripDayLeg.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBTripDayLeg.h"


@implementation CBTripDayLeg

#pragma mark INITIALIZATION

- (id)initWithFlightNumber:(NSString *)inFlightNumber departureCity:(NSString *)inDepartureCity departureTime:(int)inDepartureTime arrivalCity:(NSString *)inArrivalCity arrivalTime:(int)inArrivalTime equipmentType:(NSString *)inEquipmentType isDeadhead:(BOOL)inIsDeadhead isAircraftChange:(BOOL)inIsAircraftChange
{
   if (self = [super init]) {
      [self setFlightNumber:inFlightNumber];
      [self setDepartureCity:inDepartureCity];
      [self setDepartureTime:inDepartureTime];
      [self setArrivalCity:inArrivalCity];
      [self setArrivalTime:inArrivalTime];
      [self setEquipmentType:inEquipmentType];
      [self setIsDeadhead:inIsDeadhead];
      [self setIsAircraftChange:inIsAircraftChange];
   }
   return self;
}

- (void)dealloc
{
   [flightNumber release];
   [departureCity release];
   [arrivalCity release];
   [equipmentType release];
   [super dealloc];
}

#pragma mark STORAGE

static NSString * CBTripDayLegFlightNumberKey = @"Leg Flight Number";
static NSString * CBTripDayLegDepartureCityKey = @"Leg Departure City";
static NSString * CBTripDayLegDepartureTimeKey = @"Leg Departure Time";
static NSString * CBTripDayLegArrivalCityKey = @"Leg Arrival City";
static NSString * CBTripDayLegArrivalTimeKey = @"Leg Arrival Time";
static NSString * CBTripDayLegEquipmentTypeKey = @"Leg Equipment Type";
static NSString * CBTripDayLegIsDeadheadKey = @"Leg Is Deadhead";
static NSString * CBTripDayLegIsAircraftChangeKey = @"Leg Is Aircraft Change";
static NSString * CBTripDayLegGroundTimeKey = @"Leg Ground Time";

- (void)encodeWithCoder:(NSCoder *)encoder
{
   if ([encoder allowsKeyedCoding]) {
      [encoder encodeObject:[self flightNumber] forKey:CBTripDayLegFlightNumberKey];
      [encoder encodeObject:[self departureCity] forKey:CBTripDayLegDepartureCityKey];
      [encoder encodeInt:[self departureTime] forKey:CBTripDayLegDepartureTimeKey];
      [encoder encodeObject:[self arrivalCity] forKey:CBTripDayLegArrivalCityKey];
      [encoder encodeInt:[self arrivalTime] forKey:CBTripDayLegArrivalTimeKey];
      [encoder encodeObject:[self equipmentType] forKey:CBTripDayLegEquipmentTypeKey];
      [encoder encodeBool:[self isDeadhead] forKey:CBTripDayLegIsDeadheadKey];
      [encoder encodeBool:[self isAircraftChange] forKey:CBTripDayLegIsAircraftChangeKey];
      [encoder encodeInt:[self groundTime] forKey:CBTripDayLegGroundTimeKey];
   } else {
      [encoder encodeObject:flightNumber];
      [encoder encodeObject:departureCity];
      [encoder encodeValueOfObjCType:@encode(int) at:&departureTime];
      [encoder encodeObject:arrivalCity];
      [encoder encodeValueOfObjCType:@encode(int) at:&arrivalTime];
      [encoder encodeObject:equipmentType];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&isDeadhead];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&isAircraftChange];
      [encoder encodeValueOfObjCType:@encode(int) at:&groundTime];
   }
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super init];
   if ([decoder allowsKeyedCoding]) {
      [self setFlightNumber:[decoder decodeObjectForKey:CBTripDayLegFlightNumberKey]];
      [self setDepartureCity:[decoder decodeObjectForKey:CBTripDayLegDepartureCityKey]];
      [self setDepartureTime:[decoder decodeIntForKey:CBTripDayLegDepartureTimeKey]];
      [self setArrivalCity:[decoder decodeObjectForKey:CBTripDayLegArrivalCityKey]];
      [self setArrivalTime:[decoder decodeIntForKey:CBTripDayLegArrivalTimeKey]];
      [self setEquipmentType:[decoder decodeObjectForKey:CBTripDayLegEquipmentTypeKey]];
      [self setIsDeadhead:[decoder decodeBoolForKey:CBTripDayLegIsDeadheadKey]];
      [self setIsAircraftChange:[decoder decodeBoolForKey:CBTripDayLegIsAircraftChangeKey]];
      [self setGroundTime:[decoder decodeIntForKey:CBTripDayLegGroundTimeKey]];
   } else {
      [self setFlightNumber:[decoder decodeObject]];
      [self setDepartureCity:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(int) at:&departureTime];
      [self setArrivalCity:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(int) at:&arrivalTime];
      [self setEquipmentType:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&isDeadhead];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&isAircraftChange];
      [decoder decodeValueOfObjCType:@encode(int) at:&groundTime];
   }
   return self;
}

#pragma mark DERIVED VALUES

- (NSString *)blockTimeString
{
	NSString * blockTimeString = nil;
	int block = [self arrivalTime] - [self departureTime];
	int hours = block / 60;
	int minutes = block % 60;
   
   if ([self isReserve] || [self isPilotSecondRoundLeg] /*0 == block second round trip*/) {
      blockTimeString = @"    ";
	} else if (hours > 0) {
		blockTimeString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
	} else {
		blockTimeString = [NSString stringWithFormat:@"  %02d", minutes];
	}
	[NSString stringWithFormat:@"%2d%02d", hours, minutes];
	return blockTimeString;
}

- (NSString *)groundTimeString
{
	int ground = [self groundTime];
	int hours = ground / 60;
	int minutes = ground % 60;
	NSString * groundTimeString = nil;
	if (ground == 0) {
		groundTimeString = @"   0";
	} else if (hours > 0) {
		groundTimeString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
	} else {
		groundTimeString = [NSString stringWithFormat:@"  %02d", minutes];
	}
	return groundTimeString;
}

- (NSString *)layoverTimeString
{
   NSString * layoverTimeString = nil;
   int ground = [self groundTime];
   int layoverMinutes = 0;
   int hours = 0;
   int minutes = 0;
	// if ground time is zero, then this is last leg of a trip
   if (0 == ground) {
      layoverTimeString = @"    ";
   } else {
      if ([self isReserve]) {
         layoverMinutes = ground;
      } else {
         // shorten layover by 60 minutes to account for preflight and postflight
         layoverMinutes = ground - 60;
      }
		hours = layoverMinutes / 60;
		minutes = layoverMinutes % 60;
      layoverTimeString = [NSString stringWithFormat:@"%2d%02d", hours, minutes];
   }
   return layoverTimeString;
}

- (BOOL)isReserve
{
	BOOL isReserve = NO;
	if ([[self departureCity] isEqualToString:[self arrivalCity]]) {
		isReserve = YES;
	}
	return isReserve;
//   char secondFlightNumberCharacter = [flightNumber characterAtIndex:1];
//   return (' ' != secondFlightNumberCharacter && 'H' != secondFlightNumberCharacter);
}

- (BOOL)isPilotSecondRoundLeg
{
	BOOL isPilotSecondRoundLeg = (nil == [self flightNumber]);
	return isPilotSecondRoundLeg;
}

- (NSCalendarDate *)departDateWithTripStartDate:(NSCalendarDate *)tripStartDate
{
    NSCalendarDate *departDate = [tripStartDate 
        dateByAddingYears:0 
        months:0 
        days:0 
        hours:0 
        minutes:[self departureTime] 
        seconds:0];
    // check for case where trip start date time zone differs from depart date
    // time zone
    BOOL tripStartDateIsDST = [[NSTimeZone defaultTimeZone] isDaylightSavingTimeForDate:tripStartDate];
    BOOL departDateIsDST = [[NSTimeZone defaultTimeZone] isDaylightSavingTimeForDate:departDate];
    int timeZoneAdjustmentHours = 0;
    if (tripStartDateIsDST && !departDateIsDST)
    {
        timeZoneAdjustmentHours = 1;
    }
    else if (!tripStartDateIsDST && departDateIsDST)
    {
        timeZoneAdjustmentHours = -1;
    }
    if (0 != timeZoneAdjustmentHours)
    {
        departDate = [departDate 
            dateByAddingYears:0 
            months:0 
            days:0 
            hours:timeZoneAdjustmentHours 
            minutes:0 
            seconds:0];
    }
    return departDate;
}

- (NSCalendarDate *)arriveDateWithTripStartDate:(NSCalendarDate *)tripStartDate
{
    NSCalendarDate *arriveDate = [tripStartDate 
        dateByAddingYears:0 
        months:0 
        days:0 
        hours:0 
        minutes:[self arrivalTime] 
        seconds:0];
    // check for case where trip start date time zone differs from depart date
    // time zone
    BOOL tripStartDateIsDST = [[NSTimeZone defaultTimeZone] isDaylightSavingTimeForDate:tripStartDate];
    BOOL arriveDateIsDST = [[NSTimeZone defaultTimeZone] isDaylightSavingTimeForDate:arriveDate];
    int timeZoneAdjustmentHours = 0;
    if (tripStartDateIsDST && !arriveDateIsDST)
    {
        timeZoneAdjustmentHours = 1;
    }
    else if (!tripStartDateIsDST && arriveDateIsDST)
    {
        timeZoneAdjustmentHours = -1;
    }
    if (0 != timeZoneAdjustmentHours)
    {
        arriveDate = [arriveDate 
            dateByAddingYears:0 
            months:0 
            days:0 
            hours:timeZoneAdjustmentHours 
            minutes:0 
            seconds:0];
    }
    return arriveDate;
}

#pragma mark ACCESSORS

- (NSString *)flightNumber { return flightNumber; }
- (void)setFlightNumber:(NSString *)inValue
{
   if (flightNumber != inValue) {
      [flightNumber release];
		int number = [[inValue substringFromIndex:2] intValue];
      if (number > 0) {
         flightNumber = [[NSString alloc] initWithFormat:@"%@%4d", [inValue substringToIndex:2], number];
      } else {
         // reserve line
         flightNumber = [inValue copy];
      }
   }
}

- (NSString *)departureCity { return departureCity; }
- (void)setDepartureCity:(NSString *)inValue;
{
   if (departureCity != inValue) {
      [departureCity release];
      departureCity = [inValue copy];
   }
}

- (int)departureTime { return departureTime; }
- (void)setDepartureTime:(int)inValue { departureTime = inValue; }

- (NSString *)arrivalCity { return arrivalCity; }
- (void)setArrivalCity:(NSString *)inValue
{
   if (arrivalCity != inValue) {
      [arrivalCity release];
      arrivalCity = [inValue copy];
   }
}

- (int)arrivalTime { return arrivalTime; }
- (void)setArrivalTime:(int)inValue { arrivalTime = inValue; }

- (NSString *)equipmentType { return equipmentType; }
- (void)setEquipmentType:(NSString *)inValue
{
   if (equipmentType != inValue) {
      [equipmentType release];
      equipmentType = [inValue copy];
   }
}

- (BOOL)isDeadhead { return isDeadhead; }
- (void)setIsDeadhead:(BOOL)inValue { isDeadhead = inValue; }

- (BOOL)isAircraftChange { return isAircraftChange; }
- (void)setIsAircraftChange:(BOOL)inValue { isAircraftChange = inValue; }

- (int)groundTime { return groundTime; }
- (void)setGroundTime:(int)inValue { groundTime = inValue; }

#pragma mark DESCRIPTION

- (NSString *)descriptionWithDate:(NSCalendarDate *)date tripDay:(int)day generic:(BOOL)generic
{
	BOOL isPilot2ndRnd = [self isPilotSecondRoundLeg];
    NSCalendarDate *depDate = [self departDateWithTripStartDate:date];
	NSString * dateString = nil;

    // generic date string
	if (generic)
	{
		dateString = [NSString stringWithFormat:@"Day %d", day];
	}
    // date string using date
	else
	{
        if (isPilot2ndRnd)
        {
            NSCalendarDate *round2DepDate = [date 
                dateByAddingYears:0 
                months:0 
                days:day - 1 
                hours:0 
                minutes:0 
                seconds:0];
            dateString = [round2DepDate descriptionWithCalendarFormat:@"%d%b"];
        }
        // for legs that are not pilot 2nd round legs, create date string
        // from date and departure time 
        else
        {
            dateString = [depDate descriptionWithCalendarFormat:@"%d%b"];
        }
	}
	NSString * depTimeString = [depDate descriptionWithCalendarFormat:@"%H%M"];
	NSCalendarDate *arrDate = [self arriveDateWithTripStartDate:date];
	NSString * arrTimeString = [arrDate descriptionWithCalendarFormat:@"%H%M"];
	NSString * descriptionString = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@%@ %@ %@\n", 
		dateString, 
		isPilot2ndRnd ? @"      " : [self flightNumber], 
		[self departureCity], 
		[self departureTime] == 0 ? @"    " : depTimeString, 
		[self arrivalCity], 
		[self arrivalTime] == 0 ? @"    " : arrTimeString, 
		[self equipmentType] != nil ? [self equipmentType] : @"   ", 
		[self blockTimeString], 
		isPilot2ndRnd ? @"    " : [self groundTimeString], 
		([self isAircraftChange] ? @" acft chg" : @"")];
	return descriptionString;
}

- (NSString *)description
{
   NSCalendarDate * date = [NSCalendarDate dateWithYear:2004 month:1 day:1 hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-21600]];
   NSCalendarDate * depDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:departureTime seconds:0];
   NSCalendarDate * arrDate = [date dateByAddingYears:0 months:0 days:0 hours:0 minutes:arrivalTime seconds:0];
   NSString * depTimeString = [depDate descriptionWithCalendarFormat:@"%H%M"];
   NSString * arrTimeString = [arrDate descriptionWithCalendarFormat:@"%H%M"];
   return [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@", flightNumber, departureCity, depTimeString, arrivalCity, arrTimeString, equipmentType, (isDeadhead ? @"DH" : @"  "), (isAircraftChange ? @"AC" : @"  ")];
}

- (NSString *)clipboardTextWithDate:(NSCalendarDate *)date
{
    NSString *clipboardText = @"";
    if (![self isPilotSecondRoundLeg])
    {
        clipboardText = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@\n",
            [date descriptionWithCalendarFormat:@"%m/%d/%Y"],
            [[self flightNumber] substringFromIndex:2],
            [self departureCity],
            [[self departDateWithTripStartDate:date] descriptionWithCalendarFormat:@"%H%M"],
            [self arrivalCity],
            [[self arriveDateWithTripStartDate:date] descriptionWithCalendarFormat:@"%H%M"]];
    }
    return clipboardText;
}

@end
