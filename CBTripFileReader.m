//
//  CBTripFileReader.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBTripFileReader.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"

@implementation CBTripFileReader

- (id)initWithTripsFile:(NSString *)path;
{
   if (self = [super init]) {
      // check that lines file exists
      if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
         [self setTripsFilePath:path];
      } else {
         NSLog(@"CBTripFileReader could not find file: %@", path);
         [super dealloc];
         return nil;
      }
   }
   return self;
}

- (void)dealloc
{
   [tripsFilePath release];
   [super dealloc];
}

#pragma mark FILE READING

- (NSDictionary *)tripsDictionary
{
   // return value
   NSMutableDictionary * tripsDictionary = [NSMutableDictionary dictionary];
   // get contents of trips file
	NSString * tripsString = [NSString stringWithContentsOfFile:[self tripsFilePath] encoding:NSUTF8StringEncoding error:NULL];
   NSRange lineRange = NSMakeRange(0, [tripsString length]);
   NSUInteger lineStartIndex = 0;
   NSUInteger lineEndIndex = 0;
   NSUInteger nextLineStartIndex = 0;
   [tripsString getLineStart:&lineStartIndex end:&nextLineStartIndex contentsEnd:&lineEndIndex forRange:lineRange];
   NSString * lineSeparator = [tripsString substringWithRange:NSMakeRange(lineEndIndex, nextLineStartIndex - lineEndIndex)];
   NSArray * tripsData = [tripsString componentsSeparatedByString:lineSeparator];
   // create trip from each group of trip data strings
   const unsigned MAX_TRIP_DATA_INDEX = [tripsData count] - 2;
   unsigned tripDataIndex = 0;
   while (tripDataIndex < MAX_TRIP_DATA_INDEX) {
      // read RECORD 1
      NSRange NUMBER_RANGE = NSMakeRange(0, 4);
      NSRange DEPARTURE_STATION_RANGE = NSMakeRange(19, 3);
      NSRange DEPARTURE_TIME_RANGE = NSMakeRange(22, 4);
      NSRange RETURN_TIME_RANGE = NSMakeRange(29, 4);
      NSRange IS_AM_TRIP_RANGE = NSMakeRange(36, 1);
      NSRange TOTAL_BLOCK_RANGE = NSMakeRange(37, 4);
      NSRange DUTY_PERIODS_RANGE = NSMakeRange(42, 1);
      NSString * record1 = [tripsData objectAtIndex:tripDataIndex];
      tripDataIndex++;
      NSString * tripNumber = [record1 substringWithRange:NUMBER_RANGE];
      NSString * tripDepartureStation = [record1 substringWithRange:DEPARTURE_STATION_RANGE];
      int tripDepartureTime = [[record1 substringWithRange:DEPARTURE_TIME_RANGE] intValue];
      int tripReturnTime = [[record1 substringWithRange:RETURN_TIME_RANGE] intValue];
      BOOL tripIsAMTrip = [[record1 substringWithRange:IS_AM_TRIP_RANGE] intValue] == 1 ? YES : NO;
      int tripTotalBlock = [[record1 substringWithRange:TOTAL_BLOCK_RANGE] intValue];
      int tripDutyPeriods = [[record1 substringWithRange:DUTY_PERIODS_RANGE] intValue];
      // create trip with initial data
      CBTrip * trip = [[CBTrip alloc] initWithNumber:tripNumber departureStation:tripDepartureStation departureTime:tripDepartureTime returnTime:tripReturnTime isAMTrip:tripIsAMTrip totalBlock:tripTotalBlock dutyPeriods:tripDutyPeriods];
      // adjust departure and arrival times for reserve tripw
//      if ([trip isReserve]) {
//         tripDepartureTime -= 700;
//         tripReturnTime += 700;
//      }

      // read RECORD2 - day's credit and number of type 5 records
      NSString * record2 = [tripsData objectAtIndex:tripDataIndex];
      tripDataIndex++;
      NSRange NUM_RECORDS_RANGE = NSMakeRange(79, 1);
      NSRange RECORD_DATA_RANGE = NSMakeRange(5, 72);
      NSRange tripCreditRange = NSMakeRange(8, 4);
      unsigned TRIP_CREDIT_INTVL = 7;
      NSMutableArray * tripDaysCredits = [NSMutableArray array];
      int numTripDays = [trip dutyPeriods];
      int tripDay = 0;
      for (tripDay = 0; tripDay < numTripDays; tripDay++) {
         [tripDaysCredits addObject:[record2 substringWithRange:tripCreditRange]];
         tripCreditRange.location += TRIP_CREDIT_INTVL;
      }
      unsigned numType5Records = [[record2 substringWithRange:NUM_RECORDS_RANGE] intValue];
      // read RECORD3 - skipped for now
      //NSString * record3 = [tripsData objectAtIndex:tripDataIndex];
      tripDataIndex++;
      // read RECORD5 - departure and arrival times, number of type 6 records
      unsigned numType6Records = [[[tripsData objectAtIndex:tripDataIndex] substringWithRange:NUM_RECORDS_RANGE] intValue];
      NSMutableString * record5 = [NSMutableString stringWithString:[[tripsData objectAtIndex:tripDataIndex] substringWithRange:RECORD_DATA_RANGE]];
      tripDataIndex++;
      unsigned record = 0;
      for (record = 1; record < numType5Records; record++) {
         [record5 appendString:[[tripsData objectAtIndex:tripDataIndex] substringWithRange:RECORD_DATA_RANGE]];
         tripDataIndex++;
      }
      // read RECORD6 - flight number, departure and arrival cities, type equipment
      NSMutableString * record6 = [NSMutableString stringWithString:[[tripsData objectAtIndex:tripDataIndex] substringWithRange:RECORD_DATA_RANGE]];
      tripDataIndex++;
      for (record = 1; record < numType6Records; record++) {
         [record6 appendString:[[tripsData objectAtIndex:tripDataIndex] substringWithRange:RECORD_DATA_RANGE]];
         tripDataIndex++;
      }
      // create trip days and legs for trip
      NSArray * tripDays = [self tripDaysWithPay:tripDaysCredits flightData:record6 times:record5 isReserve:[trip isReserve]];
      [trip setDays:tripDays];
      // add trip to dictionary
      [tripsDictionary setObject:trip forKey:tripNumber];
		[trip release];
   }
   return [NSDictionary dictionaryWithDictionary:tripsDictionary];
}

- (NSArray *)tripDaysWithPay:(NSArray *)payArray flightData:(NSString *)flightData times:(NSString *)times isReserve:(BOOL)isReserve
{
   NSMutableArray * tripDays = [NSMutableArray array];
   // number of days in trip
   int day = 0;
   unsigned NUM_DAYS = [payArray count];
   unsigned FLIGHT_DATA_LENGTH = [flightData length];
   unsigned TIMES_LENGTH = [times length];
   // day ranges and intervals
   NSRange dayFlightDataRange = NSMakeRange(0, 15);
   const unsigned DAY_FLIGHT_DATA_INTVL = 15;
   NSRange dayTimesRange = NSMakeRange(0, 12);
   const unsigned DAY_TIMES_INTVL = 12;
   // leg ranges and indexes
   const unsigned IS_NEW_DAY_INDEX = 6;
   const char IS_NEW_DAY_CHAR = '9';
   const unsigned IS_DEADHEAD_INDEX = 0;
   const char IS_DEADHEAD_CHAR = '2';
   const unsigned IS_AIRCRAFT_CHANGE_INDEX = 12;
   const char IS_AIRCRAFT_CHANGE_CHAR = '*';
   NSRange DEP_TIME_RANGE = NSMakeRange(2, 4);
   NSRange ARR_TIME_RANGE = NSMakeRange(8, 4);
   NSRange FLIGHT_NUMBER_RANGE = NSMakeRange(0, 6);
   NSRange DEP_CITY_RANGE = NSMakeRange(6, 3);
   NSRange ARR_CITY_RANGE = NSMakeRange(9, 3);
   const unsigned EQUIP_TYPE_INDEX = 13;
	// is first leg
	BOOL dayIsFirstDay = YES;
	// leg and previous leg - used to derive ground time
	CBTripDayLeg * leg = nil;
	CBTripDayLeg * previousLeg = nil;
   // read pairs of flight data and times
   NSMutableArray * dayLegs = [NSMutableArray array];
   BOOL moreLegs = YES;
   while (moreLegs) {
      // get day data
      NSString * dayFlightData = [flightData substringWithRange:dayFlightDataRange];
      dayFlightDataRange.location += DAY_FLIGHT_DATA_INTVL;
      NSString * dayTimes = [times substringWithRange:dayTimesRange];
      dayTimesRange.location += DAY_TIMES_INTVL;
      // if at a new day, create CBTripDay with dayCredit and dayLegs
      if ([dayTimes characterAtIndex:IS_NEW_DAY_INDEX] == IS_NEW_DAY_CHAR) {
         float dayCredit = [self creditWithString:[payArray objectAtIndex:day]];
         CBTripDay * tripDay = [[CBTripDay alloc] initWithCredit:dayCredit legs:[NSArray arrayWithArray:dayLegs]];
			// day is first day until a day is created, then all subsequent days
			// are not first day
			[tripDay setIsFirstDay:(dayIsFirstDay ? YES : NO)];
			dayIsFirstDay = NO;
         [dayLegs removeAllObjects];
         [tripDays addObject:tripDay];
         [tripDay release];
         day++;
      }
      // get leg data, create CBTripDayLeg, and add to dayLegs
      NSString * legFlightNumber = [dayFlightData substringWithRange:FLIGHT_NUMBER_RANGE];
      NSString * legDepartureCity = [dayFlightData substringWithRange:DEP_CITY_RANGE];
      int legDepartureTime = [[dayTimes substringWithRange:DEP_TIME_RANGE] intValue];
		// if leg departure time is 0, then all leg data has been read
      if (legDepartureTime > 0) {
         NSString * legArrivalCity = [dayFlightData substringWithRange:ARR_CITY_RANGE];
         int legArrivalTime = [[dayTimes substringWithRange:ARR_TIME_RANGE] intValue];
         NSString * legEquipmentType = [NSString stringWithFormat:@"%c00", [dayFlightData characterAtIndex:EQUIP_TYPE_INDEX]];
         BOOL legIsDeadhead = ([dayTimes characterAtIndex:IS_DEADHEAD_INDEX] == IS_DEADHEAD_CHAR);
         BOOL legIsAircraftChange = ([dayFlightData characterAtIndex:IS_AIRCRAFT_CHANGE_INDEX] == IS_AIRCRAFT_CHANGE_CHAR);
         // adjust leg departure and arrival times for reserve trips
//         if (isReserve) {
//            legDepartureTime -= (7 * 60);
//            legArrivalTime += (7 * 60);
//         }
         leg = [[CBTripDayLeg alloc] initWithFlightNumber:legFlightNumber departureCity:legDepartureCity departureTime:legDepartureTime arrivalCity:legArrivalCity arrivalTime:legArrivalTime equipmentType:legEquipmentType isDeadhead:legIsDeadhead  isAircraftChange:legIsAircraftChange];
         [dayLegs addObject:leg];
			// derive ground time for previous leg
			if (previousLeg) {
				int previousLegGroundTime = legDepartureTime - [previousLeg arrivalTime];
				[previousLeg setGroundTime:previousLegGroundTime];
			}
         [previousLeg release];
			previousLeg = leg;
		// all non-zero leg data has been read
      } else {
         moreLegs = NO;
      }
      if (moreLegs) {
         moreLegs = (day < NUM_DAYS &&
                     dayFlightDataRange.location + DAY_FLIGHT_DATA_INTVL <= FLIGHT_DATA_LENGTH &&
                     dayTimesRange.location + DAY_TIMES_INTVL <= TIMES_LENGTH);
      }
		// final day of trip
      if (!moreLegs) {
			// ground time of final leg
			[leg setGroundTime:0];
			[leg release];
			// create final day and add to trip
         float dayCredit = [self creditWithString:[payArray objectAtIndex:day]];
         CBTripDay * tripDay = [[CBTripDay alloc] initWithCredit:dayCredit legs:[NSArray arrayWithArray:dayLegs]];
			[tripDay setIsFirstDay:(dayIsFirstDay ? YES : NO)];
         [tripDays addObject:tripDay];
         [tripDay release];
      }
   }

   // return
   return [NSArray arrayWithArray:tripDays];
}

- (float)creditWithString:(NSString *)creditData
{
   int creditIntegerPart = [[creditData substringWithRange:NSMakeRange(0, 2)] intValue];
   float creditDecimalPart = [[creditData substringWithRange:NSMakeRange(2, 2)] floatValue];
   if (creditDecimalPart > 0.0) {
      creditDecimalPart /= 60.0;
   }
   return (float)creditIntegerPart + creditDecimalPart;
}

- (float)blockWithString:(NSString *)blockData
{
   int blockIntegerPart = [[blockData substringWithRange:NSMakeRange(0, 2)] intValue];
   float blockDecimalPart = [[blockData substringWithRange:NSMakeRange(2, 2)] floatValue];
   if (blockDecimalPart > 0.0) {
      blockDecimalPart /= 60.00;
   }
   return (float)blockIntegerPart + blockDecimalPart;
}

#pragma mark ACCESSORS

- (NSString *)tripsFilePath { return tripsFilePath; }
- (void)setTripsFilePath:(NSString *)inValue
{
   if (tripsFilePath != inValue)  {
      [tripsFilePath release];
      tripsFilePath = [inValue copy];
   }
}

@end
