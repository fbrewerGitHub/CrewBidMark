//
//  CBTripDayLeg.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CBTripDayLeg : NSObject <NSCoding>
{
   NSString * flightNumber;
   NSString * departureCity;
   int        departureTime;
   NSString * arrivalCity;
   int        arrivalTime;
   NSString * equipmentType;
   BOOL       isDeadhead;
   BOOL       isAircraftChange;
	int        groundTime;
}

#pragma mark INITIALIZATION
- (id)initWithFlightNumber:(NSString *)inFlightNumber departureCity:(NSString *)inDepartureCity departureTime:(int)inDepartureTime arrivalCity:(NSString *)inArrivalCity arrivalTime:(int)inArrivalTime equipmentType:(NSString *)inEquipmentType isDeadhead:(BOOL)inIsDeadhead isAircraftChange:(BOOL)inIsAircraftChange;

#pragma mark DERIVED VALUES
- (NSString *)blockTimeString;
- (NSString *)groundTimeString;
- (NSString *)layoverTimeString;
- (BOOL)isReserve;
- (BOOL)isPilotSecondRoundLeg;
- (NSCalendarDate *)departDateWithTripStartDate:(NSCalendarDate *)tripStartDate;
- (NSCalendarDate *)arriveDateWithTripStartDate:(NSCalendarDate *)tripStartDate;

#pragma mark ACCESSORS
- (NSString *)flightNumber;
- (void)setFlightNumber:(NSString *)inValue;
- (NSString *)departureCity;
- (void)setDepartureCity:(NSString *)inValue;
- (int)departureTime;
- (void)setDepartureTime:(int)inValue;
- (NSString *)arrivalCity;
- (void)setArrivalCity:(NSString *)inValue;
- (int)arrivalTime;
- (void)setArrivalTime:(int)inValue;
- (NSString *)equipmentType;
- (void)setEquipmentType:(NSString *)inValue;
- (BOOL)isDeadhead;
- (void)setIsDeadhead:(BOOL)inValue;
- (BOOL)isAircraftChange;
- (void)setIsAircraftChange:(BOOL)inValue;
// derived
- (int)groundTime;
- (void)setGroundTime:(int)inValue;

#pragma mark DESCRIPTION
- (NSString *)descriptionWithDate:(NSCalendarDate *)date tripDay:(int)day generic:(BOOL)generic;
- (NSString *)clipboardTextWithDate:(NSCalendarDate *)date;

@end
