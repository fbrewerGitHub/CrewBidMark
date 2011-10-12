//
//  CSBidDataReader.m
//  CrewBid
//
//  Created by Mark Ackerman on 8/15/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSBidDataReader.h"

#import <regex.h>
#import "CSBidPeriod.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"


@implementation CSBidDataReader

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod
{
    if (self = [super init])
    {
        [self setBidPeriod:bidPeriod];
        [self setTrips:[NSDictionary dictionary]];
    }
    
    return self;
}

- (void) dealloc
{
    [self setBidPeriod:nil];
    [self setTrips:nil];
	[self setMissingTrips:nil];
    [super dealloc];
}

#pragma mark
#pragma mark Second Round Trips
#pragma mark

// Enumerate each line trip dictionary, which contains trip number and date, 
// for each line. If a line trip is found that is not in the trips dictionary, 
// create a trip for it by reading the lines text file. If unable to create a 
// trip, set error message and return NO to indicate error.
- (BOOL)addSecondRoundTripsForBidPeriod:(CSBidPeriod *)bidPeriod
{
	// Read line file info.
	NSError *error = nil;
	NSString *fileInfo = [NSString stringWithContentsOfFile:[[self bidPeriod] linesTextFilePath] encoding:NSUTF8StringEncoding error:&error];
	if (nil == fileInfo) {
		[self setErrorReason:[NSString stringWithFormat:@"Failed to read lines text file: %@", [error localizedDescription]]];
		return NO;
	}
	// A dictionary to hold the second round trips that are created.
	NSMutableDictionary *round2Trips = [NSMutableDictionary dictionaryWithCapacity:32];
	NSArray *bpLines = [bidPeriod bidLines];
	unsigned countOfLines = [bpLines count];
	unsigned l = 0;
	// Enumerate lines.
	for (l = 0; l < countOfLines; l++)
	{
		CBLine *ln = [bpLines objectAtIndex:l];
		NSArray *lnTrips = [ln trips];
		// An array to hold the line trips that have been enumerated for a 
		// line. It is used to determine if their are trips with the same 
		// number in the line (duplicate trip numbers).
		NSMutableArray *r2TripsToRead = [NSMutableArray arrayWithCapacity:[lnTrips count]];
		unsigned countOfTrips = [lnTrips count];
		unsigned t = 0;
		// Enumerate line trip dictionaries for line.
		for (t = 0; t < countOfTrips; t++)
		{
			NSDictionary *tpd = [lnTrips objectAtIndex:t];
			NSString *tpNum = [tpd objectForKey:CBLineTripNumberKey];
			// If the line trip dictionary is not found in the trip dictionary 
			// (which has been previously read from the trips data file), then 
			// attempt to create the trip from the lines text file. If unable 
			// to create the trip from the lines text file, return NO (error 
			// reason normally have been set in the method that reads the lines 
			// text file.
			if (nil == [[self trips] objectForKey:tpNum]) {
				[r2TripsToRead addObject:[tpNum substringToIndex:4]];
				// Determine if there are duplicate trip numbers in the trips 
				// for the line. The number of trips with the same trip number 
				// is used in the method that reads the lines text file, so 
				// that the correct trip start/end times and pay are read.
				NSPredicate *dupTripPred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [tpNum substringToIndex:4]];
				NSArray *dupTrips = [r2TripsToRead filteredArrayUsingPredicate:dupTripPred];
				// Attempt to create the trip from the lines text file.
				CBTrip *r2Trip = [self readTripForLineNumber:[ln number] tripNumber:tpNum tripDate:[[tpd objectForKey:CBLineTripDateKey] integerValue] tripSequence:[dupTrips count] fileInfo:fileInfo];
				// If the trip was successfully created, add to the second 
				// round trips dictionary. This dictionary will be combined 
				// with the trips dictionary obtained from the trips data file 
				// at the end of this method.
				if (r2Trip) {
					[round2Trips setObject:r2Trip forKey:tpNum];
				}
				// Failed to create trip from lines text file. The error reason 
				// should have been set in the method that reads the lines text 
				// file. If the error reason has not been set, set a generic 
				// error reason.
				else {
					if (nil == [self errorReason]) {
						[self setErrorReason:@"Unknown error."];
					}
					return NO;
				}
			}
		}
	}
	NSMutableDictionary *newTripsDict = [NSMutableDictionary dictionaryWithCapacity:[[self trips] count] + [round2Trips count]];
	[newTripsDict addEntriesFromDictionary:[self trips]];
	[newTripsDict addEntriesFromDictionary:round2Trips];
	[self setTrips:newTripsDict];
	return YES;
}

- (CBTrip *)readTripForLineNumber:(NSInteger)lineNumber tripNumber:(NSString *)tripNumber tripDate:(NSInteger)tripDate tripSequence:(NSUInteger)tripSequence fileInfo:(NSString *)fileInfo
{
	// Return value.
	CBTrip *trip = nil;
	// Predicate to find the lines in the lines text file that begin with 
	// the string 'Line'.
	NSString *regEx = @"^Line.*";
	NSPredicate *regExPred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regEx];
	// Variables to hold the line information from the lines text file.
	NSUInteger lenFileInfo = [fileInfo length];
	NSRange lineRange = NSMakeRange(0, 0);
	NSString *lineInfo = nil;
	// Scanner results, used to determine if errors occurred in reading the 
	// line info.
	// Read lines from the file, seeking the line that begins the info for the 
	// line that contains the trip we're trying to create.
	while (lineRange.location < lenFileInfo) {
		lineRange = [fileInfo lineRangeForRange:lineRange];
		lineInfo = [fileInfo substringWithRange:lineRange];
		// Found a line that begins with 'Line'. Scan the line number that 
		// follows.
		if ([regExPred evaluateWithObject:lineInfo]) {
			NSScanner *scanner = [NSScanner scannerWithString:lineInfo];
			NSInteger lineNum = 0;
			// Scan past the string 'Line'. This shouldn't fail, since the 
			// predicate test should have found a line of text that begins with 
			// the string 'Line'.
			if (![scanner scanString:@"Line" intoString:NULL]) {
				[self setErrorReason:[NSString stringWithFormat:@"Failed to read line number for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
				return nil;
			}
			// Scan line number, which should immediately follow string 'Line' 
			// at the start of the line info.
			if (![scanner scanInteger:&lineNum]) {
				[self setErrorReason:[NSString stringWithFormat:@"Failed to read line number for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
				return nil;
			}
			// Found the start of the info for the line that contains the trip
			// that is to be created. 
			if (lineNum == lineNumber) {
				// Determine the location of the start of the days of the month 
				// in this line, which will be used to set the start of the 
				// scan for the trip number, as there is no trip number info 
				// prior to that point in the line info.
				
				// Failed to read text 'TFP', which should immediately follow 
				// line number in the line info.
				if (![scanner scanString:@"TFP" intoString:NULL]) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to read TFP text for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				// Failed to read TFP value.
				if (![scanner scanFloat:NULL]) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to read TFP value for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				if (![scanner scanInteger:NULL]) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find days of month start for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				// This is the point at which all scanning of lines info should 
				// start; there is no useful trip information in the lines 
				// file info before this point in each line of info.
				NSUInteger datesStart = [scanner scanLocation] - 1;
				// Skip past this line and the next line.
				lineRange.location = lineRange.location + lineRange.length;
				lineRange.length = 0;
				if (lineRange.location >= lenFileInfo) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				lineRange = [fileInfo lineRangeForRange:lineRange];
				lineRange.location = lineRange.location + lineRange.length;
				lineRange.length = 0;
				if (lineRange.location >= lenFileInfo) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				lineRange = [fileInfo lineRangeForRange:lineRange];
				if (lineRange.location >= lenFileInfo) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				lineInfo = [fileInfo substringWithRange:lineRange];
				// We should now be at the text that contains the partial trip 
				// number. Determine where it is located in the text, so we can 
				// use that location in the next line to read the overnight 
				// cities. This is really just a sanity check, since we should 
				// be able to determine where the overnight cities start from 
				// where the dates start and the start day of the trip.
				NSUInteger scanStart = datesStart + 3 * (tripDate - 1);
				scanner = [NSScanner scannerWithString:lineInfo];
				[scanner setScanLocation:scanStart];
				NSString *partTripNum = [tripNumber substringWithRange:NSMakeRange(1, 3)];
				// Failed to find partial trip number at scan start location 
				// in line info. Partial trip number has format 'P01'. Since 
				// the scanner should already be at the start of the partial 
				// trip number, this scan should fail.
				if ([scanner scanUpToString:partTripNum intoString:NULL]) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				NSUInteger tripStartLoc = [scanner scanLocation];
				// Skip to next line of text, which should have overnight 
				// cities.
				lineRange.location = lineRange.location + lineRange.length;
				lineRange.length = 0;
				if (lineRange.location >= lenFileInfo) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				lineRange = [fileInfo lineRangeForRange:lineRange];
				lineInfo = [fileInfo substringWithRange:lineRange];
				scanner = [NSScanner scannerWithString:lineInfo];
				[scanner setScanLocation:tripStartLoc];
				NSString *cities = nil;
				// Scan the overnight cities for the trip. The number of 
				// characters scanned should be evenly divisible by 3.
				[scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&cities];
				if (0 != [cities length] % 3) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find overnight cities for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				// Skip to next line of text, which will have start/end times 
				// and pay for trip.
				lineRange.location = lineRange.location + lineRange.length;
				lineRange.length = 0;
				lineRange = [fileInfo lineRangeForRange:lineRange];
				if (lineRange.location >= lenFileInfo) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				lineInfo = [fileInfo substringWithRange:lineRange];
				// Determine if following line has more trip info blocks. If 
				// so, append to lineInfo string. If the following line starts 
				// with a '-' char, then there is no more trip info available.
				NSUInteger nextCharLoc = lineRange.location + lineRange.length;
				if (nextCharLoc < lenFileInfo && '-' != [fileInfo characterAtIndex:nextCharLoc]) {
					lineRange.location = lineRange.location + lineRange.length;
					lineRange.length = 0;
					lineRange = [fileInfo lineRangeForRange:lineRange];
					if (lineRange.location >= lenFileInfo) {
						[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
						return nil;
					}
					lineInfo = [lineInfo stringByAppendingString:[fileInfo substringWithRange:lineRange]];
				}
				// Read trip info (format: P03=0620/1605(14.50)).
				// Start scanning at dates start location since 
				// there is no trip data before that point. If there is more 
				// than one trip with the same number in the line, skip to the 
				// trip info that corresponds to that trip (trip sequence).
				scanner = [NSScanner scannerWithString:lineInfo];
				[scanner setScanLocation:datesStart];
				NSUInteger s = 0;
				for (s = 0; s < tripSequence; s++) {
					[scanner scanUpToString:partTripNum intoString:NULL];
					[scanner scanString:partTripNum intoString:NULL];
					[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL];
				}
				// If scanner is at end, then failed to find partial trip 
				// number in trip start/end and pay info.
				if ([scanner isAtEnd]) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find trip start/end and pay info for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				NSUInteger prevScanLoc = [scanner scanLocation];
				NSInteger depTime = 0;
				// Should read an integer and should read exactly 4 characters 
				// (i.e., scan location should advance by 4).
				if (![scanner scanInteger:&depTime] || 4 != [scanner scanLocation] - prevScanLoc) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to read start time for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				prevScanLoc = [scanner scanLocation];
				NSInteger arrTime = 0;
				// Should scan at least one non decimal digit (the separator 
				// between the trip start and end times ('/'). Then, should 
				// read an integer, and should have read exactly 4 characters 
				// (plus the separator character, for a total of 5 characters 
				// difference from the previous scan location).
				if (![scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL] || 
					![scanner scanInteger:&arrTime] || 
					5 != [scanner scanLocation] - prevScanLoc) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to read end time for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				;
				float pay = 0.0;
				// Should scan at least one non decimal digit (the left parens 
				// character before the trip pay). Then, should read a float.
				if (![scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:NULL] ||
					![scanner scanFloat:&pay]) {
					[self setErrorReason:[NSString stringWithFormat:@"Failed to find pay for line: %d trip: %@ sequence: %u.", lineNumber, [tripNumber substringToIndex:4], tripSequence]];
					return nil;
				}
				// Create a new trip and set available properties. At this 
				// point should be fairly certain that available properties  
				// have been read properly.
				trip = [[CBTrip alloc] init];
				// Trip number is the first four characters of the trip key.
				[trip setNumber:[tripNumber substringToIndex:4]];
				[trip setDepartureTime:depTime];
				[trip setReturnTime:arrTime];
				[trip setCredit:pay];
				// Set trip AM/PM
				if ([trip returnTime] < 1800) {
					[trip setIsAMTrip:YES];
				}
				// Reserve trips are determined by 0 == totalBlock, so set an 
				// arbitrary totalBlock (1) so that the trip will not be 
				// considered a reserve trip.
				[trip setTotalBlock:1];
				// Create days for each city.
				NSUInteger daysCount = [cities length] / 3;
				NSUInteger d = 0;
				NSMutableArray *tripDays = [NSMutableArray arrayWithCapacity:4];
				NSString *prevCity = [[self bidPeriod] base];
				for (d = 0; d < daysCount; d++) {
					NSRange cityRange = NSMakeRange(d * 3, 3);
					NSString *city = [cities substringWithRange:cityRange];
					CBTripDay *day = [[CBTripDay alloc] init];
					// Create a single leg for each day.
					CBTripDayLeg *leg = [[CBTripDayLeg alloc] init];
					[leg setDepartureCity:prevCity];
					[leg setArrivalCity:city];
					prevCity = city;
					if (0 == d) {
						[day setIsFirstDay:YES];
					}
					[day setLegs:[NSArray arrayWithObject:leg]];
					[tripDays addObject:day];
					[day release];
					[leg release];
					// Stop when we get to city that is equal to base, to 
					// avoid reading past the trip's city (such as when the 
					// is followed by a turn).
					if ([city isEqualToString:[[self bidPeriod] base]]) {
						break;
					}
				}
				[trip setDays:tripDays];
				[trip setDutyPeriods:[tripDays count]];
				// Set departure and arrival times for first and last legs of 
				// trip. (This is the only information we have available for 
				// days and legs.) Departure and return times are minutes from 
				// midnight of first day of trip, so need to convert.
				NSInteger time = ([trip departureTime] / 100) * 60 + [trip departureTime] % 100;
				[[trip firstLeg] setDepartureTime:time];
				time = ([trip returnTime] / 100) * 60 + [trip returnTime] % 100 + ([trip dutyPeriods] - 1) * 60 * 24;
				[[trip lastLeg] setArrivalTime:time];
			}
		}
		// Go to next line in file info.
		lineRange.location = lineRange.location + lineRange.length;
		lineRange.length = 0;
	}
	return trip;
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod {
    return _bidPeriod;
}

- (void)setBidPeriod:(CSBidPeriod *)value {
    if (_bidPeriod != value) {
        [_bidPeriod release];
        _bidPeriod = [value copy];
    }
}

- (NSDictionary *)trips {
    return _trips;
}

- (void)setTrips:(NSDictionary *)value {
    if (_trips != value) {
        [_trips release];
        _trips = [value copy];
    }
}

- (NSMutableArray *)missingTrips
{
	if (!_missingTrips)
	{
		[self setMissingTrips:[NSArray array]];
	}
    return _missingTrips;
}

- (void)setMissingTrips:(NSArray *)value {
    if (_missingTrips != value) {
        [_missingTrips release];
        _missingTrips = [value mutableCopy];
    }
}

- (NSString *)errorReason {
    return _errorReason;
}

- (void)setErrorReason:(NSString *)value {
    if (_errorReason != value) {
        [_errorReason release];
        _errorReason = [value copy];
    }
}


@end
