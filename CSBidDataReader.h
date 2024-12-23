//
//  CSBidDataReader.h
//  CrewBid
//
//  Created by Mark Ackerman on 8/15/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

/*******************************************************************************
 
 Depsite the name, this class is used only for reading second round pilot 
 trip data from the lines text file.
 
 Second round trips have limited information, namely:d
 - trip number
 - trip duty periods
 - trip overnight cities
 - trip start and return times
 - trip pay
 
 The second round trips are constructed to contain:
 - a CBTripDay for each day
 - one CBTripDayLeg for each day, which has departureCity and arrivalCity; if 
   the leg is in the first day, it will also have a departureTime; if in the 
   last day, it will have an arrivalTime
 - total pay (credit) for the trip
 
*******************************************************************************/

#import <Cocoa/Cocoa.h>

@class CSBidPeriod;
@class CBTrip;

@interface CSBidDataReader : NSObject
{
    CSBidPeriod *_bidPeriod;
    NSDictionary *_trips;
	NSMutableArray *_missingTrips;
	NSString *_errorReason;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark
#pragma mark Second Round Trips
#pragma mark

// Reads lines text file, adding available properties for trips that do not 
// appear in the trips data file. If a line trip is not found in either the 
// trip data file or the lines file text, returns NO to indicate and error, and 
// sets the error string for use by other classes.
- (BOOL)addSecondRoundTripsForBidPeriod:(CSBidPeriod *)bidPeriod;
// Creates a trip by reading the lines text file.
- (CBTrip *)readTripForLineNumber:(NSInteger)lineNumber tripNumber:(NSString *)tripNumber tripDate:(NSInteger)tripDate tripSequence:(NSUInteger)tripSequence fileInfo:(NSString *)fileInfo;

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod;
- (void)setBidPeriod:(CSBidPeriod *)value;

- (NSDictionary *)trips;
- (void)setTrips:(NSDictionary *)value;

- (NSMutableArray *)missingTrips;
- (void)setMissingTrips:(NSArray *)value;

- (NSString *)errorReason;
- (void)setErrorReason:(NSString *)value;


@end
