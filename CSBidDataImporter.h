//
//  CSBidDataImporter.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 6/22/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CSBidPeriod;
@class CSBidLine;
@class CSTrip;


@interface CSBidDataImporter : NSObject
{
    CSBidPeriod *_bidPeriod;
    NSDictionary *_trips;
    NSMutableDictionary *_tripLegs;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark
#pragma mark Data Importing
#pragma mark

- (NSURL *)importBidLineNumbers;
- (void)importBidDataForBidPeriod:(CSBidPeriod *)bidPeriod;
- (void)insertPredicateOperatorsForBidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark
#pragma mark Trips File
#pragma mark

- (void)importTrips;
- (void)setDaysPayForTrip:(CSTrip *)trip withTripRecord:(char *)tripRec;
- (void)addLegsForTrip:(CSTrip *)trip withRecord5:(char *)rec5 record6:(char *)rec6 payFile:(FILE *)payFilePtr;
- (void)grepTripTextFile;

#pragma mark
#pragma mark Lines File
#pragma mark

- (void)importBidLinesDataForBidPeriod:(CSBidPeriod *)bidPeriod;
- (void)addTripsForBidLine:(CSBidLine *)line withLineRecord:(char *)lineRec;

#pragma mark
#pragma mark Second Round Trips
#pragma mark

- (void)addSecondRoundTripsForBidPeriod:(CSBidPeriod *)bidPeriod;
- (char)tripNumberFirstChar;

#pragma mark
#pragma mark Utility Functions
#pragma mark

NSString * CopyStringFromCStringRange( char *str, NSRange r );
float PayFromCStringRange( char *str, NSRange r);
int BlockFromCStringRange( char *str, NSRange r);
int IntFromCStringRange( char *str, NSRange r);
float FloatFromCStringRange( char *str, NSRange r);
NSString * CopyFlightFromCStringRange( char *str, NSRange r);
void SetManagedObjectIntValueForKey( NSManagedObject *mo, int val, NSString *key );
void SetManagedObjectFloatValueForKey( NSManagedObject *mo, float val, NSString *key );
void SetManagedObjectBoolValueForKey( NSManagedObject *mo, BOOL val, NSString *key );

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod;
- (void)setBidPeriod:(CSBidPeriod *)value;

- (NSDictionary *)trips;
- (void)setTrips:(NSDictionary *)value;

- (NSMutableDictionary *)tripLegs;
- (void)setTripLegs:(NSDictionary *)value;

@end
