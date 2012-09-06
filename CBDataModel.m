//
//  CBDataModel.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 03 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDataModel.h"
#import "CBDocument.h"
#import "CSBidPeriod.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"
#import "CSCrewPositions.h"
#import "NSMutableArray+MAArrayUtilities.h"

#pragma mark NOTIFICATION NAMES
NSString * CBDataModelLinesChangedNotification = @"CBDataModel Lines Changed Notification";
NSString * CBDataModelLinesMovedNotification = @"CBDataModel Lines Moved Notification";
NSString * CBDataModelSortSelectionsChangedNotification = @"CBDataModel Sort Selection Changed Notification";
NSString * CBDataModelUnarchivedNotification = @"CBDataModel Unarchived Notification";
NSString * CBDataModelFaPositionValuesChangedNotification = @"CBDataModel FA Position Changed Notification";
NSString *CBDataModelFaReserveBidIndexChangedNotification = @"Data Model FA Reserve Bid Index Changed Notification";
NSString *CBDataModelFaMrtBidIndexChangedNotification = @"Data Model FA MRT Bid Index Changed Notification";
#pragma mark SORT SELECTION KEYS
NSString * CBDataModelSortSelectionTitleKey = @"CBDataModel Sort Selection Title Key";
NSString * CBDataModelSortSelectionFunctionKey = @"CBDataModel Sort Selection Function Key";
#pragma mark POINTS VALUE KEYS
NSString * CBDataModelPointsItemKey = @"CBDataModel Points Item Key";
NSString * CBDataModelPointsValueKey = @"CBDataModel Points Value Key";

@implementation CBDataModel

#pragma mark INITIALIZATION

+ (void)initialize {

   static BOOL initialized = NO;
   if (!initialized && (self == [CBDataModel class])) {
      // version 1 added overlapFormValues variable
      //
      // version 2 added noOverlapSelectCheckboxValue,
      // noOverlapPointsCheckboxValue, noOverlapPointsValue,
      // overlapPointsCheckboxValue, and overlapPointsValue
      // variables
      //
      // version 3 added block of days off variables
      //
      // version 4 added FA positions for sorting
      //
      // version 5 added FA reserve bid index, FA MRT bid index, and bid round
      //
      // version 6 added deadheads and commuting
	  //
      // version 7 added max legs per day
	   // 
	   // version 8 added FA 'D' position
      [self setVersion:8];
      initialized = YES;
   }
}

- (id)initWithDocument:(CBDocument *)inDocument
{
   if (self = [super init]) {
      document = inDocument;
      // disable undo registration
      [[self undoManager] disableUndoRegistration];
      // disable sorting
      [self setSortingEnabled:NO];
      // sort selections
      // available sort selections is set in
      [self setAvailableSortSelections:[self sortSelectionsArray]];
      [self setInUseSortSelections:[NSMutableArray array]];
      // FA positions
      [self setFaPositions:[self initialFaPositionsArray]];
      // set default values
         // any required??
            // top and bottom freeze indexes are set in AppController 
            // openDocumentWithDataFile: method
      // commuting
      [self setConsiderAdjacentTripsNotCommutable:YES];
      // days of month
      [self setDaysOfMonthSelectValues:[NSSet set]];
      [self setDaysOfMonthPointsValues:[NSDictionary dictionary]];
      [self setDaysOfWeekSelectValues:[NSSet set]];
      [self setDaysOfWeekPointsValues:[NSDictionary dictionary]];
      // overnightCities
      [self setOvernightCitiesSelectValues:[NSSet set]];
      [self setOvernightCitiesPointsValues:[NSDictionary dictionary]];
      // enable undo registration
      [[self undoManager] enableUndoRegistration];
      // enable sorting
      [self setSortingEnabled:YES];
      // register for notifications that am time preferences have changed
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAmOrPm:) name:CBAmTimePreferencesChangedNotification object:nil];   
   }
   return self;
}

- (void)initializeAfterUnarchivingWithDocument:(CBDocument *)inDocument
{
   document = inDocument;
   // limit undo to two items
//   [[self undoManager] setLevelsOfUndo:2];
   // set FA reserve and MRT bid lines
   if ([self isFlightAttendantBid]) {
      [self updateAmOrPm:nil];
   }
   // register for notifications that am time preferences have changed
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAmOrPm:) name:CBAmTimePreferencesChangedNotification object:nil];   
   [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelUnarchivedNotification 
      object:[self document] userInfo:nil];
   
   // TEMP CODE
   [[self document] updateChangeCount:NSChangeCleared];
   
    // Prevent case where old version of bid file (prior to data model
    // version 4, where bid round is not saved) is opened with this version,
    // which will result in a bid round of 0
    if ([self bidRound] == 0)
    {
        NSString *docFileNamePath = [[[self document] fileURL] path];
        NSString *docFileName = [[docFileNamePath lastPathComponent] stringByDeletingPathExtension];
        unsigned docFileNameLen = [docFileName length];
        NSString *docFileBidRound = [docFileName substringFromIndex:docFileNameLen - 1];
        int docBidRound = [docFileBidRound intValue];
        [self setBidRound:docBidRound];
    }
}

- (void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [month release];
   [crewBase release];
   [crewPosition release];
   [self setBidPeriod:nil];
   [lines release];
   [trips release];
   [firstBidDate release];
   [firstCalendarDate release];
   [lastBidDate release];
   [inUseSortSelections release];
   [availableSortSelections release];
   [faReserveBidLine release];
   [faMrtBidLine release];
   [daysOfMonthSelectValues release];
   [daysOfMonthPointsValues release];
   [daysOfWeekSelectValues release];
   [daysOfWeekPointsValues release];
   [overnightCitiesSelectValues release];
   [overnightCitiesPointsValues release];
   [overlapFormValues release];
   // deadheads
   [deadheadAtStartCities release];
   [deadheadAtStartCity release];
   [deadheadAtEndCities release];
   [deadheadAtEndCity release];
   // commuting
   [self setCommuteWeekdayStartValue:nil];
   [self setCommuteFridayStartValue:nil];
   [self setCommuteSaturdayStartValue:nil];
   [self setCommuteSundayStartValue:nil];
   [self setCommuteWeekdayEndValue:nil];
   [self setCommuteFridayEndValue:nil];
   [self setCommuteSaturdayEndValue:nil];
   [self setCommuteSundayEndValue:nil];
   // vacation
   [self setVacationWeeks:nil];
   [self setSelectedVacationWeekIndexes:nil];
   [super dealloc];
}

#pragma mark DERIVED VALUES

- (NSArray *)sortSelectionsArray
{
   NSArray *sortSelectionsArray = [NSArray arrayWithObjects:
      @"AM Then PM",
      @"PM Then AM",
      @"Aircraft Changes",
      @"Block Time",
      @"Block Of Days Off",
      @"Commutes Required",
      @"Days Off",
      @"Legs",
      @"Line Number",
      @"Overnights in Domicile",
      @"Passes Through Domicile",
      @"Pay",
      @"Pay Per Block Time",
      @"Pay Per Day",
      @"Pay Per Duty Time",
      @"Pay Per Leg",
//      @"Pay With Vacation",
      @"Points",
      @"Trips",
//      @"Vacation Drop",
//      @"Vacation Days Off",
//      @"Vacation Pay",
      @"Work Days",
      @"Max Legs Per Day",
      nil];
   return sortSelectionsArray;
}

- (void)addNewSortSelections
{
    // at this point, the available and in use sort selections have been
    // unarchived so we want to add any sort selections that have been
    // added to the application since the data model was archived
	
	// first get all sort selections for archived version
	NSMutableSet *oldSortSelections = [NSMutableSet setWithArray:[self availableSortSelections]];
	[oldSortSelections addObjectsFromArray:[self inUseSortSelections]];
    
    // now we get all the sorts selections for the current version of the
    // application
//	NSSet *currentSortSelections = [NSSet setWithArray:[self sortSelectionsArray]];
	// add current sort selections to archived sort selections
	[oldSortSelections addObjectsFromArray:[self sortSelectionsArray]];
	// remove in use sort selections
	[oldSortSelections minusSet:[NSSet setWithArray:[self inUseSortSelections]]];
//    NSMutableArray *currentSortSelections = [NSMutableArray arrayWithArray:[self sortSelectionsArray]];
//    NSMutableArray *currentSortSelections = [NSMutableArray arrayWithArray:[self availableSortSelections]];
    // now remove the in use sort selections
//    [currentSortSelections removeObjectsInArray:[self inUseSortSelections]];
    // save the new available sort selections
    [self setAvailableSortSelections:[oldSortSelections allObjects]];
}

- (NSArray *)initialFaPositionsArray
{
   return [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", nil];
}

- (void)initializeDerivedValues
{
   [self addNewSortSelections];
   NSMutableArray *available = [NSMutableArray arrayWithArray:[self availableSortSelections]];
   // this can't be done in initWithDocument: method because crewPosition
   // data member has not been set, and isFlightAttendantBid method needs
   // the crewPosition data member to determine if it is a flight attendant
   // bid
	// If this is a flight attendant bid.
   if ([self isFlightAttendantBid])
   {
	   // Add sorting by flight attendant position if they are not already 
	   // in the available sort positions.
      NSArray *faPositionsArray = [NSArray arrayWithObjects:
         @"Position A",
         @"Position B",
         @"Position C",
		 @"Position D",
         nil];
      id commonObj = [available firstObjectCommonWithArray:faPositionsArray];
      if (!commonObj)
      {
         [available addObjectsFromArray:faPositionsArray];
      }
	   
	   // Add position D if it is not in faPositions array.
	   if (3 == [[self faPositions] count]) {
		   NSMutableArray *positions = [NSMutableArray arrayWithArray:[self faPositions]];
		   [positions addObject:@"D"];
		   [self setFaPositions:positions];
	   }
	   
	   // Remove aircraft changes.
      [available removeObject:@"Aircraft Changes"];
   }
   // remove inappropriate sort selections for pilot second round bids
   if ([[[self bidPeriod] round] intValue] == 2 && ![[[self bidPeriod] position] isEqualToString:CSFlightAttendant])
   {
      [available removeObject:@"Aircraft Changes"];
//      [available removeObject:@"Block Time"];
      [available removeObject:@"Legs"];
      [available removeObject:@"Passes Through Domicile"];
//      [available removeObject:@"Pay Per Block Time"];
      [available removeObject:@"Pay Per Duty Time"];
      [available removeObject:@"Pay Per Leg"];
      [available removeObject:@"Max Legs Per Day"];
   }
  [self setAvailableSortSelections:[NSArray arrayWithArray:available]];
   // overlap - this can't be done in initWithDocument: method because month
   // data member has not been set, and initialReleaseTime method needs
   // month data member to determine initial release time
   if (!overlapFormValues) {
      [self setOverlapFormValues:[self zeroOverlapValues]];
   }
   // offset from line trip date to line calender entry
	int lineCalendarOffset = [self calendarOffset];
   // overnight cities
   NSMutableSet * allOvernightCities = [NSMutableSet set];
   // deadheads
   NSMutableSet *allDeadheadAtStartCities = [NSMutableSet set];
   NSMutableSet *allDeadheadAtEndCities = [NSMutableSet set];
   // read lines
   NSDictionary * tripsDictionary = [self trips];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   // set derived values for each line
   while (line = [linesEnumerator nextObject]) {
      // line number string
	  NSString *lineNumString = nil;
      // line calendar entries
      NSMutableArray * lineCalendarEntries = [self emptyCalendarEntries];
      // line calendar objects
      NSMutableArray * lineCalendarObjects = [self emptyCalendarObjects];
      // line calendar tags
      NSMutableArray * lineCalendarTags = [self emptyCalendarTags];
      // line calendar print entries
      NSMutableArray * linePrintCalendarEntries = [self emptyCalendarEntries];
      // AM/PM
      BOOL lineIsAM = NO;
      BOOL lineIsPM = NO;
      // t234
      int lineNumberOfTurns = 0;
      int lineNumberOf2Days = 0;
      int lineNumberOf3Days = 0;
      int lineNumberOf4Days = 0;
      // block of days off
      NSInteger blockOfDaysOff = 0;
      int lineLongestBlockOfDaysOff = 0;
      NSCalendarDate * tripStartDate = nil;
      NSCalendarDate *endDatePreviousTrip = [[self month] dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
      // 3-on/3-off
      BOOL lineIs3on3off = YES;
      // weekends
      int lineWeekends = 0;
      // overnight cities
      NSCountedSet * lineOvernightCities = [NSCountedSet set];
      // work dates
      NSMutableSet * lineWorkDates = [NSMutableSet set];
      NSMutableSet * lineWorkDatesNextMonth = [NSMutableSet set];
      // TAFB
      int lineTafb = 0;
      // credit next month
      float lineCreditNextMonth = 0.0;
      // block time next month
      int lineBlockNextMonthMinutes = 0;
      // duty time
      int lineDuty = 0;
      int lineDutyNextMonth = 0;
      int lineMaxDutyDay = 0;
      // legs
      int lineLegs = 0;
      int lineLegsNextMonth = 0;
      int lineMaxLegs = 0;
      // aircraft changes
      int lineAircraftChanges = 0;
      int lineAircraftChangesNextMonth = 0;
      // passes through domicile
      int linePassesThroughDomicile = 0;
      // earliest start and latest arrival
      int lineEarliestStart = 2400;
      int lineLatestArrival = 0;
      // deadheads
      NSCountedSet *lineDeadheadAtStartCities = [NSCountedSet set];
      NSCountedSet *lineDeadheadAtEndCities = [NSCountedSet set];
	  // For second round bids
	  // Line has reserve trip and line has non-reserve trip are used for
	  // line number string for pilot second round bids. If the line has both
	  // reserve and non-reserve trips, then line number will have 'M' suffix
	  BOOL lineHasReserveTrip = NO;
	  BOOL lineHasNonReserveTrip = NO;
      
      // TRIPS
      
      NSEnumerator * lineTripsEnumerator = [[line trips] objectEnumerator];
      NSDictionary * lineTrip = nil;
      while (lineTrip = [lineTripsEnumerator nextObject]) {
         CBTrip * trip = [tripsDictionary objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
         // if trip is not in trips dictionary then it's a flight attendant
         // second round reserve trip
         if (!trip) {
			 // Check to make sure this is FA second round bid.
			 if ([[self bidPeriod] isFlightAttendantBid] && [[self bidPeriod] isSecondRoundBid]) {
				 trip = [[[CBTrip alloc] 
						  initWithNumber:[lineTrip objectForKey:CBLineTripNumberKey] 
						  departureStation:[self crewBase] 
						  departureTime:[[lineTrip objectForKey:CBLineTripReserveStartTimeKey] intValue] 
						  returnTime:[[lineTrip objectForKey:CBLineTripReserveEndTimeKey] intValue] 
						  isAMTrip: NSNotFound != [[lineTrip objectForKey:CBLineTripNumberKey] rangeOfString:@"FAR"].location 
						  totalBlock:0 
						  dutyPeriods:1] autorelease];
				 CBTripDay *resvTripDay = [[[CBTripDay alloc] initWithCredit:6.0 legs:[NSArray array]] autorelease];
				 [resvTripDay setIsFirstDay:YES];
				 [trip setDays:[NSArray arrayWithObject:resvTripDay]];
			 }
			 // Shouldn't get here...
			 // Not a FA second round bid. There's an error in reading bid data.
			 // There is a line trip for which there is no trip in the trips 
			 // dictionary...
			 else {
				 continue;
			 }
         }

         // line print calendar entries
         NSString * tripNumberString = [NSString stringWithFormat:@"Trip %@", [trip number]];
         // AM/PM
		 if ([trip isAMTrip]) {
			lineIsAM = YES;
		 } else {
			lineIsPM = YES;
		 }
         // t234 - increment lines number of days for each
         int tripLength = [trip dutyPeriods];
         switch (tripLength) {
            case 1:
               lineNumberOfTurns++;
               break;
            case 2:
               lineNumberOf2Days++;
               break;
            case 3:
               lineNumberOf3Days++;
               break;
            case 4:
               lineNumberOf4Days++;
               break;
            default:
               break;
         }
		 // Line has reserve/non-reserve trip
		 if ([trip isReserve]) {
		    lineHasReserveTrip = YES;
		 } else {
		    lineHasNonReserveTrip = YES;
		 }
         // TAFB
         lineTafb += [trip tafb];
         // earliest departure and latest arrival
         if ([trip departureTime] < lineEarliestStart) {
            lineEarliestStart = [trip departureTime];
         }
         if ([trip returnTime] > lineLatestArrival) {
            lineLatestArrival = [trip returnTime];
         }
         // deadhead cities
         if ([[trip firstLeg] isDeadhead]) {
            [allDeadheadAtStartCities addObject:[[trip firstLeg] arrivalCity]];
            [lineDeadheadAtStartCities addObject:[[trip firstLeg] arrivalCity]];
         }
         if ([[trip lastLeg] isDeadhead]) {
            [allDeadheadAtEndCities addObject:[[trip lastLeg] departureCity]];
            [lineDeadheadAtEndCities addObject:[[trip lastLeg] departureCity]];
         }
         
         // DAYS
         
         int tripDate = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
		 int day = tripDate;
         tripStartDate = [[self month] dateByAddingYears:0 months:0 days:(tripDate - 1) hours:0 minutes:0 seconds:0];
         
         // block of days off
         [tripStartDate years:NULL months:NULL days:&blockOfDaysOff hours:NULL minutes:NULL seconds:NULL sinceDate:endDatePreviousTrip];
         blockOfDaysOff--;
         if (blockOfDaysOff > lineLongestBlockOfDaysOff)
         {
            lineLongestBlockOfDaysOff = blockOfDaysOff;
         }
         
         // 3-on/3-off
         if ((blockOfDaysOff > 3 && [[self month] monthOfYear] == [endDatePreviousTrip monthOfYear]) || 
             [[trip days] count] != 3) {
            lineIs3on3off = NO;
         }

         NSCalendarDate * date = [[tripStartDate copy] autorelease];
         int thisMonth = [tripStartDate monthOfYear];
         NSEnumerator * tripDaysEnumerator = [[trip days] objectEnumerator];
         CBTripDay * tripDay = nil;
         while (tripDay = [tripDaysEnumerator nextObject]) {
            // used in line calendar entries, objects, tags, and print entries
            int lineCalendarIndex = day + lineCalendarOffset;
            // line calendar entries, objects, and tags
            NSString * lineCalendarEntry = [tripDay shortCalendarText];
            // if line calendar entry is nil, then trip is a flight attendant
            // second round reserve trip
            if (!lineCalendarEntry) {
               lineCalendarEntry = [NSString stringWithFormat:@"%04d\n%@\n%04d", [trip departureTime], [[trip number] substringToIndex:3], [trip returnTime]];
            }
            [lineCalendarEntries replaceObjectAtIndex:lineCalendarIndex withObject:lineCalendarEntry];
            NSDictionary * representedObject = [NSDictionary dictionaryWithObjectsAndKeys:
               trip, CBLineTripNumberKey, 
               tripStartDate, CBLineTripDateKey, 
               [lineTrip objectForKey:CBLineTripPositionKey], CBLineTripPositionKey, nil];
            [lineCalendarObjects replaceObjectAtIndex:lineCalendarIndex withObject:representedObject];
            [lineCalendarTags replaceObjectAtIndex:lineCalendarIndex withObject:[NSNumber numberWithInt:[tripStartDate dayOfYear]]];
            // line calendar print entries
            NSString * linePrintCalendarEntry = nil;
            if ([tripDay isFirstDay]) {
               NSString *tripDayPrintCalText = [tripDay printCalendarText];
               // if tripDayPrintCalText is nil, then trip is a flight attendant
               // second round reserve trip
               if (!tripDayPrintCalText) {
                  tripDayPrintCalText = [NSString stringWithFormat:@"%@ %04d\n%@ %04d", [trip departureStation], [trip departureTime], [trip departureStation], [trip returnTime]];
               }
               linePrintCalendarEntry = [NSString stringWithFormat:@"%@\n%@", tripNumberString, tripDayPrintCalText];
            } else {
               linePrintCalendarEntry = [NSString stringWithFormat:@"\n%@", [tripDay printCalendarText]];
            }
            [linePrintCalendarEntries replaceObjectAtIndex:lineCalendarIndex withObject:linePrintCalendarEntry];
            // weekdays and weekends
            int dayOfWeek = [date dayOfWeek];
            if (dayOfWeek == 0 || dayOfWeek == 6) {
               lineWeekends++;
            }
            // max duty day
            int tripDayDuty = ([tripDay releaseTime] - [tripDay reportTime]);
            if (tripDayDuty > lineMaxDutyDay) {
               lineMaxDutyDay = tripDayDuty;
            }
            // overnight cities
            NSString * overnight = [[[tripDay legs] lastObject] arrivalCity];
            if (overnight && ![overnight isEqualToString:[self crewBase]]) {
               [lineOvernightCities addObject:overnight];
               [allOvernightCities addObject:overnight];
            }
            // this month
            if (thisMonth == [date monthOfYear]) {
               // work dates
               [lineWorkDates addObject:date];
               // line duty
               lineDuty += tripDayDuty;
            // next month
            } else {
               // credit next month
               lineCreditNextMonth += [tripDay credit];
               // block time next month
               lineBlockNextMonthMinutes += [tripDay block];
               // work dates next month
               [lineWorkDatesNextMonth addObject:date];
               // line duty next month
               lineDutyNextMonth += tripDayDuty;
            }
            
            // LEGS
            
            int tripDayLegs = 0;
            // aircraft changes
            int tripDayAircraftChanges = 0;
            NSEnumerator * tripDayLegsEnumerator = [[tripDay legs] objectEnumerator];
            CBTripDayLeg * tripDayLeg = nil;
            while (tripDayLeg = [tripDayLegsEnumerator nextObject]) {
               // legs
               tripDayLegs++;
               // aircraft changes
               if ([tripDayLeg isAircraftChange]) {
                  tripDayAircraftChanges++;
               }
               // passes through domicile
               if ([tripDayLeg groundTime] > 0 && [[tripDayLeg arrivalCity] isEqualToString:[self crewBase]]) {
                  linePassesThroughDomicile++;
               }
            }//LEGS
            
            // this month
            if (thisMonth == [date monthOfYear]) {
               // number of legs
               lineLegs += tripDayLegs;
               // number of aircraft changes
               lineAircraftChanges += tripDayAircraftChanges;
            // next month
            } else {
               // number of legs next month
               lineLegsNextMonth += tripDayLegs;
               // number of aircraft changes next month
               lineAircraftChangesNextMonth += tripDayAircraftChanges;
            }
            // max legs
            if (lineMaxLegs < tripDayLegs) {
               lineMaxLegs = tripDayLegs;
            }
            // update variables for next day
            day++;
            endDatePreviousTrip = date;
            date = [date dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
         }// DAYS
      }// TRIPS
      
      // block of days off - check for block of days off at end of month
      tripStartDate = [[self month] dateByAddingYears:0 months:1 days:0 hours:0 minutes:0 seconds:0];
      [tripStartDate years:NULL months:NULL days:&blockOfDaysOff hours:NULL minutes:NULL seconds:NULL sinceDate:endDatePreviousTrip];
      blockOfDaysOff--;
      if (blockOfDaysOff > lineLongestBlockOfDaysOff)
      {
         lineLongestBlockOfDaysOff = blockOfDaysOff;
      }

      // some attributes make sense only for lines that are not blank or reserve
      BOOL lineNotReserveOrBlank = (![line isReserveLine] && ![line isBlankLine]);
	  // line number string
	  if ([line isReserveLine]) {
		  lineNumString = [NSString stringWithFormat:@"%dR", [line number]];
	  } else if ([line isBlankLine]) {
		  lineNumString = [NSString stringWithFormat:@"%dB", [line number]];
	  } else if ([self isPilotSecondRoundBid]) {
	     // line has only reserve trips
	     if (lineHasReserveTrip && !lineHasNonReserveTrip) {
		    lineNumString = [NSString stringWithFormat:@"%dR", [line number]];
		 // line has both reserve and non-reserveTrips
		 } else if (lineHasReserveTrip && lineHasNonReserveTrip) {
		    lineNumString = [NSString stringWithFormat:@"%dM", [line number]];
		 } else {
		    lineNumString = [NSString stringWithFormat:@"%d", [line number]];
		 }
	  } else {
		  lineNumString = [NSString stringWithFormat:@"%d", [line number]];
	  }
	  [line setNumberString:lineNumString];
      // calendar entries
      [line setLineCalendarEntries:lineCalendarEntries];
      [line setLineCalendarObjects:lineCalendarObjects];
      [line setLineCalendarTags:lineCalendarTags];
      [line setPrintCalendarEntries:linePrintCalendarEntries];
      // AM/PM
      [line setIsAM:lineIsAM];
      [line setIsPM:lineIsPM];
      // t234
      NSString * lineT234 = (lineNumberOfTurns < 10 ? 
         [NSString stringWithFormat:@"%d%d%d%d", lineNumberOfTurns, lineNumberOf2Days, lineNumberOf3Days, lineNumberOf4Days] :
         [NSString stringWithFormat:@"*%d%d%d", lineNumberOf2Days, lineNumberOf3Days, lineNumberOf4Days]);
      [line setT234:lineT234];
      [line setTurns:lineNumberOfTurns];
      [line setTwoDays:lineNumberOf2Days];
      [line setThreeDays:lineNumberOf3Days];
      [line setFourDays:lineNumberOf4Days];
      // block of days off
      [line setLongestDaysOffBlock:([line isBlankLine] ? 0 : lineLongestBlockOfDaysOff)];
      // 3-on/3-off
      [line setIs3on3off:lineIs3on3off];
      // weekdays and weekends
      [line setWeekends:lineWeekends];
      // credit next month
      [line setCreditNextMonth:lineCreditNextMonth];
      // block time next month
      [line setBlockNextMonth:(lineNotReserveOrBlank ? [self lineBlockWithMinutes:lineBlockNextMonthMinutes] : 0.0)];
      // duty
      [line setDuty:(lineNotReserveOrBlank ? lineDuty : 0.0)];
      // duty next month
      [line setDutyNextMonth:(lineNotReserveOrBlank ? lineDutyNextMonth : 0.0)];
      // max duty
      [line setMaxDutyDay:(lineNotReserveOrBlank ? lineMaxDutyDay : 0)];
      // overnight cities
      [line setOvernightCities:[NSCountedSet setWithSet:lineOvernightCities]];
      // work dates
      [line setWorkDates:[NSSet setWithSet:lineWorkDates]];
      [line setWorkDatesNextMonth:[NSSet setWithSet:lineWorkDatesNextMonth]];
      // number of work days
      int lineWorkDays = [lineWorkDates count] + [lineWorkDatesNextMonth count];
      [line setWorkDays:lineWorkDays];
      // days off
      int lineDaysOff = [self daysInMonth] - [lineWorkDates count];
      [line setDaysOff:(![line isBlankLine] ? lineDaysOff : 0)];
      // TAFB
      [line setTafb:(lineNotReserveOrBlank ? lineTafb : 0.0)];
      // line legs
      [line setLegs:(lineNotReserveOrBlank ? lineLegs : 0)];
      // max legs
      [line setMaxLegs:(lineNotReserveOrBlank ? lineMaxLegs : 0)];
      // aircraft changes
      [line setAircraftChanges:lineAircraftChanges];
      // passes through domicile
      [line setPassesThroughDomicile:(lineNotReserveOrBlank ? linePassesThroughDomicile : 0)];
      // earliest start and latest arrival
      [line setEarliestStart:(lineNotReserveOrBlank ? lineEarliestStart : 0)];
      [line setLatestArrival:(lineNotReserveOrBlank ? lineLatestArrival : 0)];
      // deadheads
      [line setDeadheadAtStartCities:lineDeadheadAtStartCities];
      [line setDeadheadAtEndCities:lineDeadheadAtEndCities];
   }
   // data model overnight cities
   [self setOvernightCities:[[allOvernightCities allObjects] sortedArrayUsingSelector:@selector(compare:)]];
   // data model deadhead cities
   if ([allDeadheadAtStartCities count] == 0)
   {
      [allDeadheadAtStartCities addObject:@"None"];
      [self setDeadheadAtStartCity:@"None"];
   }
   else if ([self deadheadAtEndCity] == nil)
   {
      [self setDeadheadAtStartCity:[[[allDeadheadAtStartCities allObjects] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0]];
   }
   if ([allDeadheadAtEndCities count] == 0)
   {
      [allDeadheadAtEndCities addObject:@"None"];
      [self setDeadheadAtEndCity:@"None"];
   }
   else if ([self deadheadAtEndCity] == nil)
   {
      [self setDeadheadAtEndCity:[[[allDeadheadAtEndCities allObjects] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0]];
   }
   [self setDeadheadAtStartCities:[[allDeadheadAtStartCities allObjects] sortedArrayUsingSelector:@selector(compare:)]];
   [self setDeadheadAtEndCities:[[allDeadheadAtEndCities allObjects] sortedArrayUsingSelector:@selector(compare:)]];
   // commuting
   [self initializeCommutingTabDataModel];
   // vacation
   [self initializeVacationTabDataModel];
}

- (NSMutableArray *)emptyCalendarEntries
{
   const unsigned NUM_CALENDAR_ENTRIES = 42;
   NSMutableArray * calendarEntries = [NSMutableArray arrayWithCapacity:NUM_CALENDAR_ENTRIES];
   unsigned index = 0;
   for (index = 0; index < NUM_CALENDAR_ENTRIES; index++) {
      [calendarEntries addObject:@""];
   }
   return calendarEntries;
}

- (NSMutableArray *)emptyCalendarObjects
{
   const unsigned NUM_CALENDAR_ENTRIES = 42;
   NSMutableArray * calendarObjects = [NSMutableArray arrayWithCapacity:NUM_CALENDAR_ENTRIES];
   unsigned index = 0;
   for (index = 0; index < NUM_CALENDAR_ENTRIES; index++) {
      [calendarObjects addObject:[NSNull null]];
   }
   return calendarObjects;
}

- (NSMutableArray *)emptyCalendarTags
{
   const unsigned NUM_CALENDAR_ENTRIES = 42;
   NSMutableArray * calendarTags = [NSMutableArray arrayWithCapacity:NUM_CALENDAR_ENTRIES];
   unsigned index = 0;
   for (index = 0; index < NUM_CALENDAR_ENTRIES; index++) {
      [calendarTags addObject:[NSNumber numberWithInt:0]];
   }
   return calendarTags;
}

- (void)updateAmOrPm:(NSNotification *)notification
{
   if ([self isFlightAttendantBid])
   {
      [self updateTripsIsAm];
      [self updateLinesIsAmOrPm];
      [self sortLines];
   }
}

- (void)updateTripsIsAm
{
   // get preferences values from user defaults
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   int prefsAmDepartTime = [[defaults objectForKey:CBAmDepartTimePreferencesKey] intValue];
   int prefsAmArrivalTime = [[defaults objectForKey:CBAmArrivalTimePreferencesKey] intValue];
   
   CBTrip * trip = nil;
   NSEnumerator *e = [[self trips] objectEnumerator];

   while (trip = [e nextObject])
   {
      [trip setIsAmWithDefaultAmDepartTime:prefsAmDepartTime arrivalTime:prefsAmArrivalTime];
   }
}

- (void)updateLinesIsAmOrPm
{
   CBLine *line = nil;
   NSEnumerator *le = [[self lines] objectEnumerator];
   NSDictionary *ltDict = nil;
   NSEnumerator *te = nil;
   NSString *tn = nil;
   CBTrip *trip = nil;

   while (line = [le nextObject])
   {
      [line setIsAM:NO];
      [line setIsPM:NO];
      te = [[line trips] objectEnumerator];
      while (ltDict = [te nextObject])
      {
         tn = [ltDict objectForKey:CBLineTripNumberKey];
         trip = [[self trips] objectForKey:tn];
         // flight attendant reserve am trip
         if (NSNotFound != [tn rangeOfString:@"FAR"].location)
         {
            [line setIsAM:YES];
            break;
         }
         // flight attendant reserve pm trip
         else if (NSNotFound != [tn rangeOfString:@"FPR"].location)
         {
            [line setIsPM:YES];
            break;
         }
         // flight attendant ready reserve trip
         else if (NSNotFound != [tn rangeOfString:@"FRR"].location)
         {
            [line setIsAM:YES];
            [line setIsPM:YES];
            break;
         }
         else if ([trip isAMTrip])
         {
            [line setIsAM:YES];
         }
         else
         {
            [line setIsPM:YES];
         }
      }
   }
}

- (int)daysInMonth
{
   NSCalendarDate * lastDateOfMonth = [[self month] dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0];
   return [lastDateOfMonth dayOfMonth];
}

- (float)lineBlockWithMinutes:(int)blockMinutes
{
   int blockNextMonthHours = blockMinutes / 60;
   int blockNextMonthMinutes = (blockMinutes % 60);
   float blockNextMonthDecimalPart = 0.0;
   if (blockNextMonthMinutes > 0) {
      blockNextMonthDecimalPart = (float)blockNextMonthMinutes / 60.0;
   }
   float lineBlockNextMonth = ((float)blockNextMonthHours + blockNextMonthDecimalPart);
   return lineBlockNextMonth;
}

#pragma mark SORTING

- (void)sortLines
{
   // top and bottom freeze indexes to restore correct indexes after removing
   // and inserting reserve and MRT bids
   int topFreezeAtStart = [self topFreezeIndex];
   int botFreezeAtStart = [self bottomFreezeIndex];
   // remove reserve and MRT bids, to be reinserted after sorting
   NSUInteger resvBidIdx = NSNotFound;
   NSUInteger mrtBidIdx = NSNotFound;
   if ([self isFlightAttendantFirstRoundBid]) {
      // reserve bid
      if ([self hasFaReserveBid]) {
         resvBidIdx = [self removeFaReserveBid];
      }
      // MRT bid
      if ([self hasFaMrtBid]) {
         mrtBidIdx = [self removeFaMrtBid];
      }
   }
   // adjust MRT bid index if reserve bid was removed above
   if (mrtBidIdx != NSNotFound && mrtBidIdx > resvBidIdx) {
      mrtBidIdx++;
   }
   
   // create array of sort functions which will be included in context for
   // compareLines function
   NSMutableArray * sortSelections = [NSMutableArray arrayWithCapacity:[[self inUseSortSelections] count]];
   if ([self blankLinesToBottomCheckboxValue]) {
      [sortSelections addObject:[NSValue valueWithPointer:compareLinesByBlankLinesToBottom]];
   }
   if ([self reserveLinesToBottomCheckboxValue]) {
      [sortSelections addObject:[NSValue valueWithPointer:compareLinesByReserveLinesToBottom]];
   }
   if ([self threeOnThreeOffToBottomCheckboxValue]) {
      [sortSelections addObject:[NSValue valueWithPointer:compareLinesByThreeOnThreeOffToBottom]];
   }
   [sortSelections addObject:[NSValue valueWithPointer:compareLinesBySelected]];

   NSEnumerator * sortSelectionsEnumerator = [[self inUseSortSelections] objectEnumerator];
   NSString * sortSelection = nil;
   while (sortSelection = [sortSelectionsEnumerator nextObject]) {
      [sortSelections addObject:[self sortFunctionValueWithSortSelection:sortSelection]];
   }
   // sort by line number if not already included
   NSValue * compareByNumber = [NSValue valueWithPointer:compareLinesByNumber];
   if (![sortSelections containsObject:compareByNumber]) {
      [sortSelections addObject:compareByNumber];
   }
   // array of FA positions which will be included in context for compareLines
   // function
   NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys:
      sortSelections, CBLineComparisonSortSelectionsKey,
      [self faPositions], CBLineComparisonFaPositionsKey,
      nil];
   // sort array between top and bottom freeze indices
   NSArray * topFrozenLines = nil;
   NSArray * bottomFrozenLines = nil;
   unsigned topFrozenLinesCount = 0;
   unsigned bottomFrozenLinesCount = 0;
   unsigned linesCount = [[self lines] count];
   
   if ([self topFreezeIndex] > -1) {
      topFrozenLinesCount = [self topFreezeIndex] + 1;
      NSRange topFrozenLinesRange = NSMakeRange( 0, topFrozenLinesCount );
      topFrozenLines = [lines subarrayWithRange:topFrozenLinesRange];
   }
   else {
      topFrozenLines = [NSArray array];
   }
   if ([self bottomFreezeIndex] < linesCount) {
      bottomFrozenLinesCount = linesCount - [self bottomFreezeIndex];
      NSRange bottomFrozenLinesRange = NSMakeRange( [self bottomFreezeIndex], bottomFrozenLinesCount );
      bottomFrozenLines = [lines subarrayWithRange:bottomFrozenLinesRange];
   } else {
      bottomFrozenLines = [NSArray array];
   }
   unsigned linesToSortCount = linesCount - topFrozenLinesCount - bottomFrozenLinesCount;
   NSRange linesToSortRange = NSMakeRange( topFrozenLinesCount, linesToSortCount );
   NSArray * linesToSort = [lines subarrayWithRange:linesToSortRange];

   NSArray * sortedLines = [linesToSort sortedArrayUsingFunction:compareLines context:context];
   // reassemble lines
   sortedLines = [topFrozenLines arrayByAddingObjectsFromArray:sortedLines];
   sortedLines = [sortedLines arrayByAddingObjectsFromArray:bottomFrozenLines];
   // set lines to newly sorted lines
   [self setLines:sortedLines];
   
   // reinsert reserve and MRT bids
   if ([self isFlightAttendantFirstRoundBid]) {
      // insert reserve bid and MRT bids in order of their indexes
      if (resvBidIdx < mrtBidIdx) {
         // reserve bid
         if (resvBidIdx != NSNotFound) {
            [self insertFaReserveBidAtIndex:resvBidIdx];
         }
         // MRT bid
         if (mrtBidIdx != NSNotFound) {
            [self insertFaMrtBidAtIndex:mrtBidIdx];
         }
      } else {
         // MRT bid
         if (mrtBidIdx != NSNotFound) {
            [self insertFaMrtBidAtIndex:mrtBidIdx];
         }
         // reserve bid
         if (resvBidIdx != NSNotFound) {
            [self insertFaReserveBidAtIndex:resvBidIdx];
         }
      }
   }
   // restore top and bottom freeze indexes
   topFreezeIndex = topFreezeAtStart;
   bottomFreezeIndex = botFreezeAtStart;
}

- (NSValue *)sortFunctionValueWithSortSelection:(NSString *)sortSelection
{
   NSValue * sortFunctionValue = nil;
   
   if ([sortSelection isEqualToString:@"AM Then PM"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByAmThenPm];
   }
   else if ([sortSelection isEqualToString:@"PM Then AM"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPmThenAm];
   }
   else if ([sortSelection isEqualToString:@"Aircraft Changes"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByAircraftChanges];
   }
   else if ([sortSelection isEqualToString:@"Block Time"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByBlock];
   }
   else if ([sortSelection isEqualToString:@"Block Of Days Off"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByBlockOfDaysOff];
   }
   else if ([sortSelection isEqualToString:@"Commutes Required"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByCommutesRequired];
   }
   else if ([sortSelection isEqualToString:@"Days Off"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByDaysOff];
   }
   else if ([sortSelection isEqualToString:@"Legs"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByLegs];
   }
   else if ([sortSelection isEqualToString:@"Line Number"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByNumber];
   }
   else if ([sortSelection isEqualToString:@"Overnights in Domicile"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByOvernightsInDomicile];
   }
   else if ([sortSelection isEqualToString:@"Passes Through Domicile"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPassesThroughDomicile];
   }
   else if ([sortSelection isEqualToString:@"Pay"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPay];
   }
   else if ([sortSelection isEqualToString:@"Pay Per Block Time"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerBlock];
   }
   else if ([sortSelection isEqualToString:@"Pay Per Day"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerDay];
   }
   else if ([sortSelection isEqualToString:@"Pay Per Duty Time"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerDuty];
   }
   else if ([sortSelection isEqualToString:@"Pay Per Leg"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerLeg];
   }
   else if ([sortSelection isEqualToString:@"Points"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPoints];
   }
   else if ([sortSelection isEqualToString:@"Trips"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByTrips];
   }
   else if ([sortSelection isEqualToString:@"Work Days"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByWorkDays];
   }
   else if ([sortSelection isEqualToString:@"Max Legs Per Day"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByMaxLegsPerDay];
   }
   else if ([sortSelection isEqualToString:@"Position A"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByFAAPosition];
   }
   else if ([sortSelection isEqualToString:@"Position B"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByFABPosition];
   }
   else if ([sortSelection isEqualToString:@"Position C"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByFACPosition];
   }
   else if ([sortSelection isEqualToString:@"Position D"])
   {
	   sortFunctionValue = [NSValue valueWithPointer:compareLinesByFADPosition];
   }
   else if ([sortSelection isEqualToString:@"Vacation Drop"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByVacationDrop];
   }
   else if ([sortSelection isEqualToString:@"Vacation Days Off"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByVacationDaysOff];
   }
   else if ([sortSelection isEqualToString:@"Vacation Pay"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByVacationPay];
   }
   else if ([sortSelection isEqualToString:@"Pay With Vacation"])
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayWithVacation];
   }
   else
   {
      sortFunctionValue = [NSValue valueWithPointer:compareLinesByNumber];
   }
/*
   CBSortSelection sortSelection = [number intValue];

   switch (sortSelection) {
      case CBAmThenPmSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByAmThenPm];
         break;
      case CBPmThenAmSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPmThenAm];
         break;
      case CBAircraftChangesSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByAircraftChanges];
         break;
      case CBBlockSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByBlock];
         break;
      case CBBlockOfDaysOffSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByBlockOfDaysOff];
         break;
      case CBLegsSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByLegs];
         break;
      case CBNumberSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByNumber];
         break;
      case CBPassesThroughDomicileSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPassesThroughDomicile];
         break;
      case CBPaySort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPay];
         break;
      case CBPayPerBlockSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerBlock];
         break;
      case CBPayPerDaySort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerDay];
         break;
      case CBPayPerDutySort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerDuty];
         break;
      case CBPayPerLegSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPayPerLeg];
         break;
      case CBPointsSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByPoints];
         break;
      case CBTripsSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByTrips];
         break;
      case CBWorkDaysSort :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByWorkDays];
         break;
      default :
         sortFunctionValue = [NSValue valueWithPointer:compareLinesByNumber];
         break;
   }
*/
   return sortFunctionValue;
}

- (void)adjustPointsForLines
{
   // for adjusting points
   NSNumber * pointsNumber = nil;
   // days of month
   NSMutableSet * lineDaysOfMonthSet = [NSMutableSet set];
   NSDictionary * daysOffPoints = [self daysOfMonthPointsValues];
   NSSet * daysOff = [NSSet setWithArray:[daysOffPoints allKeys]];
   // overnight cities
   NSCountedSet * lineOvernightCitiesSet = nil;
   NSDictionary * cityPoints = [self overnightCitiesPointsValues];
   // enumerate lines
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      float addedPoints = 0.0;
      // aircraft changes
      if ([self aircraftChangesPointsCheckboxValue] == YES) {
         addedPoints += [line aircraftChanges] * [self aircraftChangesPointsValue];
      }
      // am/pm
      if ([self amPointsCheckboxValue] == YES && [line isAM]) {
         addedPoints += [self amPointsValue];
      }
      if ([self pmPointsCheckboxValue] == YES && [line isPM]) {
         addedPoints += [self pmPointsValue];
      }
      // trip length
      if ([self turnPointsCheckboxValue] == YES) {
         addedPoints += [line turns] * [self turnPointsValue];
      }
      if ([self twoDayPointsCheckboxValue] == YES) {
         addedPoints += [line twoDays] * [self twoDayPointsValue];
      }
      if ([self threeDayPointsCheckboxValue] == YES) {
         addedPoints += [line threeDays] * [self threeDayPointsValue];
      }
      if ([self fourDayPointsCheckboxValue] == YES) {
         addedPoints += [line fourDays] * [self fourDayPointsValue];
      }
      // block of days off
      if ([self blockOfDaysOffPointsCheckboxValue] && 
         ([line longestDaysOffBlock] >= [self blockOfDaysOffPointsTriggerValue])) {
         addedPoints += [self blockOfDaysOffPointsValue];
      }
      // commuting
      if ([self commuteAssignsPointsForCommutesRequired])
      {
         addedPoints += [line commutesRequiredCount] * [self commutePointsForCommutesRequired];
      }
      if ([self commuteAssignsPointsForOvernightsInDomicile])
      {
         addedPoints += [line overnightsInDomicileCount] * [self commutePointsForOvernightsInDomicile];
      }
      // days of month
      if ([self daysOfMonthPointsCheckboxValue]) {
         [lineDaysOfMonthSet setSet:[line workDates]];
         [lineDaysOfMonthSet unionSet:[line workDatesNextMonth]];
         [lineDaysOfMonthSet intersectSet:daysOff];
         NSEnumerator * datesEnumerator = [lineDaysOfMonthSet objectEnumerator];
         NSCalendarDate * pointsDate = nil;
         while (pointsDate = [datesEnumerator nextObject]) {
            pointsNumber = [daysOffPoints objectForKey:pointsDate];
            if (pointsNumber) {
               addedPoints += [pointsNumber floatValue];
            }
         }
      }
      // deadheads
      if ([self deadheadAtStartPointsCheckboxValue]) {
         addedPoints += [[line deadheadAtStartCities] countForObject:[self deadheadAtStartCity]] * [self deadheadAtStartPointsValue];
      }
      if ([self deadheadAtEndPointsCheckboxValue]) {
         addedPoints += [[line deadheadAtEndCities] countForObject:[self deadheadAtEndCity]] * [self deadheadAtEndPointsValue];
      }
      // overnight cities
      if ([self overnightCitiesPointsCheckboxValue]) {
         lineOvernightCitiesSet = [line overnightCities];
         NSEnumerator * citiesEnumerator = [lineOvernightCitiesSet objectEnumerator];
         NSString * pointsCity = nil;
         while (pointsCity = [citiesEnumerator nextObject]) {
            pointsNumber = [cityPoints objectForKey:pointsCity];
            if (pointsNumber) {
               addedPoints += ([pointsNumber floatValue] * [lineOvernightCitiesSet countForObject:pointsCity]);
            }
         }
      }
      // overlap
      if ([self noOverlapPointsCheckboxValue] && ![line hasOverlap]) {
         addedPoints += [self noOverlapPointsValue];
      }
      if ([self overlapPointsCheckboxValue] && [line hasOverlap]) {
         addedPoints += [self overlapPointsValue];
      }
	  // max legs per day
	  if (maxLegsPerDayGreaterThanPointsCheckboxValue && 
	      [line maxLegs] > maxLegsPerDayGreaterThanPointsTriggerValue) {
		  addedPoints += maxLegsPerDayGreaterThanPointsValue;
	  }
	  if (maxLegsPerDayLessThanOrEqualPointsCheckboxValue && 
	      [line maxLegs] <= maxLegsPerDayLessThanOrEqualPointsTriggerValue) {
		  addedPoints += maxLegsPerDayLessThanOrEqualPointsValue;
	  }
      // add line credit to pay if line points include pay is selected
      if ([self linePointsIncludePay] == YES) {
         addedPoints += [line credit];
      }
      // set points for line
      [line setPoints:addedPoints];
   }
   [self sortLines];
}

// returns NSComparisonResult based on sort selection's title
NSInteger compareSortSelection(id fore, id aft, void * context )
{
   int comparisonResult = NSOrderedSame;
   
   if ([fore respondsToSelector:@selector(caseInsensitiveCompare:)])
   {
      comparisonResult = [(NSString *)fore caseInsensitiveCompare:(NSString *)aft];
   }
   else
   {
      comparisonResult = [(NSString *)[(NSDictionary *)fore objectForKey:CBDataModelSortSelectionTitleKey] caseInsensitiveCompare:(NSString *)[(NSDictionary *)aft objectForKey:CBDataModelSortSelectionTitleKey]];
   }
   
   return comparisonResult;
   // returns NSComparisonResult based on sort selection's enumerated function key
//   return [(NSNumber *)[(NSDictionary *)fore objectForKey:CBDataModelSortSelectionFunctionKey] compare:(NSNumber *)[(NSDictionary *)aft objectForKey:CBDataModelSortSelectionFunctionKey]];
}

#pragma mark ARRAY OBJECT MANIPULATION

- (void)moveLinesArrayRows:(NSArray *)oldRows toRows:(NSArray *)newRows
{
   if (oldRows && newRows && oldRows != newRows && [oldRows count] == [newRows count]) {
      // undo
//      [[[self undoManager] prepareWithInvocationTarget:self] moveLinesArrayRows:newRows toRows:oldRows];
      // move rows
      NSMutableArray *arr = [[self lines] mutableCopy];
      [arr moveObjectsAtIndexes:oldRows toIndexes:newRows];
      // adjust indexes
      [self adjustIndexesAfterMovingLinesArrayRows:oldRows toRows:newRows];
      // set lines, which will post lines changed notification
      [self setLines:[NSArray arrayWithArray:arr]];
		// post notification that lines have been moved
/*		[[NSNotificationCenter defaultCenter] 
			postNotificationName:CBDataModelLinesMovedNotification 
			object:[self document] 
			userInfo:[NSDictionary 
				dictionaryWithObject:newRows 
				forKey:CBDataModelLinesMovedNotification]];
*/
   }
}

- (void)adjustIndexesAfterMovingLinesArrayRows:(NSArray *)oldRows toRows:(NSArray *)newRows
{
   unsigned rowsCount = [oldRows count];
   int i = 0;
   int toIdx = 0;
   int fromIdx = 0;
   int topFreeze = [self topFreezeIndex];
   int bottomFreeze = [self bottomFreezeIndex];

   for (i = 0; i < rowsCount; ++i) {
      fromIdx = [[oldRows objectAtIndex:i] intValue];
      toIdx = [[newRows objectAtIndex:i] intValue];
      // top freeze
      //    move into top freeze
      if (fromIdx > topFreeze && toIdx <= topFreeze) {
         topFreezeIndex++;
      //    move out of top freeze
      } else if (fromIdx <= topFreeze && toIdx > topFreeze) {
         topFreezeIndex--;
      }
      // bottom freeze
      //    move into bottom freeze
      if (fromIdx <= bottomFreeze && toIdx > bottomFreeze) {
         bottomFreezeIndex--;
      //    move out of bottom freeze
      } else if (fromIdx > bottomFreeze && toIdx <= bottomFreeze) {
         bottomFreezeIndex++;
      }
   }
}

- (void)insertLine:(CBLine *)line atIndex:(int)lineIndex
{   
   if (lineIndex > -1 && lineIndex <= [[self lines] count]) {
      // insert line
      NSMutableArray *mutableLines = [[self lines] mutableCopy];
      [mutableLines insertObject:line atIndex:lineIndex];
      // adjust top and bottom freeze indexes
      if (lineIndex <= [self topFreezeIndex]) {
			topFreezeIndex++;
      }
		if (lineIndex < [self bottomFreezeIndex]) {
			bottomFreezeIndex++;
		}
		// set lines, which will update interface
      [self setLines:[NSArray arrayWithArray:mutableLines]];
	  [mutableLines release];
   }
}

- (void)removeLine:(CBLine *)line atIndex:(int)lineIndex
{
   if (lineIndex > -1 && 
       lineIndex < [[self lines] count]) {

      // remove line
      NSMutableArray *mutableLines = [[self lines] mutableCopy];
      [mutableLines removeObjectAtIndex:lineIndex];
      // adjust top and bottom freeze indexes
      if (lineIndex <= [self topFreezeIndex]) {
			topFreezeIndex--;
      }
		if (lineIndex < [self bottomFreezeIndex]) {
			bottomFreezeIndex--;
		}
      // set lines, which will update interface
      [self setLines:[NSArray arrayWithArray:mutableLines]];
	  [mutableLines release];
   }
}

- (void)insertFaReserveBidAtIndex:(unsigned)index
{
   if (CBFaReserveLineNumber != [(CBLine *)[[self lines] objectAtIndex:index] number]) {
      [self insertLine:[self faReserveBidLine] atIndex:index];
      [self setHasFaReserveBid:YES];
   }
}

- (NSUInteger)removeFaReserveBid
{
   NSUInteger index = [self faReserveBidIndex];
   if (index != NSNotFound) {
      [self removeLine:[self faReserveBidLine] atIndex:index];
      [self setHasFaReserveBid:NO];
   }
   return index;
}

- (void)insertFaMrtBidAtIndex:(unsigned)index
{
   if (CBFaMrtLineNumber != [(CBLine *)[[self lines] objectAtIndex:index] number]) {
      [self insertLine:[self faMrtBidLine] atIndex:index];
      [self setHasFaMrtBid:YES];
   }
}

- (NSUInteger)removeFaMrtBid
{
   NSUInteger index = [self faMrtBidIndex];
   if (index != NSNotFound) {
      [self removeLine:[self faMrtBidLine] atIndex:index];
      [self setHasFaMrtBid:NO];
   }
   return index;
}

- (NSUInteger)faReserveBidIndex
{
   NSArray *linesArr = [self lines];
   NSUInteger linesCount = [linesArr count];
   NSUInteger index = 0;
   while (index < linesCount && CBFaReserveLineNumber != [(CBLine *)[linesArr objectAtIndex:index] number]) {
      index++;
   }
   if (index >= linesCount) {
      index = NSNotFound;
   }
   return index;
}

- (NSUInteger)faMrtBidIndex
{
   NSArray *linesArr = [self lines];
   NSUInteger linesCount = [linesArr count];
   NSUInteger index = 0;
   while (index < linesCount && CBFaMrtLineNumber != [(CBLine *)[linesArr objectAtIndex:index] number]) {
      index++;
   }
   if (index >= linesCount) {
      index = NSNotFound;
   }
   return index;
}

- (CBLine *)faReserveBidLine
{
   if (!faReserveBidLine) {
      faReserveBidLine = [[CBLine alloc] initWithNumber:CBFaReserveLineNumber credit:0.0 block:0.0 trips:[NSArray array]];
   }
   return faReserveBidLine;
}

- (CBLine *)faMrtBidLine
{
   if (!faMrtBidLine) {
      faMrtBidLine = [[CBLine alloc] initWithNumber:CBFaMrtLineNumber credit:0.0 block:0.0 trips:[NSArray array]];
   }
   return faMrtBidLine;
}

#pragma mark SELECTING

- (void)selectLinesByAircraftChanges
{
   int trigger = [self aircraftChangesSelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if ([self aircraftChangesSelectCheckboxValue] && ([line aircraftChanges] > trigger)) {
         [line setDeselectedFlag:CBAircraftChangesDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBAircraftChangesDeselectedLineMask];
      }
   }
}

- (void)selectLinesByAm
{
   BOOL selectAM = [self amSelectCheckboxValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if (selectAM && [line isPM]) {
         [line setDeselectedFlag:CBAmDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBAmDeselectedLineMask];
      }
   }
}

- (void)selectLinesByPm
{
   BOOL selectPM = [self pmSelectCheckboxValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if (selectPM && [line isAM]) {
         [line setDeselectedFlag:CBPmDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBPmDeselectedLineMask];
      }
   }
}

- (void)selectLinesByTurns
{
   int trigger = [self turnSelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if ([self turnSelectCheckboxValue] && ([line turns] > trigger)) {
         [line setDeselectedFlag:CBTurnDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBTurnDeselectedLineMask];
      }
   }
}

- (void)selectLinesByTwoDays
{
   int trigger = [self twoDaySelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if ([self twoDaySelectCheckboxValue] && ([line twoDays] > trigger)) {
         [line setDeselectedFlag:CBTwoDayDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBTwoDayDeselectedLineMask];
      }
   }
}
- (void)selectLinesByThreeDays
{
   int trigger = [self threeDaySelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if ([self threeDaySelectCheckboxValue] && ([line threeDays] > trigger)) {
         [line setDeselectedFlag:CBThreeDayDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBThreeDayDeselectedLineMask];
      }
   }
}
- (void)selectLinesByFourDays
{
   int trigger = [self fourDaySelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if ([self fourDaySelectCheckboxValue] && ([line fourDays] > trigger)) {
         [line setDeselectedFlag:CBFourDayDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBFourDayDeselectedLineMask];
      }
   }
}

- (void)selectLinesByBlockOfDaysOff
{
   int trigger = [self blockOfDaysOffSelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if ([self blockOfDaysOffSelectCheckboxValue] && ([line longestDaysOffBlock] < trigger)) {
         [line setDeselectedFlag:CBBlockOfDaysOffDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBBlockOfDaysOffDeselectedLineMask];
      }
   }
}

- (void)selectLinesByDaysOfMonth
{
   NSMutableSet * lineSet = [NSMutableSet set];
   NSSet * daysOff = [self daysOfMonthSelectValues];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      [lineSet setSet:[line workDates]];
      [lineSet unionSet:[line workDatesNextMonth]];
      if ([self daysOfMonthSelectCheckboxValue] && [daysOff intersectsSet:lineSet]) {
         [line setDeselectedFlag:CBDaysOfMonthDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBDaysOfMonthDeselectedLineMask];
      }
   }
}

- (void)selectLinesByDeadheadAtStart
{
    BOOL select = [self deadheadAtStartSelectCheckboxValue];
    NSString *city = [self deadheadAtStartCity];
    NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
    CBLine * line = nil;
    while (line = [linesEnumerator nextObject]) {
        if (select) {
            if ([[line deadheadAtStartCities] containsObject:city]) {
                [line clearDeselectedFlag:CBDeadheadAtStartDeselectedMask];
            } else {
                [line setDeselectedFlag:CBDeadheadAtStartDeselectedMask];
            }
        } else {
            [line clearDeselectedFlag:CBDeadheadAtStartDeselectedMask];
        }
    }
}

- (void)selectLinesByDeadheadAtEnd
{
    BOOL select = [self deadheadAtEndSelectCheckboxValue];
    NSString *city = [self deadheadAtEndCity];
    NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
    CBLine * line = nil;
    while (line = [linesEnumerator nextObject]) {
        if (select) {
            if ([[line deadheadAtEndCities] containsObject:city]) {
                [line clearDeselectedFlag:CBDeadheadAtEndDeselectedMask];
            } else {
                [line setDeselectedFlag:CBDeadheadAtEndDeselectedMask];
            }
        } else {
            [line clearDeselectedFlag:CBDeadheadAtEndDeselectedMask];
        }
    }
}

- (void)selectLinesByOvernightCities
{
   CBSelectChoice choice = [self overnightCitiesSelectMatrixValue];
   NSSet * selectedCities = [self overnightCitiesSelectValues];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      switch (choice) {
         case CBNoSelect :
            [line clearDeselectedFlag:CBOvernightCitiesDeselectedLineMask];
            break;
         case CBSelectWithAtLeastOne :
            if ([selectedCities intersectsSet:[line overnightCities]]) {
               [line clearDeselectedFlag:CBOvernightCitiesDeselectedLineMask];
            } else {
               [line setDeselectedFlag:CBOvernightCitiesDeselectedLineMask];
            }
            break;
         case CBSelectWithNone :
            if ([selectedCities intersectsSet:[line overnightCities]]) {
               [line setDeselectedFlag:CBOvernightCitiesDeselectedLineMask];
            } else {
               [line clearDeselectedFlag:CBOvernightCitiesDeselectedLineMask];
            }
            break;
         default :
            break;
      }
   }
}

- (void)selectLinesByNoOverlap
{
   BOOL selectNoOverlap = [self noOverlapSelectCheckboxValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if (selectNoOverlap && [line hasOverlap]) {
         [line setDeselectedFlag:CBOverlapDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBOverlapDeselectedLineMask];
      }
   }
}

- (void)selectLinesByMaxLegsPerDay
{
   BOOL shouldSelect = [self maxLegsPerDaySelectCheckboxValue];
   int trigger = [self maxLegsPerDaySelectTriggerValue];
   NSEnumerator * linesEnumerator = [[self lines] objectEnumerator];
   CBLine * line = nil;
   while (line = [linesEnumerator nextObject]) {
      if (shouldSelect && [line maxLegs] > trigger) {
         [line setDeselectedFlag:CBMaxLegsPerDayDeselectedLineMask];
      } else {
         [line clearDeselectedFlag:CBMaxLegsPerDayDeselectedLineMask];
      }
   }
}

#pragma mark CLIPBOARD TEXT

- (NSString *)clipboardTextWithLine:(CBLine *)line
{
   NSMutableString *clipboardText = [NSMutableString string];
   NSEnumerator *tripsEnum = [[line trips] objectEnumerator];
   NSDictionary *lineTrip = nil;
   CBTrip *trip = nil;
   int day = 0;
   NSCalendarDate *startDate = nil;
   while (lineTrip = [tripsEnum nextObject]) {
      trip = [[self trips] objectForKey:[lineTrip objectForKey:CBLineTripNumberKey]];
      day = [[lineTrip objectForKey:CBLineTripDateKey] intValue];
      startDate = [[self month] dateByAddingYears:0 months:0 days:day - 1 hours:0 minutes:0 seconds:0];
      [clipboardText appendString:[trip clipboardTextWithStartDate:startDate]];
   }
   return [NSString stringWithString:clipboardText];
}

#pragma mark STORAGE

static NSString * CBDataModelMonthKey = @"Month";
static NSString * CBDataModelCrewBaseKey = @"Crew Base";
static NSString * CBDataModelCrewPositionKey = @"Crew Position";
static NSString * CBDataModelLinesKey = @"Lines";
static NSString * CBDataModelTripsKey = @"Trips";
static NSString * CBDataModelTopFreezeIndexKey = @"Top Freeze Index";
static NSString * CBDataModelBottomFreezeIndexKey = @"Bottom Freeze Index";
static NSString * CBDataModelAvailableSortSelectionsKey = @"Available Sort Selections";
static NSString * CBDataModelInUseSortSelectionsKey = @"In Use Sort Selections";
static NSString * CBDataModelLinePointsIncludePayCheckboxValueKey = @"Line Points Include Pay";
static NSString * CBDataModelReserveLinesToBottomCheckboxValueKey = @"Reserve Lines To Bottom Checkbox Value";
static NSString * CBDataModelBlankLinesToBottomCheckboxValueKey = @"Blank Lines To Bottom Checkbox Value";
static NSString * CBDataModelAircraftChangesSelectCheckboxValueKey = @"Aircraft Changes Select Checkbox Value";
static NSString * CBDataModelAircraftChangesSelectTriggerValueKey = @"Aircraft Changes Select Trigger Value";
static NSString * CBDataModelAircraftChangesPointsCheckboxValueKey = @"Aircraft Changes Points Checkbox Value";
static NSString * CBDataModelAircraftChangesPointsValueKey = @"Aircraft Changes Points Value";
static NSString * CBDataModelAmSelectCheckboxValueKey = @"AM Select Checkbox Value";
static NSString * CBDataModelPmSelectCheckboxValueKey = @"PM Select Checkbox Value";
static NSString * CBDataModelAmPointsCheckboxValueKey = @"AM Points Checkbox Value";
static NSString * CBDataModelAmPointsValueKey = @"AM Points Value";
static NSString * CBDataModelPmPointsCheckboxValueKey = @"PM Points Checkbox Value";
static NSString * CBDataModelPmPointsValueKey = @"PM Points Value";
static NSString * CBDataModelTurnSelectCheckboxValueKey = @"Turn Select Checkbox Value";
static NSString * CBDataModelTurnSelectTriggerValueKey = @"Turn Select Trigger Value";
static NSString * CBDataModelTurnPointsCheckboxValueKey = @"Turn Points Checkbox Value";
static NSString * CBDataModelTurnPointsValueKey = @"Turn Points Value";
static NSString * CBDataModelTwoDaySelectCheckboxValueKey = @"Two-Day Select Checkbox Value";
static NSString * CBDataModelTwoDaySelectTriggerValueKey = @"Two-Day Select Trigger Value";
static NSString * CBDataModelTwoDayPointsCheckboxValueKey = @"Two-Day Points Checkbox Value";
static NSString * CBDataModelTwoDayPointsValueKey = @"Two-Day Points Value";
static NSString * CBDataModelThreeDaySelectCheckboxValueKey = @"Three-Day Select Checkbox Value";
static NSString * CBDataModelThreeDaySelectTriggerValueKey = @"Three-Day Select Trigger Value";
static NSString * CBDataModelThreeDayPointsCheckboxValueKey = @"Three-Day Points Checkbox Value";
static NSString * CBDataModelThreeDayPointsValueKey = @"Three-Day Points Value";
static NSString * CBDataModelFourDaySelectCheckboxValueKey = @"Four-Day Select Checkbox Value";
static NSString * CBDataModelFourDaySelectTriggerValueKey = @"Four-Day Select Trigger Value";
static NSString * CBDataModelFourDayPointsCheckboxValueKey = @"Four-Day Points Checkbox Value";
static NSString * CBDataModelFourDayPointsValueKey = @"Four-Day Points Value";
static NSString * CBDataModelDaysOfMonthSelectCheckboxValueKey = @"Days Of Month Select Checkbox Value";
static NSString * CBDataModelDaysOfMonthSelectValuesKey = @"Days Of Month Select Values";
static NSString * CBDataModelDaysOfMonthPointsCheckboxValueKey = @"Days Of Month Points Checkbox Value";
static NSString * CBDataModelDaysOfMonthPointsValuesKey = @"Days Of Month Points Values";
static NSString * CBDataModelDaysOfWeekSelectValuesKey = @"Days Of Week Select Values";
static NSString * CBDataModelDaysOfWeekPointsValuesKey = @"Days Of Week Points Values";
static NSString * CBDataModelOvernightCitiesSelectMatrixValueKey = @"Overnight Cities Select Matrix Value";
static NSString * CBDataModelOvernightCitiesSelectValuesKey = @"Overnight Cities Select Values";
static NSString * CBDataModelOvernightCitiesPointsCheckboxValueKey = @"Overnight Cities Points Checkbox Value";
static NSString * CBDataModelOvernightCitiesPointsValuesKey = @"Overnight Cities Points Values";
static NSString * CBDataModelOverlapFormValuesKey = @"Overlap Form Values";
static NSString * CBDataModelNoOverlapSelectCheckboxValueKey = @"No Overlap Select Checkbox Value";
static NSString * CBDataModelNoOverlapPointsCheckboxValueKey = @"No Overlap Points Checkbox Value";
static NSString * CBDataModelNoOverlapPointsValueKey = @"No Overlap Points Value";
static NSString * CBDataModelOverlapPointsCheckboxValueKey = @"Overlap Points Checkbox Value";
static NSString * CBDataModelOverlapPointsValueKey = @"Overlap Points Value";
static NSString * CBDataModelBlockOfDaysOffSelectCheckboxValueKey = @"Block of Days Off Select Checkbox Value";
static NSString * CBDataModelBlockOfDaysOffSelectTriggerValueKey = @"Block of Days Off Trigger Value";
static NSString * CBDataModelBlockOfDaysOffPointsCheckboxValueKey = @"Block of Days Off Points Checkbox Value";
static NSString * CBDataModelBlockOfDaysOffPointsTriggerValueKey = @"Block of Days Off Points Trigger Value";
static NSString * CBDataModelBlockOfDaysOffPointsValueKey = @"Block of Days Off Points Value";
//static NSString * CBDataModelFaPositionsValueKey = @"FA Positions Values";

// Deadheads
static NSString *CBDataModelDeadheadAtStartCheckboxValueKey = @"Deadhead At Start Select Checkbox Value";
static NSString *CBDataModelDeadheadAtStartCityKey = @"Deadhead At Start City";
static NSString *CBDataModelDeadheadAtStartPointsCheckboxValueKey = @"Deadhead At Start Points Checkbox Value";
static NSString *CBDataModelDeadheadAtStartPointsValueKey = @"Deadhead At Start Points Value";
static NSString *CBDataModelDeadheadAtEndCheckboxValueKey = @"Deadhead At End Select Checkbox Value";
static NSString *CBDataModelDeadheadAtEndCityKey = @"Deadhead At End City";
static NSString *CBDataModelDeadheadAtEndPointsCheckboxValueKey = @"Deadhead At End Points Checkbox Value";
static NSString *CBDataModelDeadheadAtEndPointsValueKey = @"Deadhead At End Points Value";
// Commute Times
static NSString *CBDataModelCommuteWeekdayStartValueKey = @"Commute Weekday Start Value";
static NSString *CBDataModelCommuteFridayStartValueKey = @"Commute Friday Start Value";
static NSString *CBDataModelCommuteSaturdayStartValueKey = @"Commute Saturday Start Value";
static NSString *CBDataModelCommuteSundayStartValueKey = @"Commute Sunday Start Value";
static NSString *CBDataModelCommuteWeekdayEndValueKey = @"Commute Weekday End Value";
static NSString *CBDataModelCommuteFridayEndValueKey = @"Commute Friday End Value";
static NSString *CBDataModelCommuteSaturdayEndValueKey = @"Commute Saturday End Value";
static NSString *CBDataModelCommuteSundayEndValueKey = @"Commute Sunday End Value";
// Commuting
//static NSString *CBDataModelCommuteSelectBothEndsCheckboxValueKey = @"Commute Select Both Ends Checkbox Value";
//static NSString *CBDataModelCommuteSelectBothEndsAllTripsValueKey = @"Commute Select Both Ends All Trips Value";
static NSString *CBDataModelCommuteSelectsByCommutesRequiredKey = @"Commute Selects By Commutes Required";
static NSString *CBDataModelCommuteSelectsByCommutesRequiredTriggerKey = @"Commute Selects By Commutes Required Trigger";
static NSString *CBDataModelCommuteSelectsByOvernightsInDomicileKey = @"Commute Selects By Overnights In Domicile";
static NSString *CBDataModelCommuteSelectsByOvernightsInDomicileTriggerKey = @"Commute Selects By Overnights In Domicile Trigger";
static NSString *CBDataModelCommuteAssignsPointsForCommutesRequiredKey = @"Commute Assigns Points For Commutes Required";
static NSString *CBDataModelCommutePointsForCommutesRequiredKey = @"Commute Points For Commutes Required";
static NSString *CBDataModelCommuteAssignsPointsForOvernightsInDomicileKey = @"Commute Assigns Points For Overnights In Domicile";
static NSString *CBDataModelCommutePointsForOvernightsInDomicileKey = @"Commute Points For Overnights In Domicile";
// Max legs per day
static NSString *CBDataModelMaxLegsPerDaySelectCheckboxValueKey = @"Max Legs Per Day Checkbox Value";
static NSString *CBDataModelMaxLegsPerDaySelectTriggerValueKey = @"Max Legs Per Day Trigger Value";
static NSString *CBDataModelMaxLegsPerDayLessThanOrEqualPointsCheckboxValueKey = @"Max Legs Per Day Less Than Or Equal Checkbox Value";
static NSString *CBDataModelMaxLegsPerDayLessThanOrEqualPointsTriggerValueKey = @"Max Legs Per Day Less Than Or Eaual Points Trigger Value";
static NSString *CBDataModelMaxLegsPerDayLessThanOrEqualPointsValueKey = @"Max Legs Per Day Less Than Or Eaual Points Value";
static NSString *CBDataModelMaxLegsPerDayGreaterThanPointsCheckboxValueKey = @"Max Legs Per Day Greater Than Checkbox Value";
static NSString *CBDataModelMaxLegsPerDayGreaterThanPointsTriggerValueKey = @"Max Legs Per Day Greater Than Points Trigger Value";
static NSString *CBDataModelMaxLegsPerDayGreaterThanPointsValueKey = @"Max Legs Per Day Greater Than Points Value";

- (void)encodeWithCoder:(NSCoder *)encoder
{
   unsigned version = [encoder versionForClassName:@"CBDataModel"];

   if ([encoder allowsKeyedCoding]) {
      // basic document data
      [encoder encodeObject:[self month] forKey:CBDataModelMonthKey];
      [encoder encodeObject:[self crewBase] forKey:CBDataModelCrewBaseKey];
      [encoder encodeObject:[self crewPosition] forKey:CBDataModelCrewPositionKey];
      [encoder encodeObject:[self lines] forKey:CBDataModelLinesKey];
      [encoder encodeObject:[self trips] forKey:CBDataModelTripsKey];
      // top/bottom freeze indexes
      [encoder encodeInt:[self topFreezeIndex] forKey:CBDataModelTopFreezeIndexKey];
      [encoder encodeInt:[self bottomFreezeIndex] forKey:CBDataModelBottomFreezeIndexKey];
      // sort selections
      [encoder encodeObject:[self availableSortSelections] forKey:CBDataModelAvailableSortSelectionsKey];
      [encoder encodeObject:[self inUseSortSelections] forKey:CBDataModelInUseSortSelectionsKey];
      // points
      [encoder encodeBool:[self linePointsIncludePay] forKey:CBDataModelLinePointsIncludePayCheckboxValueKey];
      // reserve/blank lines to bottom
      [encoder encodeBool:[self reserveLinesToBottomCheckboxValue] forKey:CBDataModelReserveLinesToBottomCheckboxValueKey];
      [encoder encodeBool:[self blankLinesToBottomCheckboxValue] forKey:CBDataModelBlankLinesToBottomCheckboxValueKey];
      // aircraft changes
      [encoder encodeBool:[self aircraftChangesSelectCheckboxValue] forKey:CBDataModelAircraftChangesSelectCheckboxValueKey];
      [encoder encodeInt:[self aircraftChangesSelectTriggerValue] forKey:CBDataModelAircraftChangesSelectTriggerValueKey];
      [encoder encodeBool:[self aircraftChangesPointsCheckboxValue] forKey:CBDataModelAircraftChangesPointsCheckboxValueKey];
      [encoder encodeFloat:[self aircraftChangesPointsValue] forKey:CBDataModelAircraftChangesPointsValueKey];
      // am/pm
      [encoder encodeBool:[self amSelectCheckboxValue] forKey:CBDataModelAmSelectCheckboxValueKey];
      [encoder encodeBool:[self pmSelectCheckboxValue] forKey:CBDataModelPmSelectCheckboxValueKey];
      [encoder encodeBool:[self amPointsCheckboxValue] forKey:CBDataModelAmPointsCheckboxValueKey];
      [encoder encodeFloat:[self amPointsValue] forKey:CBDataModelAmPointsValueKey];
      [encoder encodeBool:[self pmPointsCheckboxValue] forKey:CBDataModelPmPointsCheckboxValueKey];
      [encoder encodeFloat:[self pmPointsValue] forKey:CBDataModelPmPointsValueKey];
      // turns
      [encoder encodeBool:[self turnSelectCheckboxValue] forKey:CBDataModelTurnSelectCheckboxValueKey];
      [encoder encodeInt:[self turnSelectTriggerValue] forKey:CBDataModelTurnSelectTriggerValueKey];
      [encoder encodeBool:[self turnPointsCheckboxValue] forKey:CBDataModelTurnPointsCheckboxValueKey];
      [encoder encodeFloat:[self turnPointsValue] forKey:CBDataModelTurnPointsValueKey];
      // two-days
      [encoder encodeBool:[self twoDaySelectCheckboxValue] forKey:CBDataModelTwoDaySelectCheckboxValueKey];
      [encoder encodeInt:[self twoDaySelectTriggerValue] forKey:CBDataModelTwoDaySelectTriggerValueKey];
      [encoder encodeBool:[self twoDayPointsCheckboxValue] forKey:CBDataModelTwoDayPointsCheckboxValueKey];
      [encoder encodeFloat:[self twoDayPointsValue] forKey:CBDataModelTwoDayPointsValueKey];
      // three-days
      [encoder encodeBool:[self threeDaySelectCheckboxValue] forKey:CBDataModelThreeDaySelectCheckboxValueKey];
      [encoder encodeInt:[self threeDaySelectTriggerValue] forKey:CBDataModelThreeDaySelectTriggerValueKey];
      [encoder encodeBool:[self threeDayPointsCheckboxValue] forKey:CBDataModelThreeDayPointsCheckboxValueKey];
      [encoder encodeFloat:[self threeDayPointsValue] forKey:CBDataModelThreeDayPointsValueKey];
      // four-days
      [encoder encodeBool:[self fourDaySelectCheckboxValue] forKey:CBDataModelFourDaySelectCheckboxValueKey];
      [encoder encodeInt:[self fourDaySelectTriggerValue] forKey:CBDataModelFourDaySelectTriggerValueKey];
      [encoder encodeBool:[self fourDayPointsCheckboxValue] forKey:CBDataModelFourDayPointsCheckboxValueKey];
      [encoder encodeFloat:[self fourDayPointsValue] forKey:CBDataModelFourDayPointsValueKey];
      // days of month
      [encoder encodeBool:[self daysOfMonthSelectCheckboxValue] forKey:CBDataModelDaysOfMonthSelectCheckboxValueKey];
      [encoder encodeObject:[self daysOfMonthSelectValues] forKey:CBDataModelDaysOfMonthSelectValuesKey];
      [encoder encodeBool:[self daysOfMonthPointsCheckboxValue] forKey:CBDataModelDaysOfMonthPointsCheckboxValueKey];
      [encoder encodeObject:[self daysOfMonthPointsValues] forKey:CBDataModelDaysOfMonthPointsValuesKey];
      [encoder encodeObject:[self daysOfWeekSelectValues] forKey:CBDataModelDaysOfWeekSelectValuesKey];
      [encoder encodeObject:[self daysOfWeekPointsValues] forKey:CBDataModelDaysOfWeekPointsValuesKey];
      // overnight cities
      [encoder encodeInt:[self overnightCitiesSelectMatrixValue] forKey:CBDataModelOvernightCitiesSelectMatrixValueKey];
      [encoder encodeObject:[self overnightCitiesSelectValues] forKey:CBDataModelOvernightCitiesSelectValuesKey];
      [encoder encodeBool:[self overnightCitiesPointsCheckboxValue] forKey:CBDataModelOvernightCitiesPointsCheckboxValueKey];
      [encoder encodeObject:[self overnightCitiesPointsValues] forKey:CBDataModelOvernightCitiesPointsValuesKey];
      // overlap
      [encoder encodeObject:[self overlapFormValues] forKey:CBDataModelOverlapFormValuesKey];
      // NEED TO ADD OTHER OVERLAP, BLOCK OF DAYS OFF, and FA POSITION DATA
      
   } else {
      // basic document data
      [encoder encodeObject:month];
      [encoder encodeObject:crewBase];
      [encoder encodeObject:crewPosition];
      [encoder encodeObject:lines];
      [encoder encodeObject:trips];
      // top/bottom freeze indexes
      [encoder encodeValueOfObjCType:@encode(int) at:&topFreezeIndex];
      [encoder encodeValueOfObjCType:@encode(int) at:&bottomFreezeIndex];
      // sort selections
      [encoder encodeObject:availableSortSelections];
      [encoder encodeObject:inUseSortSelections];
      // points
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&linePointsIncludePay];
      // reserve/blank lines to bottom
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&reserveLinesToBottomCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&blankLinesToBottomCheckboxValue];
      // selecting
      // aircraft changes
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&aircraftChangesSelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(int) at:&aircraftChangesSelectTriggerValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&aircraftChangesPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&aircraftChangesPointsValue];
      // am/pm
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&amSelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&pmSelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&amPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&amPointsValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&pmPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&pmPointsValue];
      // turns
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&turnSelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(int) at:&turnSelectTriggerValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&turnPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&turnPointsValue];
      // two-days
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&twoDaySelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(int) at:&twoDaySelectTriggerValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&twoDayPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&twoDayPointsValue];
      // three-days
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&threeDaySelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(int) at:&threeDaySelectTriggerValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&threeDayPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&threeDayPointsValue];
      // four-days
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&fourDaySelectCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(int) at:&fourDaySelectTriggerValue];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&fourDayPointsCheckboxValue];
      [encoder encodeValueOfObjCType:@encode(float) at:&fourDayPointsValue];
      // days of month
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&daysOfMonthSelectCheckboxValue];
      [encoder encodeObject:daysOfMonthSelectValues];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&daysOfMonthPointsCheckboxValue];
      [encoder encodeObject:daysOfMonthPointsValues];
      [encoder encodeObject:daysOfWeekSelectValues];
      [encoder encodeObject:daysOfWeekPointsValues];
      // overnight cities
      [encoder encodeValueOfObjCType:@encode(int) at:&overnightCitiesSelectMatrixValue];
      [encoder encodeObject:overnightCitiesSelectValues];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&overnightCitiesPointsCheckboxValue];
      [encoder encodeObject:overnightCitiesPointsValues];
      // overlap form values
      // encode only if version > 0
      if (version > 0) {
         [encoder encodeObject:overlapFormValues];
      }
      // encode only if version > 1
      if (version > 1) {
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&noOverlapSelectCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&noOverlapPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(float) at:&noOverlapPointsValue];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&overlapPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(float) at:&overlapPointsValue];
      }
      // encode only if version > 2
      if (version > 2) {
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&blockOfDaysOffSelectCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(int) at:&blockOfDaysOffSelectTriggerValue];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&blockOfDaysOffPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(int) at:&blockOfDaysOffPointsTriggerValue];
         [encoder encodeValueOfObjCType:@encode(float) at:&blockOfDaysOffPointsValue];
      }
      // encode only if version > 3
      if (version > 3) {
         if ([self isFlightAttendantBid])
         {
            [encoder encodeObject:faPositions];
         }
      }
      // encode only if version > 4
      if (version > 4) {
         [encoder encodeValueOfObjCType:@encode(int) at:&bidRound];
         if ([self isFlightAttendantFirstRoundBid])
         {
            [encoder encodeValueOfObjCType:@encode(BOOL) at:&hasFaReserveBid];
            [encoder encodeValueOfObjCType:@encode(BOOL) at:&hasFaMrtBid];
         }
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&threeOnThreeOffToBottomCheckboxValue];
      }
      // encode only if version > 5
      if (version > 5) {
		  // deadheads
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&deadheadAtStartSelectCheckboxValue];
         [encoder encodeObject:deadheadAtStartCity];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&deadheadAtEndSelectCheckboxValue];
         [encoder encodeObject:deadheadAtEndCity];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&deadheadAtStartPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(float) at:&deadheadAtStartPointsValue];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&deadheadAtEndPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(float) at:&deadheadAtEndPointsValue];
         // commuting times
         [encoder encodeObject:commuteWeekdayStartValue];
         [encoder encodeObject:commuteWeekdayEndValue];
         [encoder encodeObject:commuteFridayStartValue];
         [encoder encodeObject:commuteFridayEndValue];
         [encoder encodeObject:commuteSaturdayStartValue];
         [encoder encodeObject:commuteSaturdayEndValue];
         [encoder encodeObject:commuteSundayStartValue];
         [encoder encodeObject:commuteSundayEndValue];
		 [encoder encodeValueOfObjCType:@encode(BOOL) at:&considerAdjacentTripsNotCommutable];
		 // commuting select
		 [encoder encodeValueOfObjCType:@encode(BOOL) at:&commuteSelectsByCommutesRequired];
		 [encoder encodeValueOfObjCType:@encode(int) at:&commuteSelectsByCommutesRequiredTrigger];
		 [encoder encodeValueOfObjCType:@encode(BOOL) at:&commuteSelectsByOvernightsInDomicile];
		 [encoder encodeValueOfObjCType:@encode(int) at:&commuteSelectsByOvernightsInDomicileTrigger];
		 // commuting points
		 [encoder encodeValueOfObjCType:@encode(BOOL) at:&commuteAssignsPointsForCommutesRequired];
		 [encoder encodeValueOfObjCType:@encode(float) at:&commutePointsForCommutesRequired];
		 [encoder encodeValueOfObjCType:@encode(BOOL) at:&commuteAssignsPointsForOvernightsInDomicile];
		 [encoder encodeValueOfObjCType:@encode(float) at:&commutePointsForOvernightsInDomicile];
      }
	  // encode only if version > 6
	  if (version > 6) {
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&maxLegsPerDaySelectCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(int) at:&maxLegsPerDaySelectTriggerValue];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&maxLegsPerDayLessThanOrEqualPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(int) at:&maxLegsPerDayLessThanOrEqualPointsTriggerValue];
		 [encoder encodeValueOfObjCType:@encode(float) at:&maxLegsPerDayLessThanOrEqualPointsValue];
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&maxLegsPerDayGreaterThanPointsCheckboxValue];
         [encoder encodeValueOfObjCType:@encode(int) at:&maxLegsPerDayGreaterThanPointsTriggerValue];
		 [encoder encodeValueOfObjCType:@encode(float) at:&maxLegsPerDayGreaterThanPointsValue];
	  }
   }
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super init];

   unsigned version = [decoder versionForClassName:@"CBDataModel"];

   // disable undo until data is initialized
   [[self undoManager] disableUndoRegistration];
   // disable sorting until data is initialized
   [self setSortingEnabled:NO];
   
   if ([decoder allowsKeyedCoding]) {
      // basic document data
      [self setMonth:[decoder decodeObjectForKey:CBDataModelMonthKey]];
      [self setCrewBase:[decoder decodeObjectForKey:CBDataModelCrewBaseKey]];
      [self setCrewPosition:[decoder decodeObjectForKey:CBDataModelCrewPositionKey]];
      [self setLines:[decoder decodeObjectForKey:CBDataModelLinesKey]];
      [self setTrips:[decoder decodeObjectForKey:CBDataModelTripsKey]];
      // top/bottom freeze indexes
      [self setTopFreezeIndex:[decoder decodeIntForKey:CBDataModelTopFreezeIndexKey]];
      [self setBottomFreezeIndex:[decoder decodeIntForKey:CBDataModelBottomFreezeIndexKey]];
      // sort selections
      // convert NSDictionary type sort selections to NSString sort selections
      [self setAvailableSortSelections:[self stringSortSelectionsWithDictionarySortSelections:(NSArray *)[decoder decodeObjectForKey:CBDataModelAvailableSortSelectionsKey]]];
      [self setInUseSortSelections:[self stringSortSelectionsWithDictionarySortSelections:(NSArray *)[decoder decodeObjectForKey:CBDataModelInUseSortSelectionsKey]]];
      // points
      [self setLinePointsIncludePay:[decoder decodeBoolForKey:CBDataModelLinePointsIncludePayCheckboxValueKey]];
      // reserve/blank lines to bottom
      [self setReserveLinesToBottomCheckboxValue:[decoder decodeBoolForKey:CBDataModelReserveLinesToBottomCheckboxValueKey]];
      [self setBlankLinesToBottomCheckboxValue:[decoder decodeBoolForKey:CBDataModelBlankLinesToBottomCheckboxValueKey]];
      // aircraft changes
      [self setAircraftChangesSelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelAircraftChangesSelectCheckboxValueKey]];
      [self setAircraftChangesSelectTriggerValue:[decoder decodeIntForKey:CBDataModelAircraftChangesSelectTriggerValueKey]];
      [self setAircraftChangesPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelAircraftChangesPointsCheckboxValueKey]];
      [self setAircraftChangesPointsValue:[decoder decodeFloatForKey:CBDataModelAircraftChangesPointsValueKey]];
      // am/pm
      [self setAmSelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelAmSelectCheckboxValueKey]];
      [self setPmSelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelPmSelectCheckboxValueKey]];
      [self setAmPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelAmPointsCheckboxValueKey]];
      [self setAmPointsValue:[decoder decodeFloatForKey:CBDataModelAmPointsValueKey]];
      [self setPmPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelPmPointsCheckboxValueKey]];
      [self setPmPointsValue:[decoder decodeFloatForKey:CBDataModelPmPointsValueKey]];
      // turns
      [self setTurnSelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelTurnSelectCheckboxValueKey]];
      [self setTurnSelectTriggerValue:[decoder decodeIntForKey:CBDataModelTurnSelectTriggerValueKey]];
      [self setTurnPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelTurnPointsCheckboxValueKey]];
      [self setTurnPointsValue:[decoder decodeFloatForKey:CBDataModelTurnPointsValueKey]];
      // two-days
      [self setTwoDaySelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelTwoDaySelectCheckboxValueKey]];
      [self setTwoDaySelectTriggerValue:[decoder decodeIntForKey:CBDataModelTwoDaySelectTriggerValueKey]];
      [self setTwoDayPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelTwoDayPointsCheckboxValueKey]];
      [self setTwoDayPointsValue:[decoder decodeFloatForKey:CBDataModelTwoDayPointsValueKey]];
      // three-days
      [self setThreeDaySelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelThreeDaySelectCheckboxValueKey]];
      [self setThreeDaySelectTriggerValue:[decoder decodeIntForKey:CBDataModelThreeDaySelectTriggerValueKey]];
      [self setThreeDayPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelThreeDayPointsCheckboxValueKey]];
      [self setThreeDayPointsValue:[decoder decodeFloatForKey:CBDataModelThreeDayPointsValueKey]];
      // four-days
      [self setFourDaySelectCheckboxValue:[decoder decodeBoolForKey:CBDataModelFourDaySelectCheckboxValueKey]];
      [self setFourDaySelectTriggerValue:[decoder decodeIntForKey:CBDataModelFourDaySelectTriggerValueKey]];
      [self setFourDayPointsCheckboxValue:[decoder decodeBoolForKey:CBDataModelFourDayPointsCheckboxValueKey]];
      [self setFourDayPointsValue:[decoder decodeFloatForKey:CBDataModelFourDayPointsValueKey]];
      // overlap
      [self setOverlapFormValues:[decoder decodeObjectForKey:CBDataModelOverlapFormValuesKey]];
      // NEED TO ADD OTHER OVERLAP, BLOCK OF DAYS OFF, and FA POSITION DATA
      
   } else {
      // basic document data
      [self setMonth:[decoder decodeObject]];
      [self setCrewBase:[decoder decodeObject]];
      [self setCrewPosition:[decoder decodeObject]];
      [self setLines:[decoder decodeObject]];
      [self setTrips:[decoder decodeObject]];
      // top/bottom freeze indexes
      int tempInt = 0;
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setTopFreezeIndex:tempInt];
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setBottomFreezeIndex:tempInt];
      // sort selections
      [self setAvailableSortSelections:[self stringSortSelectionsWithDictionarySortSelections:(NSArray *)[decoder decodeObject]]];
      [self setInUseSortSelections:[self stringSortSelectionsWithDictionarySortSelections:(NSArray *)[decoder decodeObject]]];
      // points
      BOOL tempBool = NO;
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setLinePointsIncludePay:tempBool];
      // reserve/blank lines to bottom
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setReserveLinesToBottomCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setBlankLinesToBottomCheckboxValue:tempBool];
      // selecting
      float tempFloat = 0.0;
      // aircraft changes
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setAircraftChangesSelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setAircraftChangesSelectTriggerValue:tempInt];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setAircraftChangesPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setAircraftChangesPointsValue:tempFloat];
      // am/pm
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setAmSelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setPmSelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setAmPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setAmPointsValue:tempFloat];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setPmPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setPmPointsValue:tempFloat];
      // turns
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setTurnSelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setTurnSelectTriggerValue:tempInt];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setTurnPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setTurnPointsValue:tempFloat];
      // two-days
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setTwoDaySelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setTwoDaySelectTriggerValue:tempInt];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setTwoDayPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setTwoDayPointsValue:tempFloat];
      // three-days
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setThreeDaySelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setThreeDaySelectTriggerValue:tempInt];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setThreeDayPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setThreeDayPointsValue:tempFloat];
      // four-days
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setFourDaySelectCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setFourDaySelectTriggerValue:tempInt];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setFourDayPointsCheckboxValue:tempBool];
      [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
      [self setFourDayPointsValue:tempFloat];
      // days of month
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setDaysOfMonthSelectCheckboxValue:tempBool];
      [self setDaysOfMonthSelectValues:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setDaysOfMonthPointsCheckboxValue:tempBool];
      [self setDaysOfMonthPointsValues:[decoder decodeObject]];
      [self setDaysOfWeekSelectValues:[decoder decodeObject]];
      [self setDaysOfWeekPointsValues:[decoder decodeObject]];
      // overnight cities
      [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
      [self setOvernightCitiesSelectMatrixValue:tempInt];
      [self setOvernightCitiesSelectValues:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
      [self setOvernightCitiesPointsCheckboxValue:tempBool];
      [self setOvernightCitiesPointsValues:[decoder decodeObject]];
      // overlap form values
      // decode only if version > 0
      if (version > 0) {
         [self setOverlapFormValues:[decoder decodeObject]];
      }
      // decode only if version > 1
      if (version > 1) {
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setNoOverlapSelectCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setNoOverlapPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setNoOverlapPointsValue:tempFloat];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setOverlapPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setOverlapPointsValue:tempFloat];
      }
      // decode only if version > 2
      if (version > 2) {
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setBlockOfDaysOffSelectCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
         [self setBlockOfDaysOffSelectTriggerValue:tempInt];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setBlockOfDaysOffPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
         [self setBlockOfDaysOffPointsTriggerValue:tempInt];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setBlockOfDaysOffPointsValue:tempFloat];
      }
      // decode only if version > 3
      if (version > 3) {
         if ([self isFlightAttendantBid]) {
            [self setFaPositions:[decoder decodeObject]];
         }
      }
      // decode only if version > 4
      if (version > 4) {
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
         [self setBidRound:tempInt];
         if ([self isFlightAttendantFirstRoundBid]) {
            [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
            [self setHasFaReserveBid:tempBool];
            [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
            [self setHasFaMrtBid:tempBool];
         }
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setThreeOnThreeOffToBottomCheckboxValue:tempBool];
      }
      // decode only if version > 5
      // deadheads
      if (version > 5) {
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setDeadheadAtStartSelectCheckboxValue:tempBool];
         [self setDeadheadAtStartCity:[decoder decodeObject]];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setDeadheadAtEndSelectCheckboxValue:tempBool];
         [self setDeadheadAtEndCity:[decoder decodeObject]];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setDeadheadAtStartPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setDeadheadAtStartPointsValue:tempFloat];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setDeadheadAtEndPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setDeadheadAtEndPointsValue:tempFloat];
         // commuting times
         [self setCommuteWeekdayStartValue:[decoder decodeObject]];
         [self setCommuteWeekdayEndValue:[decoder decodeObject]];
         [self setCommuteFridayStartValue:[decoder decodeObject]];
         [self setCommuteFridayEndValue:[decoder decodeObject]];
         [self setCommuteSaturdayStartValue:[decoder decodeObject]];
         [self setCommuteSaturdayEndValue:[decoder decodeObject]];
         [self setCommuteSundayStartValue:[decoder decodeObject]];
         [self setCommuteSundayEndValue:[decoder decodeObject]];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setConsiderAdjacentTripsNotCommutable:tempBool];
		 // commuting select
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setCommuteSelectsByCommutesRequired:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
         [self setCommuteSelectsByCommutesRequiredTrigger:tempInt];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setCommuteSelectsByOvernightsInDomicile:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
         [self setCommuteSelectsByOvernightsInDomicileTrigger:tempInt];
		 // commuting points
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setCommuteAssignsPointsForCommutesRequired:tempBool];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setCommutePointsForCommutesRequired:tempFloat];
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
         [self setCommuteAssignsPointsForOvernightsInDomicile:tempBool];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
         [self setCommutePointsForOvernightsInDomicile:tempFloat];
      }
      // decode only if version > 6
      if (version > 6) {
		 // max legs per day select
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		 [self setMaxLegsPerDaySelectCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
		 [self setMaxLegsPerDaySelectTriggerValue:tempInt];
		 // max legs per day less than or equal points
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		 [self setMaxLegsPerDayLessThanOrEqualPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
		 [self setMaxLegsPerDayLessThanOrEqualPointsTriggerValue:tempInt];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
		 [self setMaxLegsPerDayLessThanOrEqualPointsValue:tempFloat];
		 // max legs per day greater than points
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		 [self setMaxLegsPerDayGreaterThanPointsCheckboxValue:tempBool];
         [decoder decodeValueOfObjCType:@encode(int) at:&tempInt];
		 [self setMaxLegsPerDayGreaterThanPointsTriggerValue:tempInt];
         [decoder decodeValueOfObjCType:@encode(float) at:&tempFloat];
		 [self setMaxLegsPerDayGreaterThanPointsValue:tempFloat];
	  }
   }
   // set derived values
   [self initializeDerivedValues];
   // update any new sort selections that have been added since this data
   // model was archived
//   [self addNewSortSelections];
   // enable undo
   [[self undoManager] enableUndoRegistration];
   // enable sorting
   [self setSortingEnabled:YES];
   
   return self;
}

- (NSArray *)stringSortSelectionsWithDictionarySortSelections:(NSArray *)sortSelections
{
   NSMutableArray *newSortSelections = nil;
   unsigned count = 0;
   unsigned index = 0;
   id sortSelection = nil;
   NSString *sortTitle = nil;
   
   newSortSelections = [sortSelections mutableCopy];
   // convert sort selections from NSDictionary to NSString, if sort selections
   // are in old data model format
   count = [newSortSelections count];
   for (index = 0; index < count; index++)
   {
      sortSelection = [newSortSelections objectAtIndex:index];
      if (![sortSelection respondsToSelector:@selector(caseInsensitiveCompare:)])
      {
         sortTitle = [(NSDictionary *)sortSelection objectForKey:CBDataModelSortSelectionTitleKey];
         [newSortSelections replaceObjectAtIndex:index withObject:sortTitle];
      }
   }
   return [NSArray arrayWithArray:newSortSelections];
}

- (void)saveChoices:(NSString *)path
{
   NSString * choicesFilePath = nil;
   NSDictionary * choices = nil;
   NSFileManager * fileManager = nil;
   
   choicesFilePath = [path stringByAppendingPathExtension:@"plist"];
   
   choices = [NSDictionary dictionaryWithObjectsAndKeys:
      // sort selections
      [self availableSortSelections], CBDataModelAvailableSortSelectionsKey,
      [self inUseSortSelections], CBDataModelInUseSortSelectionsKey,
      // points
      [NSNumber numberWithBool:[self linePointsIncludePay]], CBDataModelLinePointsIncludePayCheckboxValueKey,
      // reserve/blank lines to bottom
      [NSNumber numberWithBool:[self reserveLinesToBottomCheckboxValue]], CBDataModelReserveLinesToBottomCheckboxValueKey,
      [NSNumber numberWithBool:[self blankLinesToBottomCheckboxValue]], CBDataModelBlankLinesToBottomCheckboxValueKey,
      // aircraft changes
      [NSNumber numberWithBool:[self aircraftChangesSelectCheckboxValue]], CBDataModelAircraftChangesSelectCheckboxValueKey,
      [NSNumber numberWithInt:[self aircraftChangesSelectTriggerValue]], CBDataModelAircraftChangesSelectTriggerValueKey,
      [NSNumber numberWithBool:[self aircraftChangesPointsCheckboxValue]], CBDataModelAircraftChangesPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self aircraftChangesPointsValue]], CBDataModelAircraftChangesPointsValueKey,
      // am/pm
      [NSNumber numberWithBool:[self amSelectCheckboxValue]], CBDataModelAmSelectCheckboxValueKey,
      [NSNumber numberWithBool:[self pmSelectCheckboxValue]], CBDataModelPmSelectCheckboxValueKey,
      [NSNumber numberWithBool:[self amPointsCheckboxValue]], CBDataModelAmPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self amPointsValue]], CBDataModelAmPointsValueKey,
      [NSNumber numberWithBool:[self pmPointsCheckboxValue]], CBDataModelPmPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self pmPointsValue]], CBDataModelPmPointsValueKey,
      // turns
      [NSNumber numberWithBool:[self turnSelectCheckboxValue]], CBDataModelTurnSelectCheckboxValueKey,
      [NSNumber numberWithInt:[self turnSelectTriggerValue]], CBDataModelTurnSelectTriggerValueKey,
      [NSNumber numberWithBool:[self turnPointsCheckboxValue]], CBDataModelTurnPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self turnPointsValue]], CBDataModelTurnPointsValueKey,
      // two-days
      [NSNumber numberWithBool:[self twoDaySelectCheckboxValue]], CBDataModelTwoDaySelectCheckboxValueKey,
      [NSNumber numberWithInt:[self twoDaySelectTriggerValue]], CBDataModelTwoDaySelectTriggerValueKey,
      [NSNumber numberWithBool:[self twoDayPointsCheckboxValue]], CBDataModelTwoDayPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self twoDayPointsValue]], CBDataModelTwoDayPointsValueKey,
      // three-days
      [NSNumber numberWithBool:[self threeDaySelectCheckboxValue]], CBDataModelThreeDaySelectCheckboxValueKey,
      [NSNumber numberWithInt:[self threeDaySelectTriggerValue]], CBDataModelThreeDaySelectTriggerValueKey,
      [NSNumber numberWithBool:[self threeDayPointsCheckboxValue]], CBDataModelThreeDayPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self threeDayPointsValue]], CBDataModelThreeDayPointsValueKey,
      // four-days
      [NSNumber numberWithBool:[self fourDaySelectCheckboxValue]], CBDataModelFourDaySelectCheckboxValueKey,
      [NSNumber numberWithInt:[self fourDaySelectTriggerValue]], CBDataModelFourDaySelectTriggerValueKey,
      [NSNumber numberWithBool:[self fourDayPointsCheckboxValue]], CBDataModelFourDayPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self fourDayPointsValue]], CBDataModelFourDayPointsValueKey,
      // days of month
      //
      // save days of week values only since days of month select and points
      // values are most likely inapropriate for the new month
      //
      // save days of week select values as array so that it may be written to
      // file as NSDictionary method (NSDictionary won't write an NSSet to file
      //
      // save days of week points values as NSDictionary(s) with string keys
      // since NSDictionary won't save NSNumber keys to file
      [NSNumber numberWithBool:[self daysOfMonthSelectCheckboxValue]], CBDataModelDaysOfMonthSelectCheckboxValueKey,
      [NSNumber numberWithBool:[self daysOfMonthPointsCheckboxValue]], CBDataModelDaysOfMonthPointsCheckboxValueKey,
      [[self daysOfWeekSelectValues] allObjects], CBDataModelDaysOfWeekSelectValuesKey,
      [self stringKeysDictionaryWithNumberKeysDictionary:[self daysOfWeekPointsValues]], CBDataModelDaysOfWeekPointsValuesKey,
      // overnight cities
      [NSNumber numberWithInt:[self overnightCitiesSelectMatrixValue]], CBDataModelOvernightCitiesSelectMatrixValueKey,
      [[self overnightCitiesSelectValues] allObjects], CBDataModelOvernightCitiesSelectValuesKey,
      [NSNumber numberWithBool:[self overnightCitiesPointsCheckboxValue]], CBDataModelOvernightCitiesPointsCheckboxValueKey,
      [self overnightCitiesPointsValues], CBDataModelOvernightCitiesPointsValuesKey,
      // overlap
      [NSNumber numberWithBool:[self noOverlapSelectCheckboxValue]], CBDataModelNoOverlapSelectCheckboxValueKey,
      [NSNumber numberWithBool:[self noOverlapPointsCheckboxValue]], CBDataModelNoOverlapPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self noOverlapPointsValue]], CBDataModelNoOverlapPointsValueKey,
      [NSNumber numberWithBool:[self overlapPointsCheckboxValue]], CBDataModelOverlapPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self overlapPointsValue]], CBDataModelOverlapPointsValueKey,
      // block of days off
      [NSNumber numberWithBool:[self blockOfDaysOffSelectCheckboxValue]], CBDataModelBlockOfDaysOffSelectCheckboxValueKey,
      [NSNumber numberWithInt:[self blockOfDaysOffSelectTriggerValue]], CBDataModelBlockOfDaysOffSelectTriggerValueKey,
      [NSNumber numberWithBool:[self blockOfDaysOffPointsCheckboxValue]], CBDataModelBlockOfDaysOffPointsCheckboxValueKey,
      [NSNumber numberWithInt:[self blockOfDaysOffPointsTriggerValue]], CBDataModelBlockOfDaysOffPointsTriggerValueKey,
      [NSNumber numberWithFloat:[self blockOfDaysOffPointsValue]], CBDataModelBlockOfDaysOffPointsValueKey,
	  // Deadheads
	  [NSNumber numberWithBool:[self deadheadAtStartSelectCheckboxValue]], CBDataModelDeadheadAtStartCheckboxValueKey,
      [self deadheadAtStartCity], CBDataModelDeadheadAtStartCityKey,
      [NSNumber numberWithBool:[self deadheadAtStartPointsCheckboxValue]], CBDataModelDeadheadAtStartPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self deadheadAtStartPointsValue]], CBDataModelDeadheadAtStartPointsValueKey,
	  [NSNumber numberWithBool:[self deadheadAtEndSelectCheckboxValue]], CBDataModelDeadheadAtEndCheckboxValueKey,
      [self deadheadAtEndCity], CBDataModelDeadheadAtEndCityKey,
      [NSNumber numberWithBool:[self deadheadAtEndPointsCheckboxValue]], CBDataModelDeadheadAtEndPointsCheckboxValueKey,
      [NSNumber numberWithFloat:[self deadheadAtEndPointsValue]], CBDataModelDeadheadAtEndPointsValueKey,
	  // Commute times
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteWeekdayStartValue]], CBDataModelCommuteWeekdayStartValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteFridayStartValue]], CBDataModelCommuteFridayStartValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteSaturdayStartValue]], CBDataModelCommuteSaturdayStartValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteSundayStartValue]], CBDataModelCommuteSundayStartValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteWeekdayEndValue]], CBDataModelCommuteWeekdayEndValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteFridayEndValue]], CBDataModelCommuteFridayEndValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteSaturdayEndValue]], CBDataModelCommuteSaturdayEndValueKey,
	  [NSKeyedArchiver archivedDataWithRootObject:[self commuteSundayEndValue]], CBDataModelCommuteSundayEndValueKey,
      // Commuting select
      [NSNumber numberWithInt:[self commuteSelectsByCommutesRequiredTrigger]], CBDataModelCommuteSelectsByCommutesRequiredTriggerKey,
      [NSNumber numberWithBool:[self commuteSelectsByCommutesRequired]], CBDataModelCommuteSelectsByCommutesRequiredKey,
      [NSNumber numberWithInt:[self commuteSelectsByOvernightsInDomicileTrigger]], CBDataModelCommuteSelectsByOvernightsInDomicileTriggerKey,
      [NSNumber numberWithBool:[self commuteSelectsByOvernightsInDomicile]], CBDataModelCommuteSelectsByOvernightsInDomicileKey,
      // Commuting points
      [NSNumber numberWithBool:[self commuteAssignsPointsForCommutesRequired]], CBDataModelCommuteAssignsPointsForCommutesRequiredKey,
      [NSNumber numberWithFloat:[self commutePointsForCommutesRequired]], CBDataModelCommutePointsForCommutesRequiredKey,
      [NSNumber numberWithBool:[self commuteAssignsPointsForOvernightsInDomicile]], CBDataModelCommuteAssignsPointsForOvernightsInDomicileKey,
      [NSNumber numberWithFloat:[self commutePointsForOvernightsInDomicile]], CBDataModelCommutePointsForOvernightsInDomicileKey,
	  // Max legs per day select
	  [NSNumber numberWithBool:[self maxLegsPerDaySelectCheckboxValue]],
		  CBDataModelMaxLegsPerDaySelectCheckboxValueKey,
	  [NSNumber numberWithInt:[self maxLegsPerDaySelectTriggerValue]],
		  CBDataModelMaxLegsPerDaySelectTriggerValueKey,
	  // Max legs per day less than or equal points
	  [NSNumber numberWithBool:[self maxLegsPerDayLessThanOrEqualPointsCheckboxValue]],
		  CBDataModelMaxLegsPerDayLessThanOrEqualPointsCheckboxValueKey,
	  [NSNumber numberWithInt:[self maxLegsPerDayLessThanOrEqualPointsTriggerValue]],
		  CBDataModelMaxLegsPerDayLessThanOrEqualPointsTriggerValueKey,
	  [NSNumber numberWithFloat:[self maxLegsPerDayLessThanOrEqualPointsValue]],
		  CBDataModelMaxLegsPerDayLessThanOrEqualPointsValueKey,
	  // Max legs per day greater than points
	  [NSNumber numberWithBool:[self maxLegsPerDayGreaterThanPointsCheckboxValue]],
		  CBDataModelMaxLegsPerDayGreaterThanPointsCheckboxValueKey,
	  [NSNumber numberWithInt:[self maxLegsPerDayGreaterThanPointsTriggerValue]],
		  CBDataModelMaxLegsPerDayGreaterThanPointsTriggerValueKey,
	  [NSNumber numberWithFloat:[self maxLegsPerDayGreaterThanPointsValue]],
		  CBDataModelMaxLegsPerDayGreaterThanPointsValueKey,
      nil];

   if ([choices writeToFile:choicesFilePath atomically:NO])
   {
      fileManager = [NSFileManager defaultManager];
       [fileManager setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden] ofItemAtPath:choicesFilePath error:NULL];
   }
   else
   {
      // raise exceoption
      NSLog(@"choices dictionary NOT written to file");
   }
}

- (void)applyChoices:(NSString *)path
{
   NSDictionary * choices = nil;
   
   if ((choices = [NSDictionary dictionaryWithContentsOfFile:path]))
   {
      // sort selections
		[self saveSortSelectionsUsingChoices:choices];
      // points
      [self setLinePointsIncludePay:[[choices objectForKey:CBDataModelLinePointsIncludePayCheckboxValueKey] boolValue]];
      // reserve/blank lines to bottom
      [self setReserveLinesToBottomCheckboxValue:[[choices objectForKey:CBDataModelReserveLinesToBottomCheckboxValueKey] boolValue]];
      [self setBlankLinesToBottomCheckboxValue:[[choices objectForKey:CBDataModelBlankLinesToBottomCheckboxValueKey] boolValue]];
      // aircraft changes
      [self setAircraftChangesSelectCheckboxValue:[[choices objectForKey:CBDataModelAircraftChangesSelectCheckboxValueKey] boolValue]];
      [self setAircraftChangesSelectTriggerValue:[[choices objectForKey:CBDataModelAircraftChangesSelectTriggerValueKey] intValue]];
      [self setAircraftChangesPointsCheckboxValue:[[choices objectForKey:CBDataModelAircraftChangesPointsCheckboxValueKey] boolValue]];
      [self setAircraftChangesPointsValue:[[choices objectForKey:CBDataModelAircraftChangesPointsValueKey] floatValue]];
      // am/pm
      [self setAmSelectCheckboxValue:[[choices objectForKey:CBDataModelAmSelectCheckboxValueKey] boolValue]];
      [self setPmSelectCheckboxValue:[[choices objectForKey:CBDataModelPmSelectCheckboxValueKey] boolValue]];
      [self setAmPointsCheckboxValue:[[choices objectForKey:CBDataModelAmPointsCheckboxValueKey] boolValue]];
      [self setAmPointsValue:[[choices objectForKey:CBDataModelAmPointsValueKey] floatValue]];
      [self setPmPointsCheckboxValue:[[choices objectForKey:CBDataModelPmPointsCheckboxValueKey] boolValue]];
      [self setPmPointsValue:[[choices objectForKey:CBDataModelPmPointsValueKey] floatValue]];
      // turns
      [self setTurnSelectCheckboxValue:[[choices objectForKey:CBDataModelTurnSelectCheckboxValueKey] boolValue]];
      [self setTurnSelectTriggerValue:[[choices objectForKey:CBDataModelTurnSelectTriggerValueKey] intValue]];
      [self setTurnPointsCheckboxValue:[[choices objectForKey:CBDataModelTurnPointsCheckboxValueKey] boolValue]];
      [self setTurnPointsValue:[[choices objectForKey:CBDataModelTurnPointsValueKey] floatValue]];
      // two-days
      [self setTwoDaySelectCheckboxValue:[[choices objectForKey:CBDataModelTwoDaySelectCheckboxValueKey] boolValue]];
      [self setTwoDaySelectTriggerValue:[[choices objectForKey:CBDataModelTwoDaySelectTriggerValueKey] intValue]];
      [self setTwoDayPointsCheckboxValue:[[choices objectForKey:CBDataModelTwoDayPointsCheckboxValueKey] boolValue]];
      [self setTwoDayPointsValue:[[choices objectForKey:CBDataModelTwoDayPointsValueKey] floatValue]];
      // three-days
      [self setThreeDaySelectCheckboxValue:[[choices objectForKey:CBDataModelThreeDaySelectCheckboxValueKey] boolValue]];
      [self setThreeDaySelectTriggerValue:[[choices objectForKey:CBDataModelThreeDaySelectTriggerValueKey] intValue]];
      [self setThreeDayPointsCheckboxValue:[[choices objectForKey:CBDataModelThreeDayPointsCheckboxValueKey] boolValue]];
      [self setThreeDayPointsValue:[[choices objectForKey:CBDataModelThreeDayPointsValueKey] floatValue]];
      // four-days
      [self setFourDaySelectCheckboxValue:[[choices objectForKey:CBDataModelFourDaySelectCheckboxValueKey] boolValue]];
      [self setFourDaySelectTriggerValue:[[choices objectForKey:CBDataModelFourDaySelectTriggerValueKey] intValue]];
      [self setFourDayPointsCheckboxValue:[[choices objectForKey:CBDataModelFourDayPointsCheckboxValueKey] boolValue]];
      [self setFourDayPointsValue:[[choices objectForKey:CBDataModelFourDayPointsValueKey] floatValue]];
      // days of month
      //
      // set days of week only since days of month select and points values
      // are most likely inappropriate for the new month
      //
      // days of week select values are saved as an NSArray since NSDictionary
      // won't write an NSSet to file
      //
      // days of week points values are saved with NSString keys instead of
      // NSNumber keys since NSDictionary won't write NSNumber keys to file
      [self setDaysOfWeekSelectValues:[NSSet setWithArray:[choices objectForKey:CBDataModelDaysOfWeekSelectValuesKey]]];
      [self setDaysOfWeekPointsValues:[self numberKeysDictionaryWithStringKeysDictionary:[choices objectForKey:CBDataModelDaysOfWeekPointsValuesKey]]];
      [self setDaysOfMonthSelectCheckboxValue:[[choices objectForKey:CBDataModelDaysOfMonthSelectCheckboxValueKey] boolValue]];
      [self setDaysOfMonthPointsCheckboxValue:[[choices objectForKey:CBDataModelDaysOfMonthPointsCheckboxValueKey] boolValue]];
      // overnight cities
      [self setOvernightCitiesSelectMatrixValue:[[choices objectForKey:CBDataModelOvernightCitiesSelectMatrixValueKey] intValue]];
      [self setOvernightCitiesSelectValues:[NSSet setWithArray:[choices objectForKey:CBDataModelOvernightCitiesSelectValuesKey]]];
      [self setOvernightCitiesPointsCheckboxValue:[[choices objectForKey:CBDataModelOvernightCitiesPointsCheckboxValueKey] boolValue]];
      [self setOvernightCitiesPointsValues:[choices objectForKey:CBDataModelOvernightCitiesPointsValuesKey]];
      // overlap
      [self setNoOverlapSelectCheckboxValue:[[choices objectForKey:CBDataModelNoOverlapSelectCheckboxValueKey] boolValue]];
      [self setNoOverlapPointsCheckboxValue:[[choices objectForKey:CBDataModelNoOverlapPointsCheckboxValueKey] boolValue]];
      [self setNoOverlapPointsValue:[[choices objectForKey:CBDataModelNoOverlapPointsValueKey] floatValue]];
      [self setOverlapPointsCheckboxValue:[[choices objectForKey:CBDataModelOverlapPointsCheckboxValueKey] boolValue]];
      [self setOverlapPointsValue:[[choices objectForKey:CBDataModelOverlapPointsValueKey] floatValue]];
      // block of days off
      [self setBlockOfDaysOffSelectCheckboxValue:[[choices objectForKey:CBDataModelBlockOfDaysOffSelectCheckboxValueKey] boolValue]];
      [self setBlockOfDaysOffSelectTriggerValue:[[choices objectForKey:CBDataModelBlockOfDaysOffSelectTriggerValueKey] intValue]];
      [self setBlockOfDaysOffPointsCheckboxValue:[[choices objectForKey:CBDataModelBlockOfDaysOffPointsCheckboxValueKey] intValue]];
      [self setBlockOfDaysOffPointsTriggerValue:[[choices objectForKey:CBDataModelBlockOfDaysOffPointsTriggerValueKey] intValue]];
      [self setBlockOfDaysOffPointsValue:[[choices objectForKey:CBDataModelBlockOfDaysOffPointsValueKey] intValue]];
      // Deadheads
      [self setDeadheadAtStartSelectCheckboxValue:[[choices objectForKey:CBDataModelDeadheadAtStartCheckboxValueKey] boolValue]];
      [self setDeadheadAtStartCity:[choices objectForKey:CBDataModelDeadheadAtStartCityKey]];
      [self setDeadheadAtStartPointsCheckboxValue:[[choices objectForKey:CBDataModelDeadheadAtStartPointsCheckboxValueKey] boolValue]];
      [self setDeadheadAtStartPointsValue:[[choices objectForKey:CBDataModelDeadheadAtStartPointsValueKey] floatValue]];
      [self setDeadheadAtEndSelectCheckboxValue:[[choices objectForKey:CBDataModelDeadheadAtEndCheckboxValueKey] boolValue]];
      [self setDeadheadAtEndCity:[choices objectForKey:CBDataModelDeadheadAtEndCityKey]];
      [self setDeadheadAtEndPointsCheckboxValue:[[choices objectForKey:CBDataModelDeadheadAtEndPointsCheckboxValueKey] boolValue]];
      [self setDeadheadAtEndPointsValue:[[choices objectForKey:CBDataModelDeadheadAtEndPointsValueKey] floatValue]];
      // Commute Times
      [self setCommuteWeekdayStartValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteWeekdayStartValueKey]]];
      [self setCommuteFridayStartValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteFridayStartValueKey]]];
      [self setCommuteSaturdayStartValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteSaturdayStartValueKey]]];
      [self setCommuteSundayStartValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteSundayStartValueKey]]];
      [self setCommuteWeekdayEndValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteWeekdayEndValueKey]]];
      [self setCommuteFridayEndValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteFridayEndValueKey]]];
      [self setCommuteSaturdayEndValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteSaturdayEndValueKey]]];
      [self setCommuteSundayEndValue:[NSKeyedUnarchiver unarchiveObjectWithData:[choices objectForKey:CBDataModelCommuteSundayEndValueKey]]];
      // Commuting select
      [self setCommuteSelectsByCommutesRequiredTrigger:[[choices objectForKey:CBDataModelCommuteSelectsByCommutesRequiredTriggerKey] intValue]];
      [self setCommuteSelectsByCommutesRequired:[[choices objectForKey:CBDataModelCommuteSelectsByCommutesRequiredKey] boolValue]];
      [self setCommuteSelectsByOvernightsInDomicileTrigger:[[choices objectForKey:CBDataModelCommuteSelectsByOvernightsInDomicileTriggerKey] intValue]];
      [self setCommuteSelectsByOvernightsInDomicile:[[choices objectForKey:CBDataModelCommuteSelectsByOvernightsInDomicileKey] boolValue]];
      // Commuting points
      [self setCommutePointsForCommutesRequired:[[choices objectForKey:CBDataModelCommutePointsForCommutesRequiredKey] floatValue]];
      [self setCommuteAssignsPointsForCommutesRequired:[[choices objectForKey:CBDataModelCommuteAssignsPointsForCommutesRequiredKey] boolValue]];
      [self setCommutePointsForOvernightsInDomicile:[[choices objectForKey:CBDataModelCommutePointsForOvernightsInDomicileKey] floatValue]];
      [self setCommuteAssignsPointsForOvernightsInDomicile:[[choices objectForKey:CBDataModelCommuteAssignsPointsForOvernightsInDomicileKey] boolValue]];
	  // Max legs per day select
	  [self setMaxLegsPerDaySelectCheckboxValue:[[choices objectForKey:CBDataModelMaxLegsPerDaySelectCheckboxValueKey] boolValue]];
	  [self setMaxLegsPerDaySelectTriggerValue:[[choices objectForKey:CBDataModelMaxLegsPerDaySelectTriggerValueKey] intValue]];
	  // Max legs per day less than or eauql points
	  [self setMaxLegsPerDayLessThanOrEqualPointsCheckboxValue:[[choices objectForKey:CBDataModelMaxLegsPerDayLessThanOrEqualPointsCheckboxValueKey] boolValue]];
	  [self setMaxLegsPerDayLessThanOrEqualPointsTriggerValue:[[choices objectForKey:CBDataModelMaxLegsPerDayLessThanOrEqualPointsTriggerValueKey] intValue]];
	  [self setMaxLegsPerDayLessThanOrEqualPointsValue:[[choices objectForKey:CBDataModelMaxLegsPerDayLessThanOrEqualPointsValueKey] floatValue]];
	  // Max legs per day greter than points
	  [self setMaxLegsPerDayGreaterThanPointsCheckboxValue:[[choices objectForKey:CBDataModelMaxLegsPerDayGreaterThanPointsCheckboxValueKey] boolValue]];
	  [self setMaxLegsPerDayGreaterThanPointsTriggerValue:[[choices objectForKey:CBDataModelMaxLegsPerDayGreaterThanPointsTriggerValueKey] intValue]];
	  [self setMaxLegsPerDayGreaterThanPointsValue:[[choices objectForKey:CBDataModelMaxLegsPerDayGreaterThanPointsValueKey] floatValue]];
   }
   else
   {
      // raise exception
      NSLog(@"could not read choices file \"%@\"", path);
   }
}

// methods that convert non-string keys to strings and vice versa
- (NSDictionary *)stringKeysDictionaryWithNumberKeysDictionary:(NSDictionary *)numberKeysDictionary
{
   NSMutableDictionary *stringKeysDictionary = [NSMutableDictionary dictionaryWithCapacity:[numberKeysDictionary count]];
   NSEnumerator *numberKeysEnumerator = [[numberKeysDictionary allKeys] objectEnumerator];
   NSNumber *numberKey = nil;
   while (numberKey = [numberKeysEnumerator nextObject])
   {
      [stringKeysDictionary setObject:[numberKeysDictionary objectForKey:numberKey] forKey:[numberKey stringValue]];
   }
   return [NSDictionary dictionaryWithDictionary:stringKeysDictionary];
}

- (NSDictionary *)numberKeysDictionaryWithStringKeysDictionary:(NSDictionary *)stringKeysDictionary
{
   NSMutableDictionary *numberKeysDictionary = [NSMutableDictionary dictionaryWithCapacity:[stringKeysDictionary count]];
   NSEnumerator *stringKeysEnumerator = [[stringKeysDictionary allKeys] objectEnumerator];
   NSString *numberStringKey = nil;
   while (numberStringKey = [stringKeysEnumerator nextObject])
   {
      [numberKeysDictionary setObject:[stringKeysDictionary objectForKey:numberStringKey] forKey:[NSNumber numberWithInt:[numberStringKey intValue]]];
   }
   return [NSDictionary dictionaryWithDictionary:numberKeysDictionary];
}

// save sort selections, adding sort selections from current data model that
// don't exist in sort selections being applied
- (void)saveSortSelectionsUsingChoices:(NSDictionary *)choices
{
   NSMutableArray *allCurrentSortSelections = nil;
   NSMutableArray *appliedAvailableSortSelections = nil;
   NSArray *appliedInUseSortSelections = nil;
   NSEnumerator * e = nil;
   NSString *sortSelection = nil;
   
   allCurrentSortSelections = [[self sortSelectionsArray] mutableCopy];
   appliedAvailableSortSelections = [[choices objectForKey:CBDataModelAvailableSortSelectionsKey] mutableCopy];
   appliedInUseSortSelections = [choices objectForKey:CBDataModelInUseSortSelectionsKey];

   // available
   e = [appliedAvailableSortSelections objectEnumerator];
   while (sortSelection = [e nextObject])
   {
      [allCurrentSortSelections removeObject:sortSelection];
   }

   // in use
   e = [appliedInUseSortSelections objectEnumerator];
   while (sortSelection = [e nextObject])
   {
      [allCurrentSortSelections removeObject:sortSelection];
   }
   
   // add current sort selections that aren't in applied sort selections
   [appliedAvailableSortSelections addObjectsFromArray:allCurrentSortSelections];
   // set available and in use sort selections
   [self setAvailableSortSelections:[NSArray arrayWithArray:appliedAvailableSortSelections]];
   [self setInUseSortSelections:[NSArray arrayWithArray:appliedInUseSortSelections]];
}

#pragma mark INTERFACE ITEM NOTIFICATIONS

- (NSString *)notificationNameForIdentifier:(NSString *)identifier
{
	NSString * notificationName = [NSString stringWithFormat:@"%@ %@ changed notification", [self class], identifier];
	return notificationName;
}

- (void)postNotificationForIdentifier:(NSString *)identifier value:(id)value
{
	NSString * notificationName = [self notificationNameForIdentifier:identifier];
	[[NSNotificationCenter defaultCenter]
	postNotificationName:notificationName
	object:[self document]
	userInfo:[NSDictionary dictionaryWithObject:value
	forKey:notificationName]];
}
#pragma mark NIL VALUES

- (void)unableToSetNilForKey:(NSString *)key
{
   const int DEFAULT_TRIGGER_VALUE = 0;
   const float DEFAULT_POINTS_VALUE = 0.0;
   NSNumber * defaultValue = nil;
   
   if (NSNotFound != [key rangeOfString:@"Trigger"].location) {
      defaultValue = [NSNumber numberWithInt:DEFAULT_TRIGGER_VALUE];
   } else if (NSNotFound != [key rangeOfString:@"Points"].location) {
      defaultValue = [NSNumber numberWithFloat:DEFAULT_POINTS_VALUE];
   }
   [self takeValue:defaultValue forKey:key];
}

#pragma mark DERIVED ACCESSORS

- (BOOL)isFlightAttendantBid
{
   return [[self crewPosition] isEqualToString:@"Flight Attendant"];
}

- (BOOL)isFlightAttendantFirstRoundBid
{
   return [self isFlightAttendantBid] && 1 == [self bidRound];
}

- (BOOL)isPilotSecondRoundBid
{
    BOOL isPilotSecondRoundBid = 
        [[[self bidPeriod] round] intValue] == 2 &&
        ![[[self bidPeriod] position] isEqualToString:CSFlightAttendant];
    return isPilotSecondRoundBid;
}

#pragma mark CALENDAR METHODS

- (NSCalendarDate *)firstBidDate
{
	if (nil == firstBidDate) {
		NSArray *lineTripDicts = [[self lines] valueForKeyPath:@"@unionOfArrays.trips"];
		NSNumber *minTripStartDay = [lineTripDicts valueForKeyPath:[@"@min" stringByAppendingPathExtension:CBLineTripDateKey]];
		int firstBidDateOffset = [minTripStartDay intValue];
		if (firstBidDateOffset < 1) {
			firstBidDate = [[[self month] dateByAddingYears:0 months:0 days:firstBidDateOffset - 1 hours:0 minutes:0 seconds:0] retain];
		} else {
			firstBidDate = [[self month] copy];
		}
	}
	return firstBidDate;
}

- (NSCalendarDate *)firstCalendarDate
{
	if (nil == firstCalendarDate) {
		firstCalendarDate = [[[self firstBidDate] dateByAddingYears:0 months:0 days:-[[self firstBidDate] dayOfWeek] hours:0 minutes:0 seconds:0] retain];
	}
	return firstCalendarDate;
}

- (int)calendarOffset
{
	[[self month] years:NULL months:NULL days:&calendarOffset hours:NULL minutes:NULL seconds:NULL sinceDate:[self firstCalendarDate]];
	calendarOffset--;
	return calendarOffset;
}

- (NSCalendarDate *)lastBidDate
{
	if (nil == lastBidDate) {
		NSArray *lineTripDicts = [[self lines] valueForKeyPath:@"@unionOfArrays.trips"];
		int lastBidDateOffset = 0;
		NSEnumerator *tripDictEnum = [lineTripDicts objectEnumerator];
		NSDictionary *tripDict = nil;
		while (tripDict = [tripDictEnum nextObject]) {
			int tripStartDay = [[tripDict objectForKey:CBLineTripDateKey] intValue];
			CBTrip *trip = [[self trips] objectForKey:[tripDict objectForKey:CBLineTripNumberKey]];
			int tripLength = [trip dutyPeriods];
			int tripOffset = tripStartDay + tripLength - 1; 
			if (tripOffset > lastBidDateOffset) {
				lastBidDateOffset = tripOffset;
			}
		}
		lastBidDate = [[[self month] dateByAddingYears:0 months:0 days:lastBidDateOffset - 1 hours:0 minutes:0 seconds:0] retain];
	}
	return lastBidDate;
}

#pragma mark ACCESSORS

- (CBDocument *)document { return document; }
- (void)setDocument:(CBDocument *)inValue { document = inValue; }

- (NSCalendarDate *)month { return month; }
- (void)setMonth:(NSCalendarDate *)inValue
{
   if (month != inValue) {
      [month release];
      month = [inValue copy];
   }
}

- (NSUndoManager *)undoManager
{
   return [[self document] undoManager];
}

- (NSString *)crewBase { return crewBase; }
- (void)setCrewBase:(NSString *)inValue
{
   if (crewBase != inValue) {
      [crewBase release];
      crewBase = [inValue copy];
   }
}

- (NSString *)crewPosition { return crewPosition; }
- (void)setCrewPosition:(NSString *)inValue
{
   if (crewPosition != inValue) {
      [crewPosition release];
      crewPosition = [inValue copy];
   }
}

- (int)bidRound { return bidRound; }
- (void)setBidRound:(int)inValue
{
   bidRound = inValue;
}

- (NSArray *)lines { return lines; }
- (void)setLines:(NSArray *)inValue
{
   if (lines != inValue) {
      [lines release];
      lines = [inValue retain];
      // undo
      
      // TEMP CODE
      [[self document] updateChangeCount:NSChangeDone];

      // post notification
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelLinesChangedNotification object:[self document] userInfo:[NSDictionary dictionaryWithObject:lines forKey:CBDataModelLinesChangedNotification]];
   }
}

- (NSDictionary *)trips { return trips; }
- (void)setTrips:(NSDictionary *)inValue
{
   if (trips != inValue) {
      [trips release];
      trips = [inValue retain];
   }
}

- (CSBidPeriod *)bidPeriod 
{
    if (!bidPeriod)
    {
        NSDictionary *bidPeriodValues = [NSDictionary dictionaryWithObjectsAndKeys:
            [self month], @"month",
            [self crewBase], @"base",
            [self crewPosition], @"position",
            [NSNumber numberWithInt:[self bidRound]], @"round", nil];
        [self setBidPeriod:[CSBidPeriod bidPeriodForObject:bidPeriodValues]];
    }
    return bidPeriod;
}

- (void)setBidPeriod:(CSBidPeriod *)value {
    if (bidPeriod != value) {
        [bidPeriod release];
        bidPeriod = [value copy];
    }
}

- (BOOL)sortingEnabled { return sortingEnabled; }
- (void)setSortingEnabled:(BOOL)inValue { sortingEnabled = inValue; }

// derived
- (NSArray *)overnightCities  { return overnightCities; }
- (void)setOvernightCities:(NSArray *)inValue
{
   if (overnightCities != inValue) {
      [overnightCities release];
      overnightCities = [inValue retain];
   }
}

// top/bottom freeze
- (int)topFreezeIndex { return topFreezeIndex; }
- (void)setTopFreezeIndex:(int)inValue
{
   topFreezeIndex = inValue;
   if (bottomFreezeIndex <= topFreezeIndex) {
      bottomFreezeIndex = topFreezeIndex + 1;
   }
   if (sortingEnabled) {
      [self sortLines];
      // post notification
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelLinesChangedNotification object:[self document] userInfo:[NSDictionary dictionaryWithObject:[self lines] forKey:CBDataModelLinesChangedNotification]];
   }
}

- (int)bottomFreezeIndex { return bottomFreezeIndex; }
- (void)setBottomFreezeIndex:(int)inValue
{
   bottomFreezeIndex = inValue;
   if (topFreezeIndex >= bottomFreezeIndex) {
      topFreezeIndex = bottomFreezeIndex - 1;
   }
   if (sortingEnabled) {
      [self sortLines];
      // post notification
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelLinesChangedNotification object:[self document] userInfo:[NSDictionary dictionaryWithObject:[self lines] forKey:CBDataModelLinesChangedNotification]];
   }
}

// sort selections
- (NSArray *)availableSortSelections { return availableSortSelections; }
- (void)setAvailableSortSelections:(NSArray *)inValue
{
   if (availableSortSelections != inValue) {
      [availableSortSelections release];
      availableSortSelections = [[[inValue mutableCopy] sortedArrayUsingFunction:compareSortSelection context:nil] copy];
      // post notification
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelSortSelectionsChangedNotification object:[self document] userInfo:[NSDictionary dictionaryWithObject:availableSortSelections forKey:CBDataModelSortSelectionsChangedNotification]];
   }
}

- (NSArray *)inUseSortSelections { return inUseSortSelections; }
- (void)setInUseSortSelections:(NSArray *)inValue
{
   if (inUseSortSelections != inValue) {
      [inUseSortSelections release];
      inUseSortSelections = [inValue copy];
      // post notification
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelSortSelectionsChangedNotification object:[self document] userInfo:[NSDictionary dictionaryWithObject:inUseSortSelections forKey:CBDataModelSortSelectionsChangedNotification]];
      // sort lines
      if (sortingEnabled) {
         [self sortLines];
      }
   }
}

// FA positions
- (NSMutableArray *)faPositions { return faPositions; }
- (void)setFaPositions:(NSArray *)inValue
{
   if (![faPositions isEqualToArray:inValue])
   {
      [faPositions release];
      faPositions = [inValue mutableCopy];
      [[NSNotificationCenter defaultCenter] postNotificationName:CBDataModelFaPositionValuesChangedNotification object:[self document] userInfo:[NSDictionary dictionaryWithObject:faPositions forKey:CBDataModelFaPositionValuesChangedNotification]];
      if (sortingEnabled)
      {
         [self sortLines];
      }
   }
}

// FA reserve bid

- (BOOL)hasFaReserveBid
{
   return hasFaReserveBid;
}
- (void)setHasFaReserveBid:(BOOL)inValue
{
   hasFaReserveBid = inValue;
}

// FA MRT bid
- (BOOL)hasFaMrtBid
{
   return hasFaMrtBid;
}
- (void)setHasFaMrtBid:(BOOL)inValue
{
   hasFaMrtBid = inValue;
}

// points
- (BOOL)linePointsIncludePay { return linePointsIncludePay; }
- (void)setLinePointsIncludePay:(BOOL)inValue
{
   linePointsIncludePay = inValue;
   [self postNotificationForIdentifier:@"linePointsIncludePay" value:[NSNumber numberWithBool:linePointsIncludePay]];
   if (sortingEnabled) {
      [self adjustPointsForLines];
   }
}

// reserve/blank lines to bottom
- (BOOL)reserveLinesToBottomCheckboxValue { return reserveLinesToBottomCheckboxValue; }
- (void)setReserveLinesToBottomCheckboxValue:(BOOL)inValue
{
//   [[[self undoManager] prepareWithInvocationTarget:self] setReserveLinesToBottomCheckboxValue:reserveLinesToBottomCheckboxValue];
   reserveLinesToBottomCheckboxValue = inValue;
   [self postNotificationForIdentifier:@"reserveLinesToBottomCheckboxValue" value:[NSNumber numberWithBool:reserveLinesToBottomCheckboxValue]];
   if (sortingEnabled) {
      [self sortLines];
   }
}

- (BOOL)blankLinesToBottomCheckboxValue { return blankLinesToBottomCheckboxValue; }
- (void)setBlankLinesToBottomCheckboxValue:(BOOL)inValue
{
//   [[[self undoManager] prepareWithInvocationTarget:self] setBlankLinesToBottomCheckboxValue:blankLinesToBottomCheckboxValue];
   blankLinesToBottomCheckboxValue = inValue;
   [self postNotificationForIdentifier:@"blankLinesToBottomCheckboxValue" value:[NSNumber numberWithBool:blankLinesToBottomCheckboxValue]];
   if (sortingEnabled) {
      [self sortLines];
   }
}

// 3-on/3-off
- (BOOL)threeOnThreeOffToBottomCheckboxValue
{
   return threeOnThreeOffToBottomCheckboxValue;
}
- (void)setThreeOnThreeOffToBottomCheckboxValue:(BOOL)inValue
{
//   [[[self undoManager] prepareWithInvocationTarget:self] setThreeOnThreeOffToBottomCheckboxValue:threeOnThreeOffToBottomCheckboxValue];
   threeOnThreeOffToBottomCheckboxValue = inValue;
   [self postNotificationForIdentifier:@"threeOnThreeOffToBottomCheckboxValue" value:[NSNumber numberWithBool:threeOnThreeOffToBottomCheckboxValue]];
   if (sortingEnabled) {
      [self sortLines];
   }
}

@end
