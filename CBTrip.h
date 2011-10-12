//
//  CBTrip.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CBTripDayLeg;

@interface CBTrip : NSObject <NSCoding>
{
   NSString * number;           // Record 1 character  0, length 4
   NSString * departureStation; // Record 1 character 19, length 3
   int        departureTime;    // Record 1 character 22, length 4
   int        returnTime;       // Record 1 character 29, length 4
   BOOL       isAMTrip;         // Record 1 character 36, length 1 (1 for AM, 2 for PM)
   int        totalBlock;       // Record 1 character 37, length 4
   int        dutyPeriods;      // Record 1 character 42, length 1
   NSArray *  days;
	// derived values
	float      credit;
	int        block;
	int        duty;
	int        tafb;
}

#pragma mark INITIALIZATION
- (id)initWithNumber:(NSString *)inNumber departureStation:(NSString *)inDepartureStation departureTime:(int)inDepartureTime returnTime:(int)inReturnTime isAMTrip:(BOOL)inIsAMTrip totalBlock:(int)inTotalBlock dutyPeriods:(int)inDutyPeriods;
- (void)initializeDerivedValues;
- (void)initializeDepartureAndReturnTimes;

#pragma mark ACCESSORS
- (NSString *)number;
- (void)setNumber:(NSString *)inValue;
- (NSString *)departureStation;
- (void)setDepartureStation:(NSString *)inValue;
- (int)departureTime;
- (void)setDepartureTime:(int)inValue;
- (int)returnTime;
- (void)setReturnTime:(int)inValue;
- (BOOL)isAMTrip;
- (void)setIsAMTrip:(BOOL)inValue;
- (int)totalBlock;
- (void)setTotalBlock:(int)inValue;
- (int)dutyPeriods;
- (void)setDutyPeriods:(int)inValue;
- (NSArray *)days;
- (void)setDays:(NSArray *)inValue;
#pragma mark DERIVED ACCESSORS
- (float)credit;
- (void)setCredit:(float)inValue;
- (int)block;
- (void)setBlock:(int)inValue;
- (int)duty;
- (void)setDuty:(int)inValue;
- (int)tafb;
- (void)setTafb:(int)inValue;
- (BOOL)isReserve;
- (CBTripDayLeg *)firstLeg;
- (CBTripDayLeg *)lastLeg;
- (void)setIsAmWithDefaultAmDepartTime:(int)defaultDepartTime arrivalTime:(int)defaultArrivalTime;

#pragma mark DESCRIPTION
- (NSString *)descriptionWithDate:(NSCalendarDate *)date generic:(BOOL)generic faPosition:(NSString *)faPosition;
- (NSString *)descriptionWithDate:(NSCalendarDate *)date generic:(BOOL)generic;
- (NSString *)clipboardTextWithStartDate:(NSCalendarDate *)startDate;
- (NSString *)tafbString;
- (NSString *)blockString;
- (NSString *)dutyString;
- (NSString *)payString;
- (NSString *)pilotSecondRoundTripDescriptionWithDate:(NSCalendarDate *)date;

@end
