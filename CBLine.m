//
//  CBLine.m
//  CrewBid
//
//  Created by Mark Ackerman on Sun May 02 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBLine.h"

#pragma mark LINE TRIP/DATE KEYS
NSString *CBLineTripNumberKey = @"CBLine Trip Number";
NSString *CBLineTripDateKey = @"CBLine Trip Date";
NSString *CBLineTripPositionKey = @"CBLine Trip Position";
NSString *CBLineTripReserveStartTimeKey = @"CBLine Trip Reserve Start Time";
NSString *CBLineTripReserveEndTimeKey = @"CBLine Trip Reserve End Time";
#pragma mark COMPARISON FUNCTION KEYS
NSString *CBLineComparisonSortSelectionsKey = @"Sort Selections";
NSString *CBLineComparisonFaPositionsKey = @"FA Positions";

@implementation CBLine

#pragma mark INITIALIZATION

+ (void)initialize
{
   static BOOL initialized = NO;
   if (!initialized && (self == [CBLine class])) {
      // version 1 adds hasOverlap variable
      [self setVersion:1];
      initialized = YES;
   }
}

- (id)initWithNumber:(int)inNumber credit:(float)inCredit block:(float)inBlock trips:(NSArray *)inTrips
{
   if (self = [super init]) {
      [self setNumber:inNumber];
      [self setCredit:inCredit];
      [self setBlock:inBlock];
      [self setTrips:inTrips];
      BOOL lineIsReserve = NO;
      BOOL lineIsBlank = NO;
      if (0.0 == [self block]) {
        if (0.0 == [self credit]) {
            lineIsBlank = YES;
         } else {
            lineIsReserve = YES;
         }
      }
      [self setIsReserveLine:lineIsReserve];
      [self setIsBlankLine:lineIsBlank];
   }
   return self;
}

- (void)dealloc
{
   [trips release];
	[lineCalendarEntries release];
	[lineCalendarObjects release];
	[lineCalendarTags release];
	[t234 release];
	[self setNumberString:nil];
   [super dealloc];
}

#pragma mark DERIVED VALUES

- (NSString *)blockString
{
   NSString * blockString = nil;
   float lineBlock = [self block];
   if (lineBlock > 0.0) {
      int hours = floorf(lineBlock);
      int minutes = roundf((lineBlock - (float)hours) * 60);
      blockString = [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
   } else {
      blockString = @"00:00";
   }
   return blockString;
}

- (NSString *)blockNextMonthString
{
   NSString * blockNextMonthString = nil;
   float lineBlockNextMonth = [self blockNextMonth];
   if (lineBlockNextMonth > 0.0) {
      int hours = floorf(lineBlockNextMonth);
      int minutes = roundf((lineBlockNextMonth - (float)hours) * 60);
      blockNextMonthString = [NSString stringWithFormat:@"%01d:%02d", hours, minutes];
   } else {
      blockNextMonthString = @"0:00";
   }
   return blockNextMonthString;
}

- (NSString *)amPmString
{
   NSString * amPmString = nil;
   if ([self isAM] && [self isPM]) {
      amPmString = @"Mix";
   } else if ([self isAM]) {
      amPmString = @"AM";
   } else if ([self isPM]) {
      amPmString = @"PM";
   } else {
      amPmString = @"NA";
   }
   return amPmString;
}

- (NSString *)earliestStartString
{
   NSString * earliestStartString = nil;
   int eStart = [self earliestStart];
   if (eStart > 0) {
      int hours = eStart / 100;
      if (hours > 23) {
         hours %= 24;
      }
      int minutes = eStart % 100;
      earliestStartString = [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
   } else {
      earliestStartString = @"00:00";
   }
   return earliestStartString;
}

- (NSString *)latestArrivalString
{
   NSString * latestArrivalString = nil;
   int lArr = [self latestArrival];
   if (lArr > 0) {
      int hours = lArr / 100;
      if (hours > 23) {
         hours %= 24;
      }
      int minutes = lArr % 100;
      latestArrivalString = [NSString stringWithFormat:@"%02d:%02d", hours, minutes];
   } else {
      latestArrivalString = @"00:00";
   }
   return latestArrivalString;
}

- (int)numberOfTrips;
{
   return [trips count];
}

- (float)payPerBlock
{
   float payPerBlock = 0.0;
   float lineBlock = [self block];
   if (lineBlock > 0.0) {
      payPerBlock = [self credit] / lineBlock;
   }
   return payPerBlock;
}

- (float)payPerDay
{
   float payPerDay = 0.0;
   int lineWorkDays = [[self workDates] count];
   if (lineWorkDays > 0) {
      payPerDay = [self credit] / (float)lineWorkDays;
   }
   return payPerDay;
}

- (float)payPerDuty
{
   float payPerDuty = 0.0;
   int lineDuty = [self duty];
   if (lineDuty > 0) {
      payPerDuty = [self credit] / ((float)lineDuty / 60.0);
   }
   return payPerDuty;
}

- (float)payPerLeg
{
   float payPerLeg = 0.0;
   int lineLegs = [self legs];
   if (lineLegs > 0) {
      payPerLeg = [self credit] / ((float)lineLegs);
   }
   return payPerLeg;
}

- (float)payPerTafb
{
   float payPerTafb = 0.0;
   int lineTafb = [self tafb];
   if (lineTafb > 0) {
      payPerTafb = (credit + creditNextMonth) / ((float)tafb / 60.0);
   }
   return payPerTafb;
}

- (NSString *)faPosition
{
   NSString *faPos = @"NA";
   unsigned tc = [trips count];
   // if there are no trips or there is no position for a trip, 
   // then fa position is NA
   if (tc > 0)
   {
      NSDictionary *t = [trips objectAtIndex:0]; // trip from trips array
      NSString *tp = [t objectForKey:CBLineTripPositionKey]; // trip position
      if (tp)
      {
         faPos = tp;
         unsigned i = 1;
         for (i = 1; i < tc; ++i)
         {
            t = [trips objectAtIndex:i];
            tp = [t objectForKey:CBLineTripPositionKey];
            if (![faPos isEqualToString:tp])
            {
               faPos = @"M";
               break;
            }
            else
            {
               faPos = tp;
            }
         }
      }
   }
   return faPos;
}

#pragma mark STORAGE

static NSString * CBLineNumberKey = @"Line Number";
static NSString * CBLineCreditKey = @"Line Credit";
static NSString * CBLineBlockKey = @"Line Block";
static NSString * CBLineTripsKey = @"Line Trips";
static NSString * CBLineIsReserveLineKey = @"Line Is Reserve Line";
static NSString * CBLineIsBlankLineKey = @"Line Is Blank Line";
static NSString * CBLinePointsKey = @"Line Points";
static NSString * CBLineDeselectedFlagsKey = @"Line Deselected Flags";

- (void)encodeWithCoder:(NSCoder *)encoder
{
   unsigned version = [encoder versionForClassName:@"CBLine"];

   if ([encoder allowsKeyedCoding]) {
      [encoder encodeInt:[self number] forKey:CBLineNumberKey];
      [encoder encodeFloat:[self credit] forKey:CBLineCreditKey];
      [encoder encodeFloat:[self block] forKey:CBLineBlockKey];
      [encoder encodeObject:[self trips] forKey:CBLineTripsKey];
      [encoder encodeBool:[self isReserveLine] forKey:CBLineIsReserveLineKey];
      [encoder encodeBool:[self isBlankLine] forKey:CBLineIsBlankLineKey];
      [encoder encodeFloat:[self points] forKey:CBLinePointsKey];
      [encoder encodeInt:[self deselectedFlags] forKey:CBLineDeselectedFlagsKey];
   } else {
      [encoder encodeValueOfObjCType:@encode(int) at:&number];
      [encoder encodeValueOfObjCType:@encode(float) at:&credit];
      [encoder encodeValueOfObjCType:@encode(float) at:&block];
      [encoder encodeObject:trips];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&isReserveLine];
      [encoder encodeValueOfObjCType:@encode(BOOL) at:&isBlankLine];
      [encoder encodeValueOfObjCType:@encode(float) at:&points];
      [encoder encodeValueOfObjCType:@encode(int) at:&deselectedFlags];
      // encode only if version > 0
      if (version > 0) {
         [encoder encodeValueOfObjCType:@encode(BOOL) at:&hasOverlap];
      }
   }
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super init];

   unsigned version = [decoder versionForClassName:@"CBLine"];

   if ([decoder allowsKeyedCoding]) {
      [self setNumber:[decoder decodeIntForKey:CBLineNumberKey]];
      [self setCredit:[decoder decodeFloatForKey:CBLineCreditKey]];
      [self setBlock:[decoder decodeFloatForKey:CBLineBlockKey]];
      [self setTrips:[decoder decodeObjectForKey:CBLineTripsKey]];
      [self setIsReserveLine:[decoder decodeBoolForKey:CBLineIsReserveLineKey]];
      [self setIsBlankLine:[decoder decodeBoolForKey:CBLineIsBlankLineKey]];
      [self setPoints:[decoder decodeFloatForKey:CBLinePointsKey]];
      [self setDeselectedFlag:[decoder decodeIntForKey:CBLineDeselectedFlagsKey]];
   } else {
      [decoder decodeValueOfObjCType:@encode(int) at:&number];
      [decoder decodeValueOfObjCType:@encode(float) at:&credit];
      [decoder decodeValueOfObjCType:@encode(float) at:&block];
      [self setTrips:[decoder decodeObject]];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&isReserveLine];
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&isBlankLine];
      [decoder decodeValueOfObjCType:@encode(float) at:&points];
      [decoder decodeValueOfObjCType:@encode(int) at:&deselectedFlags];
      // decode only if version > 0
      if (version > 0) {
         [decoder decodeValueOfObjCType:@encode(BOOL) at:&hasOverlap];
      }
   }
   return self;
}

#pragma mark COMPARISON FUNCTIONS

// context is an array of line comparison functions
NSInteger compareLines( id foreLine, id aftLine, void * context )
{
   // return value
   NSComparisonResult comparisonResult = NSOrderedSame;
   // cast arguments
   CBLine * fore = (CBLine *)foreLine;
   CBLine * aft = (CBLine *)aftLine;
   NSArray * lineSortFunctions = [(NSDictionary *)context objectForKey:CBLineComparisonSortSelectionsKey];
   NSEnumerator * sortFunctionsEnumerator = [lineSortFunctions objectEnumerator];
   NSValue * sortFunctionValue = nil;
   while ((comparisonResult == NSOrderedSame) && (sortFunctionValue = [sortFunctionsEnumerator nextObject])) {
      NSComparisonResult (* sortFunction)( CBLine *, CBLine * ) = [sortFunctionValue pointerValue];
      comparisonResult = sortFunction( fore, aft );
   }
   // compare by FA position if lines are equal
   if (NSOrderedSame == comparisonResult) {
      comparisonResult = compareLinesByFAPosition(fore, aft, [(NSDictionary *)context objectForKey:CBLineComparisonFaPositionsKey]);
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPoints( CBLine * fore, CBLine * aft )
{
   // ordered ascending if points is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->points > aft->points) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->points < aft->points) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByAmThenPm( CBLine * fore, CBLine * aft )
{
   // ordered ascending if line is AM
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->isAM && fore->isPM && aft->isAM && aft->isPM) {
      comparisonResult = NSOrderedSame;
   } else if (fore->isAM && aft->isPM) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->isPM && aft->isAM) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPmThenAm( CBLine * fore, CBLine * aft )
{
   // ordered ascending if line is PM
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->isAM && fore->isPM && aft->isAM && aft->isPM) {
      comparisonResult = NSOrderedSame;
   } else if (fore->isAM && aft->isPM) {
      comparisonResult = NSOrderedDescending;
   } else if (fore->isPM && aft->isAM) {
      comparisonResult = NSOrderedAscending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByAircraftChanges( CBLine * fore, CBLine * aft )
{
   // ordered ascending if aircraft changes is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->aircraftChanges < aft->aircraftChanges) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->aircraftChanges > aft->aircraftChanges) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByCommutesRequired( CBLine * fore, CBLine * aft )
{
    // ordered ascending if commutes required is less
    NSComparisonResult comparisonResult = NSOrderedSame;
    if (fore->commutesRequiredCount < aft->commutesRequiredCount) {
        comparisonResult = NSOrderedAscending;
    } else if (fore->commutesRequiredCount > aft->commutesRequiredCount) {
        comparisonResult = NSOrderedDescending;
    }
    return comparisonResult;
}

NSComparisonResult compareLinesByDaysOff( CBLine * fore, CBLine * aft )
{
    // ordered ascending if days off is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->daysOff > aft->daysOff) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->daysOff < aft->daysOff) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByNumber( CBLine * fore, CBLine * aft )
{
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->number < aft->number) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->number > aft->number) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByOvernightsInDomicile( CBLine * fore, CBLine * aft )
{
    // ordered ascending if overnights in domicile is less
    NSComparisonResult comparisonResult = NSOrderedSame;
    if (fore->overnightsInDomicileCount < aft->overnightsInDomicileCount) {
        comparisonResult = NSOrderedAscending;
    } else if (fore->overnightsInDomicileCount > aft->overnightsInDomicileCount) {
        comparisonResult = NSOrderedDescending;
    }
    return comparisonResult;
}

NSComparisonResult compareLinesByPassesThroughDomicile( CBLine * fore, CBLine * aft )
{
   // ordered ascending if passes through domicile is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore passesThroughDomicile] > [aft passesThroughDomicile]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore passesThroughDomicile] < [aft passesThroughDomicile]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPay( CBLine * fore, CBLine * aft )
{
   // ordered ascending if pay is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->credit > aft->credit) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->credit < aft->credit) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPayPerBlock( CBLine * fore, CBLine * aft )
{
   // ordered ascending if pay per day is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore payPerBlock] > [aft payPerBlock]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore payPerBlock] < [aft payPerBlock]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPayPerDay( CBLine * fore, CBLine * aft )
{
   // ordered ascending if pay per day is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore payPerDay] > [aft payPerDay]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore payPerDay] < [aft payPerDay]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPayPerDuty( CBLine * fore, CBLine * aft )
{
   // ordered ascending if pay per day is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore payPerDuty] > [aft payPerDuty]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore payPerDuty] < [aft payPerDuty]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPayPerLeg( CBLine * fore, CBLine * aft )
{
   // ordered ascending if pay per leg is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore payPerLeg] > [aft payPerLeg]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore payPerLeg] < [aft payPerLeg]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByBlock(CBLine * fore, CBLine * aft)
{
   // ordered ascending if block is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->block < aft->block) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->block > aft->block) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByBlockOfDaysOff(CBLine * fore, CBLine * aft)
{
   // ordered ascending if block of days off is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->longestDaysOffBlock > aft->longestDaysOffBlock) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->longestDaysOffBlock < aft->longestDaysOffBlock) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByReserveLinesToBottom(CBLine * fore, CBLine * aft)
{
   // ordered ascending if not reserve and other line is reserve
   // ordered descending if reserve and other line is not reserve
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (![fore isReserveLine] && [aft isReserveLine]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore isReserveLine] && ![aft isReserveLine]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByBlankLinesToBottom(CBLine * fore, CBLine * aft)
{
   // ordered ascending if not blank and other line is blank
   // ordered descending if blank and other line is not blank
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (![fore isBlankLine] && [aft isBlankLine]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore isBlankLine] && ![aft isBlankLine]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByThreeOnThreeOffToBottom(CBLine * fore, CBLine * aft)
{
   // ordered ascending if fore is not 3on/3off and aft is 3on/3off
   // ordered descending if fore is 3on/3off and aft is not 3on/3off
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (![fore is3on3off] && [aft is3on3off]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore is3on3off] && ![aft is3on3off]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByTrips(CBLine * fore, CBLine * aft)
{
   // ordered ascending if number of trips is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore numberOfTrips] < [aft numberOfTrips]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore numberOfTrips] > [aft numberOfTrips]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByWorkDays(CBLine * fore, CBLine * aft)
{
   // ordered ascending if number of work days is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore workDays] < [aft workDays]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore workDays] > [aft workDays]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByMaxLegsPerDay(CBLine * fore, CBLine * aft)
{
	// ordered ascending if max legs is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->maxLegs < aft->maxLegs) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->maxLegs > aft->maxLegs) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByVacationDrop(CBLine * fore, CBLine * aft)
{
   // ordered ascending if vacation drop is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->vacationDrop < aft->vacationDrop) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->vacationDrop > aft->vacationDrop) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByVacationDaysOff(CBLine * fore, CBLine * aft)
{
   // ordered ascending if vacation days off is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->vacationDaysOff > aft->vacationDaysOff) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->vacationDaysOff < aft->vacationDaysOff) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByVacationPay(CBLine * fore, CBLine * aft)
{
   // ordered ascending if vacation pay is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->vacationPay > aft->vacationPay) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->vacationPay < aft->vacationPay) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByPayWithVacation(CBLine * fore, CBLine * aft)
{
   // ordered ascending if vacation pay is greater
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (fore->payWithVacation > aft->payWithVacation) {
      comparisonResult = NSOrderedAscending;
   } else if (fore->payWithVacation < aft->payWithVacation) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByLegs(CBLine * fore, CBLine * aft)
{
   // ordered ascending if number of legs is less
   NSComparisonResult comparisonResult = NSOrderedSame;
   if ([fore legs] < [aft legs]) {
      comparisonResult = NSOrderedAscending;
   } else if ([fore legs] > [aft legs]) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByFAPosition(CBLine * fore, CBLine * aft, void * context)
{
   NSComparisonResult comparisonResult = NSOrderedAscending;
   unsigned foreIndex = [(NSArray *)context indexOfObject:[fore faPosition]];
   unsigned aftIndex = [(NSArray *)context indexOfObject:[aft faPosition]];
   if (foreIndex > aftIndex)
   {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByFAAPosition(CBLine * fore, CBLine * aft)
{
   NSComparisonResult comparisonResult = NSOrderedSame;
   BOOL foreIsA = [[fore faPosition] isEqualToString:@"A"];
   BOOL aftIsA = [[aft faPosition] isEqualToString:@"A"];
   if (foreIsA && !aftIsA)
   {
      comparisonResult = NSOrderedAscending;
   }
   else if (!foreIsA && aftIsA)
   {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByFABPosition(CBLine * fore, CBLine * aft)
{
   NSComparisonResult comparisonResult = NSOrderedSame;
   BOOL foreIsB = [[fore faPosition] isEqualToString:@"B"];
   BOOL aftIsB = [[aft faPosition] isEqualToString:@"B"];
   if (foreIsB && !aftIsB)
   {
      comparisonResult = NSOrderedAscending;
   }
   else if (!foreIsB && aftIsB)
   {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByFACPosition(CBLine * fore, CBLine * aft)
{
   NSComparisonResult comparisonResult = NSOrderedSame;
   BOOL foreIsC = [[fore faPosition] isEqualToString:@"C"];
   BOOL aftIsC = [[aft faPosition] isEqualToString:@"C"];
   if (foreIsC && !aftIsC)
   {
      comparisonResult = NSOrderedAscending;
   }
   else if (!foreIsC && aftIsC)
   {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

NSComparisonResult compareLinesByFADPosition(CBLine * fore, CBLine * aft)
{
	NSComparisonResult comparisonResult = NSOrderedSame;
	BOOL foreIsD = [[fore faPosition] isEqualToString:@"D"];
	BOOL aftIsD = [[aft faPosition] isEqualToString:@"D"];
	if (foreIsD && !aftIsD)
	{
		comparisonResult = NSOrderedAscending;
	}
	else if (!foreIsD && aftIsD)
	{
		comparisonResult = NSOrderedDescending;
	}
	return comparisonResult;
}

NSComparisonResult compareLinesBySelected(CBLine * fore, CBLine * aft)
{
   // ordered ascending if line is selected and other is not
   NSComparisonResult comparisonResult = NSOrderedSame;
   if (!(fore->deselectedFlags) && aft->deselectedFlags) {
      comparisonResult = NSOrderedAscending;
   } else if ((fore->deselectedFlags) && !(aft->deselectedFlags)) {
      comparisonResult = NSOrderedDescending;
   }
   return comparisonResult;
}

#pragma mark COMPARISON METHOD
- (BOOL)isEqualToLine:(CBLine *)other
{
   return [self number] == [other number];
}

#pragma mark SELECTION METHODS

- (void)setDeselectedFlag:(CBLineDeselectedFlag)flag
{
   deselectedFlags |= flag;
}
- (void)clearDeselectedFlag:(CBLineDeselectedFlag)flag
{
   deselectedFlags &= ~flag;
}

#pragma mark ACCESSORS

- (int)number { return number; }
- (void)setNumber:(int)inValue { number = inValue; }

- (float)credit { return credit; }
- (void)setCredit:(float)inValue { credit = inValue; }

- (float)block { return block; }
- (void)setBlock:(float)inValue { block = inValue; }

- (NSArray *)trips{ return trips; }
- (void)setTrips:(NSArray *)inValue
{
   if (trips != inValue) {
      [trips release];
      trips = [inValue copy];
   }
}

- (BOOL)isReserveLine { return isReserveLine; }
- (void)setIsReserveLine:(BOOL)inValue { isReserveLine = inValue; }

- (BOOL)isBlankLine { return isBlankLine; }
- (void)setIsBlankLine:(BOOL)inValue { isBlankLine = inValue; }

- (NSArray *)lineCalendarEntries { return lineCalendarEntries; }
- (void)setLineCalendarEntries:(NSArray *)inValue
{
   if (lineCalendarEntries != inValue) {
      [lineCalendarEntries release];
      lineCalendarEntries = [inValue copy];
   }
}

- (NSArray *)lineCalendarObjects { return lineCalendarObjects; }
- (void)setLineCalendarObjects:(NSArray *)inValue
{
   if (lineCalendarObjects != inValue) {
      [lineCalendarObjects release];
      lineCalendarObjects = [inValue copy];
   }
}

- (NSArray *)lineCalendarTags { return lineCalendarTags; }
- (void)setLineCalendarTags:(NSArray *)inValue
{
   if (lineCalendarTags != inValue) {
      [lineCalendarTags release];
      lineCalendarTags = [inValue copy];
   }
}

- (NSArray *)printCalendarEntries { return printCalendarEntries; }
- (void)setPrintCalendarEntries:(NSArray *)inValue
{
   if (printCalendarEntries != inValue) {
      [printCalendarEntries release];
      printCalendarEntries = [inValue copy];
   }
}

- (float)points { return points; }
- (void)setPoints:(float)inValue { points = inValue; }

- (int)deselectedFlags { return deselectedFlags; }

// derived
- (NSString *)numberString {
    return numberString;
}

- (void)setNumberString:(NSString *)value {
    if (numberString != value) {
        [numberString release];
        numberString = [value copy];
    }
}

- (float)creditNextMonth { return creditNextMonth; }
- (void)setCreditNextMonth:(float)inValue { creditNextMonth = inValue; }

- (float)blockNextMonth { return blockNextMonth; }
- (void)setBlockNextMonth:(float)inValue { blockNextMonth = inValue; }

- (BOOL)isAM { return isAM; }
- (void)setIsAM:(BOOL)inValue { isAM = inValue; }

- (BOOL)isPM { return isPM; }
- (void)setIsPM:(BOOL)inValue { isPM = inValue; }

- (NSString *)t234 { return t234; }
- (void)setT234:(NSString *)inValue
{
   if (t234 != inValue) {
      [t234 release];
      t234 = [inValue copy];
   }
}

- (int)turns { return turns; }
- (void)setTurns:(int)inValue { turns = inValue; }

- (int)twoDays { return twoDays; }
- (void)setTwoDays:(int)inValue { twoDays = inValue; }

- (int)threeDays { return threeDays; }
- (void)setThreeDays:(int)inValue { threeDays = inValue; }

- (int)fourDays { return fourDays; }
- (void)setFourDays:(int)inValue { fourDays = inValue; }

- (int)oneDayWorkBlocks { return oneDayWorkBlocks; }
- (void)setOneDayWorkBlocks:(int)inValue { oneDayWorkBlocks = inValue; }

- (int)twoDayWorkBlocks { return twoDayWorkBlocks; }
- (void)setTwoDayWorkBlocks:(int)inValue { twoDayWorkBlocks = inValue; }

- (int)threeDayWorkBlocks { return threeDayWorkBlocks; }
- (void)setThreeDayWorkBlocks:(int)inValue { threeDayWorkBlocks = inValue; }

- (int)fourDayWorkBlocks { return fourDayWorkBlocks; }
- (void)setFourDayWorkBlocks:(int)inValue { fourDayWorkBlocks = inValue; }

- (int)longestDaysOffBlock { return longestDaysOffBlock; }
- (void)setLongestDaysOffBlock:(int)inValue { longestDaysOffBlock = inValue; }

- (BOOL)is3on3off
{
   return is3on3off;
}
- (void)setIs3on3off:(BOOL)inValue
{
   is3on3off = inValue;
}

- (int)weekends { return weekends; }
- (void)setWeekends:(int)inValue { weekends = inValue; }

- (int)workDays { return workDays; }
- (void)setWorkDays:(int)inValue { workDays = inValue; }

- (int)daysOff { return daysOff; }
- (void)setDaysOff:(int)inValue { daysOff = inValue; }

- (NSCountedSet *)overnightCities { return overnightCities; }
- (void)setOvernightCities:(NSCountedSet *)inValue
{
   if (overnightCities != inValue) {
      [overnightCities release];
      overnightCities = [inValue copy];
   }
}

- (NSSet *)workDates { return workDates; }
- (void)setWorkDates:(NSSet *)inValue
{
   if (workDates != inValue) {
      [workDates release];
      workDates = [inValue copy];
   }
}

- (NSSet *)workDatesNextMonth { return workDatesNextMonth; }
- (void)setWorkDatesNextMonth:(NSSet *)inValue
{
   if (workDatesNextMonth != inValue) {
      [workDatesNextMonth release];
      workDatesNextMonth = [inValue copy];
   }
}

- (int)tafb { return tafb; }
- (void)setTafb:(int)inValue { tafb = inValue; }

- (int)duty { return duty; }
- (void)setDuty:(int)inValue { duty = inValue; }

- (int)dutyNextMonth { return dutyNextMonth; }
- (void)setDutyNextMonth:(int)inValue { dutyNextMonth = inValue; }

- (int)maxDutyDay { return maxDutyDay; }
- (void)setMaxDutyDay:(int)inValue { maxDutyDay = inValue; }

- (int)legs { return legs; }
- (void)setLegs:(int)inValue { legs = inValue; }

- (int)aircraftChanges{ return aircraftChanges; }
- (void)setAircraftChanges:(int)inValue { aircraftChanges = inValue; }

- (int)legsNextMonth { return legsNextMonth; }
- (void)setLegsNextMonth:(int)inValue { legsNextMonth = inValue; }

- (int)maxLegs; { return maxLegs; }
- (void)setMaxLegs:(int)inValue { maxLegs = inValue; }

- (int)aircraftChangesNextMonth { return aircraftChangesNextMonth; }
- (void)setAircraftChangesNextMonth:(int)inValue { aircraftChangesNextMonth = inValue; }

- (int) earliestStart { return earliestStart; }
- (void)setEarliestStart:(int)inValue { earliestStart = inValue; }

- (int) latestArrival { return latestArrival; }
- (void)setLatestArrival:(int)inValue { latestArrival = inValue; }

- (int)passesThroughDomicile; { return passesThroughDomicile; }
- (void)setPassesThroughDomicile:(int)inValue { passesThroughDomicile = inValue; }

// overlap
- (BOOL)hasOverlap { return hasOverlap; }
- (void)setHasOverlap:(BOOL)inValue { hasOverlap = inValue; }

// deadheads
- (NSCountedSet *)deadheadAtStartCities {
    return deadheadAtStartCities;
}
- (void)setDeadheadAtStartCities:(NSCountedSet *)value {
    if (deadheadAtStartCities != value) {
        [deadheadAtStartCities release];
        deadheadAtStartCities = [value copy];
    }
}
- (NSCountedSet *)deadheadAtEndCities {
    return deadheadAtEndCities;
}
- (void)setDeadheadAtEndCities:(NSCountedSet *)value {
    if (deadheadAtEndCities != value) {
        [deadheadAtEndCities release];
        deadheadAtEndCities = [value copy];
    }
}
// commuting
- (int)commutesRequiredCount {
    return commutesRequiredCount;
}

- (void)setCommutesRequiredCount:(int)value {
    if (commutesRequiredCount != value) {
        commutesRequiredCount = value;
    }
}

- (int)overnightsInDomicileCount {
    return overnightsInDomicileCount;
}

- (void)setOvernightsInDomicileCount:(int)value {
    if (overnightsInDomicileCount != value) {
        overnightsInDomicileCount = value;
    }
}


#pragma mark DESCRIPTION
- (NSString *)description
{
   return [NSString stringWithFormat:@"%3d\t\t%3.2f\t\t%2.2f\t\t%@\t\t%@\n%@\n", number, credit, block, ([self isReserveLine] ? @"R" : @""), ([self isBlankLine] ? @"B" : @""), trips];
}

@end
