//
//  CBDataModel.h
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 03 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBDocument;
@class CSBidPeriod;
@class CBLine;
@class CBTrip;
@class CBBlockTime;
@class CSCalendarWeek;

// these are not used in the new data model format
// included only for compatibility with older versions
typedef enum enumCBSortSelection {
   CBAmThenPmSort,
   CBPmThenAmSort,
   CBAircraftChangesSort,
   CBBlockSort,
   CBBlockOfDaysOffSort,
   CBLegsSort,
   CBNumberSort,
   CBPassesThroughDomicileSort,
   CBPaySort,
   CBPayPerBlockSort,
   CBPayPerDaySort,
   CBPayPerDutySort,
   CBPayPerLegSort,
   CBPointsSort,
   CBTripsSort,
   CBWorkDaysSort
} CBSortSelection;

typedef enum enumCBSelectChoice {
   CBNoSelect,
   CBSelectWithAtLeastOne,
   CBSelectWithNone
} CBSelectChoice;

typedef enum enumCBLineNumber {
   CBFaReserveLineNumber = -1,
   CBFaMrtLineNumber     = -2
} CBLineNumber;

typedef enum {
   CSVacationSelectAtBothEnds,
   CSVacationSelectAtEitherEnd,
   CSVacationSelectAtStart,
   CSVacationSelectAtEnd
} CSVacationSelectEndChoice;

@interface CBDataModel : NSObject <NSCoding>
{
   // used to disable sorting until file reading is complete
   BOOL sortingEnabled;
   // basic document data
   CBDocument * document;
   NSCalendarDate * month;
   NSString * crewBase;
   NSString * crewPosition; // needed for bid submission
   int bidRound;
   NSArray * lines;
   NSDictionary * trips;
   // bid period
   CSBidPeriod *bidPeriod;
   // calendar
   NSCalendarDate *firstBidDate;
   NSCalendarDate *firstCalendarDate;
   NSInteger calendarOffset;
   NSCalendarDate *lastBidDate;
   // derived
   NSArray * overnightCities;
   // top/bottom freeze
   int topFreezeIndex;
   int bottomFreezeIndex;
   // sort selections
   NSMutableArray * inUseSortSelections;
   NSMutableArray * availableSortSelections;
   // FA position
   NSMutableArray *faPositions;
   // FA reserve bid
   BOOL hasFaReserveBid;
   BOOL hasFaMrtBid;
   CBLine *faReserveBidLine;
   CBLine *faMrtBidLine;
   // points
   BOOL linePointsIncludePay;
   // reserve/blank lines to bottom
   BOOL reserveLinesToBottomCheckboxValue;
   BOOL blankLinesToBottomCheckboxValue;
   // SELECT/POINTS
   // aircraft changes
   BOOL aircraftChangesSelectCheckboxValue;
   int aircraftChangesSelectTriggerValue;
   BOOL aircraftChangesPointsCheckboxValue;
   float aircraftChangesPointsValue;
   // am/pm
   BOOL amSelectCheckboxValue;
   BOOL pmSelectCheckboxValue;
   BOOL amPointsCheckboxValue;
   float amPointsValue;
   BOOL pmPointsCheckboxValue;
   float pmPointsValue;
   // trip length
   BOOL turnSelectCheckboxValue;
   int turnSelectTriggerValue;
   BOOL twoDaySelectCheckboxValue;
   int twoDaySelectTriggerValue;
   BOOL threeDaySelectCheckboxValue;
   int threeDaySelectTriggerValue;
   BOOL fourDaySelectCheckboxValue;
   int fourDaySelectTriggerValue;
   BOOL turnPointsCheckboxValue;
   float turnPointsValue;
   BOOL twoDayPointsCheckboxValue;
   float twoDayPointsValue;
   BOOL threeDayPointsCheckboxValue;
   float threeDayPointsValue;
   BOOL fourDayPointsCheckboxValue;
   float fourDayPointsValue;
   // block of days off
   BOOL blockOfDaysOffSelectCheckboxValue;
   int blockOfDaysOffSelectTriggerValue;
   BOOL blockOfDaysOffPointsCheckboxValue;
   int blockOfDaysOffPointsTriggerValue;
   float blockOfDaysOffPointsValue;
   // 3-on/3-off
   BOOL threeOnThreeOffToBottomCheckboxValue;
   // days of month
   BOOL daysOfMonthSelectCheckboxValue;
   BOOL daysOfMonthPointsCheckboxValue;
   NSSet * daysOfMonthSelectValues;
   NSDictionary * daysOfMonthPointsValues;
   NSSet * daysOfWeekSelectValues;
   NSDictionary * daysOfWeekPointsValues;
   // overnight cities
   CBSelectChoice overnightCitiesSelectMatrixValue;
   NSSet * overnightCitiesSelectValues;
   BOOL overnightCitiesPointsCheckboxValue;
   NSDictionary * overnightCitiesPointsValues;
   // overlap
   NSArray *        overlapFormValues;
   BOOL             noOverlapSelectCheckboxValue;
   BOOL             noOverlapPointsCheckboxValue;
   float            noOverlapPointsValue;
   BOOL             overlapPointsCheckboxValue;
   float            overlapPointsValue;
   // deadheads
   BOOL deadheadAtStartSelectCheckboxValue;
   NSArray *deadheadAtStartCities;
   NSString *deadheadAtStartCity;
   BOOL deadheadAtStartPointsCheckboxValue;
   float deadheadAtStartPointsValue;
   BOOL deadheadAtEndSelectCheckboxValue;
   NSArray *deadheadAtEndCities;
   NSString *deadheadAtEndCity;
   BOOL deadheadAtEndPointsCheckboxValue;
   float deadheadAtEndPointsValue;
   // commute times
   CBBlockTime *commuteWeekdayStartValue;
   CBBlockTime *commuteFridayStartValue;
   CBBlockTime *commuteSaturdayStartValue;
   CBBlockTime *commuteSundayStartValue;
   CBBlockTime *commuteWeekdayEndValue;
   CBBlockTime *commuteFridayEndValue;
   CBBlockTime *commuteSaturdayEndValue;
   CBBlockTime *commuteSundayEndValue;
   BOOL  considerAdjacentTripsNotCommutable;
   // commute selecting
//   BOOL commuteSelectStartCheckboxValue;
//   BOOL commuteSelectStartAllTripsValue;
//   BOOL commuteSelectEndCheckboxValue;
//   BOOL commuteSelectEndAllTripsValue;
//   BOOL commuteSelectBothEndsCheckboxValue;
//   BOOL commuteSelectBothEndsAllTripsValue;
   // commute points
//   BOOL  commutePointsStartCheckboxValue;
//   float commutePointsStartValue;
//   BOOL  commutePointsEndCheckboxValue;
//   float commutePointsEndValue;
//   BOOL  commutePointsBothEndsCheckboxValue;
//   float commutePointsBothEndsValue;
//   BOOL  commutePointsNotStartCheckboxValue;
//   float commutePointsNotStartValue;
//   BOOL  commutePointsNotEndCheckboxValue;
//   float commutePointsNotEndValue;
//   BOOL  commutePointsNotBothEndsCheckboxValue;
//   float commutePointsNotBothEndsValue;
   // commutes required and overnights in domicile select
   BOOL commuteSelectsByCommutesRequired;
   int commuteSelectsByCommutesRequiredTrigger;
   BOOL commuteSelectsByOvernightsInDomicile;
   int commuteSelectsByOvernightsInDomicileTrigger;
   // commutes and overnights in domicile points
   BOOL  commuteAssignsPointsForCommutesRequired;
   float commutePointsForCommutesRequired;
   BOOL  commuteAssignsPointsForOvernightsInDomicile;
   float commutePointsForOvernightsInDomicile;
   // vacation calendar weeks
   NSArray *vacationWeeks;
   NSIndexSet *selectedVacationWeekIndexes;
   BOOL vacationSelects;
   CSVacationSelectEndChoice vacationEndSelect;
   // max legs per day
   BOOL maxLegsPerDaySelectCheckboxValue;
   int maxLegsPerDaySelectTriggerValue;
   BOOL maxLegsPerDayLessThanOrEqualPointsCheckboxValue;
   int maxLegsPerDayLessThanOrEqualPointsTriggerValue;
   float maxLegsPerDayLessThanOrEqualPointsValue;
   BOOL maxLegsPerDayGreaterThanPointsCheckboxValue;
   int maxLegsPerDayGreaterThanPointsTriggerValue;
   float maxLegsPerDayGreaterThanPointsValue;
}

#pragma mark INITIALIZATION
- (id)initWithDocument:(CBDocument *)inDocument;
- (void)initializeAfterUnarchivingWithDocument:(CBDocument *)inDocument;

#pragma mark DERIVED VALUES
- (NSArray *)sortSelectionsArray;
- (void)addNewSortSelections;
- (NSArray *)initialFaPositionsArray;
- (void)initializeDerivedValues;
- (NSMutableArray *)emptyCalendarEntries;
- (NSMutableArray *)emptyCalendarObjects;
- (NSMutableArray *)emptyCalendarTags;
- (void)updateAmOrPm:(NSNotification *)notification;
- (void)updateTripsIsAm;
- (void)updateLinesIsAmOrPm;
- (int)daysInMonth;
- (float)lineBlockWithMinutes:(int)blockMinutes;

#pragma mark SORTING
- (void)sortLines;
- (NSValue *)sortFunctionValueWithSortSelection:(NSString *)sortSelection;
- (void)adjustPointsForLines;
NSInteger compareSortSelection(id fore, id aft, void * context );

#pragma mark ARRAY OBJECT MANIPULATION
- (void)moveLinesArrayRows:(NSArray *)oldRows toRows:(NSArray *)newRows;
- (void)adjustIndexesAfterMovingLinesArrayRows:(NSArray *)oldRows toRows:(NSArray *)newRows;
- (void)insertLine:(CBLine *)line atIndex:(int)lineIndex;
- (void)removeLine:(CBLine *)line atIndex:(int)lineIndex;
- (void)insertFaReserveBidAtIndex:(unsigned)index;
- (NSUInteger)removeFaReserveBid;
- (void)insertFaMrtBidAtIndex:(unsigned)index;
- (NSUInteger)removeFaMrtBid;
- (NSUInteger)faReserveBidIndex;
- (NSUInteger)faMrtBidIndex;
- (CBLine *)faReserveBidLine;
- (CBLine *)faMrtBidLine;

#pragma mark SELECTING
- (void)selectLinesByAircraftChanges;
- (void)selectLinesByAm;
- (void)selectLinesByPm;
- (void)selectLinesByTurns;
- (void)selectLinesByTwoDays;
- (void)selectLinesByThreeDays;
- (void)selectLinesByFourDays;
- (void)selectLinesByBlockOfDaysOff;
- (void)selectLinesByDaysOfMonth;
- (void)selectLinesByDeadheadAtStart;
- (void)selectLinesByDeadheadAtEnd;
- (void)selectLinesByOvernightCities;
- (void)selectLinesByNoOverlap;
- (void)selectLinesByMaxLegsPerDay;

#pragma mark CLIPBOARD TEXT
- (NSString *)clipboardTextWithLine:(CBLine *)line;

#pragma mark STORAGE
- (NSArray *)stringSortSelectionsWithDictionarySortSelections:(NSArray *)sortSelections;
- (void)saveChoices:(NSString *)path;
- (void)applyChoices:(NSString *)path;
// methods that convert non-string keys to strings and vice versa
- (NSDictionary *)stringKeysDictionaryWithNumberKeysDictionary:(NSDictionary *)numberKeysDictionary;
- (NSDictionary *)numberKeysDictionaryWithStringKeysDictionary:(NSDictionary *)stringKeysDictionary;
// save sort selections, adding sort selections from current data model that
// don't exist in sort selections being applied
- (void)saveSortSelectionsUsingChoices:(NSDictionary *)choices;

#pragma mark INTERFACE ITEM NOTIFICATIONS
- (NSString *)notificationNameForIdentifier:(NSString *)identifier;
- (void)postNotificationForIdentifier:(NSString *)identifier value:(id)value;

#pragma mark DERIVED ACCESSORS
- (BOOL)isFlightAttendantBid;
- (BOOL)isFlightAttendantFirstRoundBid;
- (BOOL)isPilotSecondRoundBid;

#pragma mark CALENDAR METHODS
- (NSCalendarDate *)firstBidDate;
- (NSCalendarDate *)firstCalendarDate;
- (int)calendarOffset;
- (NSCalendarDate *)lastBidDate;

#pragma mark ACCESSORS
// basic document data
- (CBDocument *)document;
- (void)setDocument:(CBDocument *)inValue;
- (NSUndoManager *)undoManager;
- (NSCalendarDate *)month;
- (void)setMonth:(NSCalendarDate *)inValue;
- (NSString *)crewBase;
- (void)setCrewBase:(NSString *)inValue;
- (NSString *)crewPosition;
- (int)bidRound;
- (void)setBidRound:(int)inValue;
- (void)setCrewPosition:(NSString *)inValue;
- (NSArray *)lines;
- (void)setLines:(NSArray *)inValue;
- (NSDictionary *)trips;
- (void)setTrips:(NSDictionary *)inValue;
- (CSBidPeriod *)bidPeriod;
- (void)setBidPeriod:(CSBidPeriod *)value;
- (BOOL)sortingEnabled;
- (void)setSortingEnabled:(BOOL)inValue;
// derived
- (NSArray *)overnightCities;
- (void)setOvernightCities:(NSArray *)inValue;
// top/bottom freeze
- (int)topFreezeIndex;
- (void)setTopFreezeIndex:(int)inValue;
- (int)bottomFreezeIndex;
- (void)setBottomFreezeIndex:(int)inValue;
// sort selections
- (NSArray *)availableSortSelections;
- (void)setAvailableSortSelections:(NSArray *)inValue;
- (NSArray *)inUseSortSelections;
- (void)setInUseSortSelections:(NSArray *)inValue;
// FA positions
- (NSMutableArray *)faPositions;
- (void)setFaPositions:(NSArray *)inValue;
// FA reserve bid
- (BOOL)hasFaReserveBid;
- (void)setHasFaReserveBid:(BOOL)inValue;
// FA MRT bid
- (BOOL)hasFaMrtBid;
- (void)setHasFaMrtBid:(BOOL)inValue;
// points
- (BOOL)linePointsIncludePay;
- (void)setLinePointsIncludePay:(BOOL)inValue;
// reserve/blank lines to bottom
- (BOOL)reserveLinesToBottomCheckboxValue;
- (void)setReserveLinesToBottomCheckboxValue:(BOOL)inValue;
- (BOOL)blankLinesToBottomCheckboxValue;
- (void)setBlankLinesToBottomCheckboxValue:(BOOL)inValue;
// 3-on/3-off
- (BOOL)threeOnThreeOffToBottomCheckboxValue;
- (void)setThreeOnThreeOffToBottomCheckboxValue:(BOOL)inValue;

@end

/******************************************************************************/
//
//  Aircraft Changes Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBAircraftChangesTabDataModel )

#pragma mark ACCESSORS
- (BOOL)aircraftChangesSelectCheckboxValue;
- (void)setAircraftChangesSelectCheckboxValue:(BOOL)inValue;
- (int)aircraftChangesSelectTriggerValue;
- (void)setAircraftChangesSelectTriggerValue:(int)inValue;
- (BOOL)aircraftChangesPointsCheckboxValue;
- (void)setAircraftChangesPointsCheckboxValue:(BOOL)inValue;
- (float)aircraftChangesPointsValue;
- (void)setAircraftChangesPointsValue:(float)inValue;

@end

/******************************************************************************/
//
//  AM/PM Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBAmPmTabDataModel )

#pragma mark ACCESSORS
- (BOOL)amSelectCheckboxValue;
- (void)setAmSelectCheckboxValue:(BOOL)inValue;
- (BOOL)pmSelectCheckboxValue;
- (void)setPmSelectCheckboxValue:(BOOL)inValue;
- (BOOL)amPointsCheckboxValue;
- (void)setAmPointsCheckboxValue:(BOOL)inValue;
- (BOOL)amPointsValue;
- (void)setAmPointsValue:(float)inValue;
- (BOOL)pmPointsCheckboxValue;
- (void)setPmPointsCheckboxValue:(BOOL)inValue;
- (BOOL)pmPointsValue;
- (void)setPmPointsValue:(float)inValue;

@end

/******************************************************************************/
//
//  Trip Length Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBTripLengthTabDataModel )

#pragma mark TURNS
- (BOOL)turnSelectCheckboxValue;
- (void)setTurnSelectCheckboxValue:(BOOL)inValue;
- (int)turnSelectTriggerValue;
- (void)setTurnSelectTriggerValue:(int)inValue;
- (BOOL)turnPointsCheckboxValue;
- (void)setTurnPointsCheckboxValue:(BOOL)inValue;
- (float)turnPointsValue;
- (void)setTurnPointsValue:(float)inValue;
#pragma mark TWO-DAYS
- (BOOL)twoDaySelectCheckboxValue;
- (void)setTwoDaySelectCheckboxValue:(BOOL)inValue;
- (int)twoDaySelectTriggerValue;
- (void)setTwoDaySelectTriggerValue:(int)inValue;
- (BOOL)twoDayPointsCheckboxValue;
- (void)setTwoDayPointsCheckboxValue:(BOOL)inValue;
- (float)twoDayPointsValue;
- (void)setTwoDayPointsValue:(float)inValue;
#pragma mark THREE-DAYS
- (BOOL)threeDaySelectCheckboxValue;
- (void)setThreeDaySelectCheckboxValue:(BOOL)inValue;
- (int)threeDaySelectTriggerValue;
- (void)setThreeDaySelectTriggerValue:(int)inValue;
- (BOOL)threeDayPointsCheckboxValue;
- (void)setThreeDayPointsCheckboxValue:(BOOL)inValue;
- (float)threeDayPointsValue;
- (void)setThreeDayPointsValue:(float)inValue;
#pragma mark FOUR-DAYS
- (BOOL)fourDaySelectCheckboxValue;
- (void)setFourDaySelectCheckboxValue:(BOOL)inValue;
- (int)fourDaySelectTriggerValue;
- (void)setFourDaySelectTriggerValue:(int)inValue;
- (BOOL)fourDayPointsCheckboxValue;
- (void)setFourDayPointsCheckboxValue:(BOOL)inValue;
- (float)fourDayPointsValue;
- (void)setFourDayPointsValue:(float)inValue;

@end

/******************************************************************************/
//
//  Block of Days Off Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBBlockOfDaysOffTabDataModel )

#pragma mark ACCESSORS
- (BOOL)blockOfDaysOffSelectCheckboxValue;
- (void)setBlockOfDaysOffSelectCheckboxValue:(BOOL)inValue;
- (int)blockOfDaysOffSelectTriggerValue;
- (void)setBlockOfDaysOffSelectTriggerValue:(int)inValue;
- (BOOL)blockOfDaysOffPointsCheckboxValue;
- (void)setBlockOfDaysOffPointsCheckboxValue:(BOOL)inValue;
- (int)blockOfDaysOffPointsTriggerValue;
- (void)setBlockOfDaysOffPointsTriggerValue:(int)inValue;
- (float)blockOfDaysOffPointsValue;
- (void)setBlockOfDaysOffPointsValue:(float)inValue;

@end

/******************************************************************************/
//
//  Days of Month Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBDaysOfMonthTabDataModel )
- (BOOL)daysOfMonthSelectCheckboxValue;
- (void)setDaysOfMonthSelectCheckboxValue:(BOOL)inValue;
- (BOOL)daysOfMonthPointsCheckboxValue;
- (void)setDaysOfMonthPointsCheckboxValue:(BOOL)inValue;
// days of month select values are NSCalendarDate(s) that correspond to days
// wanted off
- (NSSet *)daysOfMonthSelectValues;
- (void)setDaysOfMonthSelectValues:(NSSet *)inValue;
// days of month points values have key of NSCalendarDate and object an NSNumber
// (float value) that corresponds to points for that date
- (NSDictionary *)daysOfMonthPointsValues;
- (void)setDaysOfMonthPointsValues:(NSDictionary *)inValue;
// day of week select values are NSNumber(s) that represent day of week (0-6)
- (NSSet *)daysOfWeekSelectValues;
- (void)setDaysOfWeekSelectValues:(NSSet *)inValue;
// day of week points values are NSNumber(s) (float value) correspond to 
// points for day of week
- (NSDictionary *)daysOfWeekPointsValues;
- (void)setDaysOfWeekPointsValues:(NSDictionary *)inValue;
@end

/******************************************************************************/
//
//  Overnight Cities Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBOvernightCitiesDataModel )
- (CBSelectChoice)overnightCitiesSelectMatrixValue;
- (void)setOvernightCitiesSelectMatrixValue:(CBSelectChoice)inValue;
- (BOOL)overnightCitiesPointsCheckboxValue;
- (void)setOvernightCitiesPointsCheckboxValue:(BOOL)inValue;
// overnight cities select values are strings that correspond to cities
// either wanted or not wanted
- (NSSet *)overnightCitiesSelectValues;
- (void)setOvernightCitiesSelectValues:(NSSet *)inValue;
// overnight cities points values have key of NSString for a city and object an 
// NSNumber (float value) that corresponds to points for that city
- (NSDictionary *)overnightCitiesPointsValues;
- (void)setOvernightCitiesPointsValues:(NSDictionary *)inValue;

@end

/******************************************************************************/
//
//  Overlap Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( OverlapTabDataModel )

#pragma mark INITIALIZATION
- (NSArray *)zeroOverlapValues;
- (NSCalendarDate *)initialReleaseTime;

#pragma mark OVERLAP METHODS
- (void)detectOverlaps;
- (void)setOverlapFormValuesWithPreviousMonthFile:(NSString *)path line:(int)lineNumber numberOfEntries:(unsigned)numberOfEntries;
- (NSArray *)previousMonthLineOverlapEntriesWithLineCalendarObjects:(NSArray *)lineCalendarObjects startDate:(NSCalendarDate *)startDate;
- (NSDictionary *)overlapEntryForLineCalendarObject:(NSDictionary *)object date:(NSCalendarDate *)date;
//- (NSCalendarDate *)previousMonthOverlapEntriesStartDate;
//- (unsigned)previousMonthLineCalendarObjectsStartIndex;

#pragma mark ACCESSORS
- (NSArray *)overlapFormValues;
- (void)setOverlapFormValues:(NSArray *)inValue;
//- (NSCalendarDate *)overlapReleaseTimeValue;
//- (void)setOverlapReleaseTimeValue:(NSCalendarDate *)inValue;
- (BOOL)noOverlapSelectCheckboxValue;
- (void)setNoOverlapSelectCheckboxValue:(BOOL)inValue;
- (BOOL)noOverlapPointsCheckboxValue;
- (void)setNoOverlapPointsCheckboxValue:(BOOL)inValue;
- (float)noOverlapPointsValue;
- (void)setNoOverlapPointsValue:(float)inValue;
- (BOOL)overlapPointsCheckboxValue;
- (void)setOverlapPointsCheckboxValue:(BOOL)inValue;
- (float)overlapPointsValue;
- (void)setOverlapPointsValue:(float)inValue;

@end

/******************************************************************************/
//
//  Deadheads Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBDeadheadsTabDataModel )

#pragma mark ACCESSORS
- (BOOL)deadheadAtStartSelectCheckboxValue;
- (void)setDeadheadAtStartSelectCheckboxValue:(BOOL)value;

- (NSArray *)deadheadAtStartCities;
- (void)setDeadheadAtStartCities:(NSArray *)value;

- (NSString *)deadheadAtStartCity;
- (void)setDeadheadAtStartCity:(NSString *)value;

- (BOOL)deadheadAtStartPointsCheckboxValue;
- (void)setDeadheadAtStartPointsCheckboxValue:(BOOL)value;

- (float)deadheadAtStartPointsValue;
- (void)setDeadheadAtStartPointsValue:(float)value;

- (BOOL)deadheadAtEndSelectCheckboxValue;
- (void)setDeadheadAtEndSelectCheckboxValue:(BOOL)value;

- (NSArray *)deadheadAtEndCities;
- (void)setDeadheadAtEndCities:(NSArray *)value;

- (NSString *)deadheadAtEndCity;
- (void)setDeadheadAtEndCity:(NSString *)value;

- (BOOL)deadheadAtEndPointsCheckboxValue;
- (void)setDeadheadAtEndPointsCheckboxValue:(BOOL)value;

- (float)deadheadAtEndPointsValue;
- (void)setDeadheadAtEndPointsValue:(float)value;

@end

/******************************************************************************/
//
//  Commuting Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBCommutingTabDataModel )

#pragma mark Initialization
- (void)initializeCommutingTabDataModel;

#pragma mark Actions
- (void)fillDownCommuteTimes;

#pragma mark Selecting
- (void)selectLinesByCommutesRequired;
- (void)selectLinesByOvernightsInDomicile;
- (void)setLinesCommutesRequiredCount;
- (void)setLinesOvernightsInDomicileCount;
//- (void)selectLinesByCommutableAtStart;
//- (void)selectLinesByCommutableAtEnd;
//- (void)selectLinesByCommutableAtBothEnds;

#pragma mark Points Assignment
//- (float)commuteAtStartPointsForLine:(CBLine *)line;
//- (float)commuteAtEndPointsForLine:(CBLine *)line;
//- (float)commuteAtBothEndsPointsForLine:(CBLine *)line;
//- (float)commuteNotAtStartPointsForLine:(CBLine *)line;
//- (float)commuteNotAtEndPointsForLine:(CBLine *)line;
//- (float)commuteNotAtBothEndsPointsForLine:(CBLine *)line;
//- (float)commutesRequiredPointsForLine:(CBLine *)line;
//- (float)overnightsInDomicileRequiredPointsForLine:(CBLine *)line;

#pragma mark Helper Methods
- (BOOL)lineTrip:(NSDictionary *)lineTrip isCommutableAtStartWithPreviousLineTrip:(NSDictionary *)prevLineTrip;
- (BOOL)lineTrip:(NSDictionary *)lineTrip isCommutableAtEndWithNextLineTrip:(NSDictionary *)nextLineTrip;
- (BOOL)lineTrip:(NSDictionary *)lineTrip isAdjacentToNextLineTrip:(NSDictionary *)nextLineTrip;
- (int)commuteStartTimeForLineTrip:(NSDictionary *)lineTrip;
- (int)commuteEndTimeForLineTrip:(NSDictionary *)lineTrip;

#pragma mark Accessors
//- (BOOL)commuteSelectStartCheckboxValue;
//- (void)setCommuteSelectStartCheckboxValue:(BOOL)value;
//
//- (BOOL)commuteSelectStartAllTripsValue;
//- (void)setCommuteSelectStartAllTripsValue:(BOOL)value;

- (CBBlockTime *)commuteWeekdayStartValue;
- (void)setCommuteWeekdayStartValue:(CBBlockTime *)value;

- (CBBlockTime *)commuteFridayStartValue;
- (void)setCommuteFridayStartValue:(CBBlockTime *)value;

- (CBBlockTime *)commuteSaturdayStartValue;
- (void)setCommuteSaturdayStartValue:(CBBlockTime *)value;

- (CBBlockTime *)commuteSundayStartValue;
- (void)setCommuteSundayStartValue:(CBBlockTime *)value;

//- (BOOL)commuteSelectEndCheckboxValue;
//- (void)setCommuteSelectEndCheckboxValue:(BOOL)value;
//
//- (BOOL)commuteSelectEndAllTripsValue;
//- (void)setCommuteSelectEndAllTripsValue:(BOOL)value;

- (CBBlockTime *)commuteWeekdayEndValue;
- (void)setCommuteWeekdayEndValue:(CBBlockTime *)value;

- (CBBlockTime *)commuteFridayEndValue;
- (void)setCommuteFridayEndValue:(CBBlockTime *)value;

- (CBBlockTime *)commuteSaturdayEndValue;
- (void)setCommuteSaturdayEndValue:(CBBlockTime *)value;

- (CBBlockTime *)commuteSundayEndValue;
- (void)setCommuteSundayEndValue:(CBBlockTime *)value;

- (BOOL)considerAdjacentTripsNotCommutable;
- (void)setConsiderAdjacentTripsNotCommutable:(BOOL)value;

//- (BOOL)commutePointsStartCheckboxValue;
//- (void)setCommutePointsStartCheckboxValue:(BOOL)value;
//
//- (float)commutePointsStartValue;
//- (void)setCommutePointsStartValue:(float)value;
//
//- (BOOL)commutePointsEndCheckboxValue;
//- (void)setCommutePointsEndCheckboxValue:(BOOL)value;
//
//- (float)commutePointsEndValue;
//- (void)setCommutePointsEndValue:(float)value;
//
//- (BOOL)commuteSelectBothEndsCheckboxValue;
//- (void)setCommuteSelectBothEndsCheckboxValue:(BOOL)value;
//
//- (BOOL)commuteSelectBothEndsAllTripsValue;
//- (void)setCommuteSelectBothEndsAllTripsValue:(BOOL)value;
//
//- (BOOL)commutePointsBothEndsCheckboxValue;
//- (void)setCommutePointsBothEndsCheckboxValue:(BOOL)value;
//
//- (float)commutePointsBothEndsValue;
//- (void)setCommutePointsBothEndsValue:(float)value;
//
//- (BOOL)commutePointsNotStartCheckboxValue;
//- (void)setCommutePointsNotStartCheckboxValue:(BOOL)value;
//
//- (float)commutePointsNotStartValue;
//- (void)setCommutePointsNotStartValue:(float)value;
//
//- (BOOL)commutePointsNotEndCheckboxValue;
//- (void)setCommutePointsNotEndCheckboxValue:(BOOL)value;
//
//- (float)commutePointsNotEndValue;
//- (void)setCommutePointsNotEndValue:(float)value;
//
//- (BOOL)commutePointsNotBothEndsCheckboxValue;
//- (void)setCommutePointsNotBothEndsCheckboxValue:(BOOL)value;
//
//- (float)commutePointsNotBothEndsValue;
//- (void)setCommutePointsNotBothEndsValue:(float)value;

- (BOOL)commuteSelectsByCommutesRequired;
- (void)setCommuteSelectsByCommutesRequired:(BOOL)value;

- (int)commuteSelectsByCommutesRequiredTrigger;
- (void)setCommuteSelectsByCommutesRequiredTrigger:(int)value;

- (BOOL)commuteSelectsByOvernightsInDomicile;
- (void)setCommuteSelectsByOvernightsInDomicile:(BOOL)value;

- (int)commuteSelectsByOvernightsInDomicileTrigger;
- (void)setCommuteSelectsByOvernightsInDomicileTrigger:(int)value;

- (BOOL)commuteAssignsPointsForCommutesRequired;
- (void)setCommuteAssignsPointsForCommutesRequired:(BOOL)value;

- (float)commutePointsForCommutesRequired;
- (void)setCommutePointsForCommutesRequired:(float)value;

- (BOOL)commuteAssignsPointsForOvernightsInDomicile;
- (void)setCommuteAssignsPointsForOvernightsInDomicile:(BOOL)value;

- (float)commutePointsForOvernightsInDomicile;
- (void)setCommutePointsForOvernightsInDomicile:(float)value;

@end

/******************************************************************************/
//
//  Vacation Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBVacationTabDataModel )

#pragma mark
#pragma mark Initialization
#pragma mark

- (void)initializeVacationTabDataModel;

#pragma mark
#pragma mark Selecting
#pragma mark

- (void)selectLinesByVacation;
- (BOOL)line:(CBLine *)line hasTripsThatTouchCalendarWeekAtBothEnds:(CSCalendarWeek *)calendarWeek;
- (BOOL)line:(CBLine *)line hasTripThatTouchesCalendarWeekAtStart:(CSCalendarWeek *)calendarWeek nextLineTripIndex:(NSUInteger *)nextIndexPtr;
- (BOOL)line:(CBLine *)line hasTripThatTouchesCalendarWeekAtEnd:(CSCalendarWeek *)calendarWeek lineTripStartIndex:(NSUInteger)startIndex;

#pragma mark
#pragma mark Vacation Pay
#pragma mark

- (void)computeVacationPay;
- (float)vacationPayForLine:(CBLine *)line calendarWeek:(CSCalendarWeek *)calendarWeek;

#pragma mark
#pragma mark Vacation Days Off
#pragma mark

- (int)vacationDaysOffForLine:(CBLine *)line calendarWeek:(CSCalendarWeek *)calendarWeek;

#pragma mark
#pragma mark Utility Methods
#pragma mark

- (NSCalendarDate *)lastTripDateForLine:(CBLine *)line beforeCalendarWeek:(CSCalendarWeek *)calendarWeek;
- (NSCalendarDate *)firstTripDateForLine:(CBLine *)line afterCalendarWeek:(CSCalendarWeek *)calendarWeek;
- (BOOL)lineTrip:(NSDictionary *)lineTrip touchesCalendarWeekAtStart:(CSCalendarWeek *)calendarWeek;
- (BOOL)lineTrip:(NSDictionary *)lineTrip touchesCalendarWeekAtEnd:(CSCalendarWeek *)calendarWeek;
- (NSCalendarDate *)tripStartDateForLineTrip:(NSDictionary *)lineTrip;
- (NSCalendarDate *)tripEndDateForLineTrip:(NSDictionary *)lineTrip;
- (BOOL)isReserveLineTrip:(NSDictionary *)lineTrip;

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSArray *)vacationWeeks;
- (void)setVacationWeeks:(NSArray *)value;

- (NSIndexSet *)selectedVacationWeekIndexes;
- (void)setSelectedVacationWeekIndexes:(NSIndexSet *)value;

- (BOOL)vacationSelects;
- (void)setVacationSelects:(BOOL)value;

- (CSVacationSelectEndChoice)vacationEndSelect;
- (void)setVacationEndSelect:(CSVacationSelectEndChoice)value;

@end

/******************************************************************************/
//
//  Max Legs Per Day Tab Data Model
//
/******************************************************************************/
@interface CBDataModel ( CBMaxLegsPerDayTabDataModel )

#pragma mark ACCESSORS
// select
- (BOOL)maxLegsPerDaySelectCheckboxValue;
- (void)setMaxLegsPerDaySelectCheckboxValue:(BOOL)value;
- (int)maxLegsPerDaySelectTriggerValue;
- (void)setMaxLegsPerDaySelectTriggerValue:(int)value;
// less than or equal points
- (BOOL)maxLegsPerDayLessThanOrEqualPointsCheckboxValue;
- (void)setMaxLegsPerDayLessThanOrEqualPointsCheckboxValue:(BOOL)value;
- (int)maxLegsPerDayLessThanOrEqualPointsTriggerValue;
- (void)setMaxLegsPerDayLessThanOrEqualPointsTriggerValue:(int)value;
- (float)maxLegsPerDayLessThanOrEqualPointsValue;
- (void)setMaxLegsPerDayLessThanOrEqualPointsValue:(float)value;
// greater than points
- (BOOL)maxLegsPerDayGreaterThanPointsCheckboxValue;
- (void)setMaxLegsPerDayGreaterThanPointsCheckboxValue:(BOOL)value;
- (int)maxLegsPerDayGreaterThanPointsTriggerValue;
- (void)setMaxLegsPerDayGreaterThanPointsTriggerValue:(int)value;
- (float)maxLegsPerDayGreaterThanPointsValue;
- (void)setMaxLegsPerDayGreaterThanPointsValue:(float)value;

@end

#pragma mark NOTIFICATION NAMES
extern NSString * CBDataModelLinesChangedNotification;
extern NSString * CBDataModelLinesMovedNotification;
extern NSString * CBDataModelSortSelectionsChangedNotification;

// notifications defined in CBDaysOfMonthTabDataModel.m
extern NSString *CBDataModelDaysOfMonthSelectValuesChangedNotification;
extern NSString *CBDataModelDaysOfMonthPointsValuesChangedNotification;
extern NSString *CBDataModelDaysOfWeekSelectValuesChangedNotification;
extern NSString *CBDataModelDaysOfWeekPointsValuesChangedNotification;

extern NSString * CBDataModelOverlapFormValuesChangedNotification;
extern NSString * CBDataModelOverlapReleaseTimeValueChangedNotification;
extern NSString * CBDataModelUnarchivedNotification;
// FA position table view
extern NSString *CBDataModelFaPositionValuesChangedNotification;
// FA reserve bid index
extern NSString *CBDataModelFaReserveBidIndexChangedNotification;
// FA MRT bid index
extern NSString *CBDataModelFaMrtBidIndexChangedNotification;
#pragma mark SORT SELECTION KEYS
extern NSString * CBDataModelSortSelectionTitleKey;
extern NSString * CBDataModelSortSelectionFunctionKey;
#pragma mark POINTS VALUE KEYS
extern NSString * CBDataModelPointsItemKey;
extern NSString * CBDataModelPointsValueKey;
#pragma mark OVERLAP
extern NSString * CBOverlapEntryBlockTimeKey;
extern NSString * CBOverlapEntryReleaseTimeKey;
extern NSString * CBOverlapEntryDateKey;
extern int CBOverlapNextDayHour;
#pragma mark PREFERENCES KEYS
// keys for preferences that determine whether trips are AM or PM
// required for FA trips only, since pilot bid data contains AM/PM information
// and FA bid data does not
// keys are defined in CBMainPreferencesWindowController.h
extern NSString *CBAmDepartTimePreferencesKey;
extern NSString *CBAmArrivalTimePreferencesKey;
// notification that am time preferences changed
// defined in CBMainPreferencesWindowController.h
extern NSString *CBAmTimePreferencesChangedNotification;

