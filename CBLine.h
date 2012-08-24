//
//  CBLine.h
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum enumCBLineDeselectedFlag
{
	CBSelectedLineMask = 0,
	CBAircraftChangesDeselectedLineMask = 1,
	CBAmDeselectedLineMask = 1 << 1,
	CBPmDeselectedLineMask = 1 << 2,
    CBTurnDeselectedLineMask = 1 << 3,
    CBTwoDayDeselectedLineMask = 1 << 4,
    CBThreeDayDeselectedLineMask = 1 << 5,
    CBFourDayDeselectedLineMask = 1 << 6,
    CBDaysOfMonthDeselectedLineMask = 1 << 7,
    CBOvernightCitiesDeselectedLineMask = 1 << 8,
    CBOverlapDeselectedLineMask = 1 << 9,
    CBBlockOfDaysOffDeselectedLineMask = 1 << 10,
    CBDeadheadAtStartDeselectedMask = 1 << 11,
    CBDeadheadAtEndDeselectedMask = 1 << 12,
    CBCommuteAtStartDeselectMask = 1 << 13,
    CBCommuteAtEndDeselectMask = 1 << 14,
    CBCommuteAtBothEndsDeselectMask = 1 << 15,
    CBCommuteCommutesRequiredDeselectedMask = 1 << 16,
    CBCommuteOvernightsInDomicileDeselectedMask = 1 << 17,
    CBVacationDeselectedMask = 1 << 18,
	CBMaxLegsPerDayDeselectedLineMask = 1 << 19
} CBLineDeselectedFlag;

@interface CBLine : NSObject <NSCoding>
{
   int   number;
   float credit;
   float block;
   NSArray * trips;
   BOOL isReserveLine;
   BOOL isBlankLine;
   NSArray * lineCalendarEntries;
   NSArray * lineCalendarObjects;
   NSArray * lineCalendarTags;
   NSArray * printCalendarEntries;
   float points;
   // derived
   NSString *numberString;
   float creditNextMonth;
   float blockNextMonth;
   BOOL isAM;
   BOOL isPM;
   NSString * t234;
   int turns;
   int twoDays;
   int threeDays;
   int fourDays;
   int oneDayWorkBlocks;
   int twoDayWorkBlocks;
   int threeDayWorkBlocks;
   int fourDayWorkBlocks;
   int longestDaysOffBlock;
   BOOL is3on3off;
   int weekends;
   int workDays;
   NSCountedSet * overnightCities;
   NSSet * workDates;
   NSSet * workDatesNextMonth;
   int daysOff;
   int tafb;
   int duty;
   int dutyNextMonth;
   int maxDutyDay;
   int legs;
   int legsNextMonth;
   int maxLegs;
   int aircraftChanges;
   int aircraftChangesNextMonth;
   int passesThroughDomicile;
   int earliestStart;
   int latestArrival;
	// selection
	int deselectedFlags;
    // overlap
    BOOL hasOverlap;
    // deadheads
    NSCountedSet *deadheadAtStartCities;
    NSCountedSet *deadheadAtEndCities;
    // commuting
    int commutesRequiredCount;
    int overnightsInDomicileCount;
    // vacation
    float vacationPay;
    float vacationDrop;
    int vacationDaysOff;
    float payWithVacation;
}

#pragma mark INITIALIZATION
- (id)initWithNumber:(int)inNumber credit:(float)inCredit block:(float)inBlock trips:(NSArray *)inTrips;

#pragma mark DERIVED VALUES
- (NSString *)blockString;
- (NSString *)blockNextMonthString;
- (NSString *)amPmString;
- (NSString *)earliestStartString;
- (NSString *)latestArrivalString;
- (int)numberOfTrips;
- (float)payPerBlock;
- (float)payPerDay;
- (float)payPerDuty;
- (float)payPerLeg;
- (float)payPerTafb;
- (NSString *)faPosition;

#pragma mark COMPARISON FUNCTIONS
NSInteger compareLines( id foreLine, id aftLine, void * context );
NSComparisonResult compareLinesByPoints( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByAmThenPm( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPmThenAm( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByAircraftChanges( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByCommutesRequired( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByDaysOff( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByLegs(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByNumber( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByOvernightsInDomicile( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPassesThroughDomicile( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPay( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPayPerBlock( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPayPerDay( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPayPerDuty( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByPayPerLeg( CBLine * fore, CBLine * aft );
NSComparisonResult compareLinesByBlock(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByBlockOfDaysOff(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByReserveLinesToBottom(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByBlankLinesToBottom(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByThreeOnThreeOffToBottom(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByTrips(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByWorkDays(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByMaxLegsPerDay(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByVacationPay(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByVacationDaysOff(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByVacationDrop(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByPayWithVacation(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByFAPosition(CBLine * fore, CBLine * aft, void * context);
NSComparisonResult compareLinesByFAAPosition(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByFABPosition(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByFACPosition(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesByFADPosition(CBLine * fore, CBLine * aft);
NSComparisonResult compareLinesBySelected(CBLine * fore, CBLine * aft);

#pragma mark COMPARISON METHOD
- (BOOL)isEqualToLine:(CBLine *)other;

#pragma mark SELECTION METHODS
- (void)setDeselectedFlag:(CBLineDeselectedFlag)flag;
- (void)clearDeselectedFlag:(CBLineDeselectedFlag)flag;

#pragma mark ACCESSORS
- (int)number;
- (void)setNumber:(int)inValue;
- (float)credit;
- (void)setCredit:(float)inValue;
- (float)block;
- (void)setBlock:(float)inValue;
- (NSArray *)trips;
- (void)setTrips:(NSArray *)inValue;
- (BOOL)isReserveLine;
- (void)setIsReserveLine:(BOOL)inValue;
- (BOOL)isBlankLine;
- (void)setIsBlankLine:(BOOL)inValue;
- (NSArray *)lineCalendarEntries;
- (void)setLineCalendarEntries:(NSArray *)inValue;
- (NSArray *)lineCalendarObjects;
- (void)setLineCalendarObjects:(NSArray *)inValue;
- (NSArray *)lineCalendarTags;
- (void)setLineCalendarTags:(NSArray *)inValue;
- (NSArray *)printCalendarEntries;
- (void)setPrintCalendarEntries:(NSArray *)inValue;
- (float)points;
- (void)setPoints:(float)inValue;
- (int)deselectedFlags;
// overlap
- (BOOL)hasOverlap;
- (void)setHasOverlap:(BOOL)inValue;
// derived
- (NSString *)numberString;
- (void)setNumberString:(NSString *)value;
- (float)creditNextMonth;
- (void)setCreditNextMonth:(float)inValue;
- (float)blockNextMonth;
- (void)setBlockNextMonth:(float)inValue;
- (BOOL)isAM;
- (void)setIsAM:(BOOL)inValue;
- (BOOL)isPM;
- (void)setIsPM:(BOOL)inValue;
- (NSString *)t234;
- (void)setT234:(NSString *)inValue;
- (int)turns;
- (void)setTurns:(int)inValue;
- (int)twoDays;
- (void)setTwoDays:(int)inValue;
- (int)threeDays;
- (void)setThreeDays:(int)inValue;
- (int)fourDays;
- (void)setFourDays:(int)inValue;
- (int)oneDayWorkBlocks;
- (void)setOneDayWorkBlocks:(int)inValue;
- (int)twoDayWorkBlocks;
- (void)setTwoDayWorkBlocks:(int)inValue;
- (int)threeDayWorkBlocks;
- (void)setThreeDayWorkBlocks:(int)inValue;
- (int)fourDayWorkBlocks;
- (void)setFourDayWorkBlocks:(int)inValue;
- (int)longestDaysOffBlock;
- (void)setLongestDaysOffBlock:(int)inValue;
- (BOOL)is3on3off;
- (void)setIs3on3off:(BOOL)inValue;
- (int)weekends;
- (void)setWeekends:(int)inValue;
- (int)workDays;
- (void)setWorkDays:(int)inValue;
- (NSCountedSet *)overnightCities;
- (void)setOvernightCities:(NSCountedSet *)inValue;
- (NSSet *)workDates;
- (void)setWorkDates:(NSSet *)inValue;
- (NSSet *)workDatesNextMonth;
- (void)setWorkDatesNextMonth:(NSSet *)inValue;
- (int)daysOff;
- (void)setDaysOff:(int)inValue;
- (int)tafb;
- (void)setTafb:(int)inValue;
- (int)duty;
- (void)setDuty:(int)inValue;
- (int)dutyNextMonth;
- (void)setDutyNextMonth:(int)inValue;
- (int)maxDutyDay;
- (void)setMaxDutyDay:(int)inValue;
- (int)legs;
- (void)setLegs:(int)inValue;
- (int)maxLegs;
- (void)setMaxLegs:(int)inValue;
- (int)aircraftChanges;
- (void)setAircraftChanges:(int)inValue;
- (int)legsNextMonth;
- (void)setLegsNextMonth:(int)inValue;
- (int)aircraftChangesNextMonth;
- (void)setAircraftChangesNextMonth:(int)inValue;
- (int)passesThroughDomicile;
- (void)setPassesThroughDomicile:(int)inValue;
- (int) earliestStart;
- (void)setEarliestStart:(int)inValue;
- (int) latestArrival;
- (void)setLatestArrival:(int)inValue;
// deadheads
- (NSCountedSet *)deadheadAtStartCities;
- (void)setDeadheadAtStartCities:(NSCountedSet *)value;
- (NSCountedSet *)deadheadAtEndCities;
- (void)setDeadheadAtEndCities:(NSCountedSet *)value;
// commuting
- (int)commutesRequiredCount;
- (void)setCommutesRequiredCount:(int)value;
- (int)overnightsInDomicileCount;
- (void)setOvernightsInDomicileCount:(int)value;


@end

#pragma mark LINE TRIP/DATE KEYS
extern NSString *CBLineTripNumberKey;
extern NSString *CBLineTripDateKey;
extern NSString *CBLineTripPositionKey;
extern NSString *CBLineTripReserveStartTimeKey;
extern NSString *CBLineTripReserveEndTimeKey;
#pragma mark COMPARISON FUNCTION KEYS
extern NSString *CBLineComparisonSortSelectionsKey;
extern NSString *CBLineComparisonFaPositionsKey;