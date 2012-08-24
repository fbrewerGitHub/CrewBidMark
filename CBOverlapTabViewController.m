//
//  CBOverlapTabViewController.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon Aug 07 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDataModel.h"
#import "CBBlockTime.h"
#import "CBAppController.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"
#import "CBOverlapDetector.h"
#import "CBDocument.h"
#import "CBProgressWindowController.h"

@implementation CBMainWindowController ( CBOverlapTabViewController )

#pragma mark INITIALIZATION

- (void)initializeOverlapTabView
{
   [self fillOverlapDates];
   [self updateOverlapDatesForm:nil];
   [self fillLastMonthPopUpButton];
}

- (void)fillOverlapDates
{
   NSCalendarDate * previousMonth = nil;
   NSCalendarDate * cellDate = nil;
   int daysInMonth = 0;
   NSArray * dateFormCells = nil;
   NSEnumerator * dateFormCellsEnumerator = nil;
   NSFormCell * dateFormCell = nil;
   NSString * cellTitle = nil;

   previousMonth = [[[self dataModel] month] dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
   // date of first cell
   daysInMonth = [[previousMonth dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0] dayOfMonth];
   cellDate = [previousMonth dateByAddingYears:0 months:0 days:(daysInMonth - 6) hours:0 minutes:0 seconds:0];
   // set titles of form cells
   dateFormCells = [[self overlapDatesForm] cells];
   dateFormCellsEnumerator = [dateFormCells objectEnumerator];
   while (dateFormCell = [dateFormCellsEnumerator nextObject]) {

      cellTitle = [cellDate descriptionWithCalendarFormat:@"%d %b:"];
      [dateFormCell setTitle:cellTitle];
      
      [dateFormCell setRepresentedObject:cellDate];
      cellDate = [cellDate dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
   }
   [[self overlapDatesForm] sizeToCells];
   [[self overlapDatesForm] setNeedsDisplay];
}

- (void)fillLastMonthPopUpButton
{
   NSPopUpButton *previousMonthPopUpButton = [self lastMonthBidPopUpButton];
   
   NSCalendarDate *curMonth = [[self dataModel] month];
   NSCalendarDate *prevMonth = nil;
   NSInteger monthDiff = 0;

   // put names of files from previous month last month bid popup button
   [previousMonthPopUpButton removeAllItems];
   
   NSEnumerator *filenameEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[NSApp delegate] crewBidDirectoryPath]];
   NSString * filename = nil;
   while (filename = [filenameEnumerator nextObject]) {

      prevMonth = [[NSApp delegate] dateWithFilename:filename];
      if (prevMonth) {
         [curMonth years:NULL months:&monthDiff days:NULL hours:NULL minutes:NULL seconds:NULL sinceDate:prevMonth];
      }

      if ([[filename pathExtension] isEqualToString:@"crewbid"] && 1 == monthDiff) {
      
         [previousMonthPopUpButton addItemWithTitle:[filename stringByDeletingPathExtension]];
      }
   }
   // if there are no items in last month bid popup button, put in filler item
   if (0 == [[previousMonthPopUpButton itemArray] count]) {

      [previousMonthPopUpButton addItemWithTitle:@"No Previous Bid Month Available"];
      [[self lastMonthLineTextField] setEnabled:NO];
      [[self useSelectedDataButton] setEnabled:NO];

   // select filename that contains seat position or crew base
   } else {
      filenameEnumerator = [[previousMonthPopUpButton itemTitles] objectEnumerator];
      while (filename = [filenameEnumerator nextObject]) {
      
         if (NSNotFound != [filename rangeOfString:[[self dataModel] crewPosition]].location ||
             NSNotFound != [filename rangeOfString:[self shortCrewPositionWithPosition:[[self dataModel] crewPosition]]].location) {
         
            [previousMonthPopUpButton selectItemWithTitle:filename];
            break;

         } else if (NSNotFound != [filename rangeOfString:[[self dataModel] crewBase]].location) {
         
            [previousMonthPopUpButton selectItemWithTitle:filename];
            break;
         }
      }
   }

   [previousMonthPopUpButton sizeToFit];
   [previousMonthPopUpButton setNeedsDisplay];
}

- (NSString *)shortCrewPositionWithPosition:(NSString *)crewPos
{
   NSString *shortPos = nil;
   if ([crewPos isEqualToString:@"Captain"]) {
      shortPos = @"CA";
   } else if ([crewPos isEqualToString:@"First Officer"]) {
      shortPos = @"FO";
   } else if ([crewPos isEqualToString:@"Flight Attendant"]) {
      shortPos = @"FA";
   }
   return shortPos;
}

- (void)getPreviousMonth:(NSString **)month year:(NSString **)year documentName:(NSString **)name
{
   NSArray * monthNames = nil;
   NSString * documentName = nil;
   NSString * documentMonth = nil;
   NSString * documentYear = nil;
   NSString * documentNameRemainder = nil;
   NSRange monthRange = (NSRange){0, 0};
   NSRange yearRange = (NSRange){0, 0};
   unsigned thisMonthIndex = 0;
   unsigned previousMonthIndex = 0;

	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	monthNames = [df monthSymbols];
	[df release];
   documentName = [[self document] lastComponentOfFileName];
   monthRange = [documentName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
   yearRange = [documentName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSLiteralSearch range:NSMakeRange(monthRange.location + 1, [documentName length] - (monthRange.location + 1))];
   documentMonth = [documentName substringToIndex:monthRange.location];
   documentYear = [documentName substringWithRange:NSMakeRange(monthRange.location + 1, yearRange.location - (monthRange.location + 1))];
   documentNameRemainder = [documentName substringFromIndex:yearRange.location + 1];

   thisMonthIndex = [monthNames indexOfObject:documentMonth];
   previousMonthIndex = thisMonthIndex != 0 ? thisMonthIndex - 1 : 11;
   *month = [monthNames objectAtIndex:previousMonthIndex];
   
   if (0 == thisMonthIndex) {
      *year = [NSString stringWithFormat:@"%d", [documentYear intValue] - 1];
   } else {
      *year = documentYear;
   }

   if (!(*name = [[NSUserDefaults standardUserDefaults] objectForKey:CBMostRecentBidDocumentKey])) {
   
      *name = [NSString stringWithFormat:@"%@ %@ %@", *month, *year, documentNameRemainder];

      [[NSUserDefaults standardUserDefaults] setObject:*name forKey:CBMostRecentBidDocumentKey];
   }
}

#pragma mark ACTIONS

- (void)useSelectedDataButtonAction:(id)sender
{
   int previousMonthLineNumber = 0;
   unsigned numberOfOverlapFormEntries = 0;
   CBProgressWindowController * progressController = nil;
   NSString * previousMonthFileName = nil;
   NSString * previousMonthFilePath = nil;

   if ((previousMonthLineNumber = [[self lastMonthLineTextField] intValue])) {
   
      numberOfOverlapFormEntries = [[[self overlapDatesForm] cells] count];
   
      progressController = [[CBProgressWindowController alloc] init];
      [progressController setProgressText:[NSString stringWithFormat:@"Reading %@ data...", [[self lastMonthBidPopUpButton] titleOfSelectedItem]]];
      [progressController disableCancelButton];
      
      // commit pending edits
      [[self window] makeFirstResponder:[self window]];

      [NSApp beginSheet:[progressController window] modalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
   
      previousMonthFileName = [[[self lastMonthBidPopUpButton] titleOfSelectedItem] stringByAppendingPathExtension:@"crewbid"];
      
      previousMonthFilePath = [[[NSApp delegate] crewBidDirectoryPath] stringByAppendingPathComponent:previousMonthFileName];
      
      [[self dataModel] setOverlapFormValuesWithPreviousMonthFile:previousMonthFilePath line:previousMonthLineNumber numberOfEntries:numberOfOverlapFormEntries];
      
      [NSApp endSheet:[progressController window]];
      [[progressController window] close];
      [progressController release];
   }
}

- (void)computeOverlapButtonAction:(id)sender
{
   CBProgressWindowController * progressController = nil;
   progressController = [[CBProgressWindowController alloc] init];
    [progressController setProgressText:@"Computing overlaps..."];
   [progressController disableCancelButton];

   // commit pending edits
   [[self window] makeFirstResponder:[self window]];

   [NSApp beginSheet:[progressController window] modalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
   
   [[self dataModel] detectOverlaps];
   
   [NSApp endSheet:[progressController window]];
   [[progressController window] close];
   [progressController release];
}

- (void)overlapDatesFormAction:(id)sender
{
   NSForm * overlapForm = (NSForm *)sender;
   NSFormCell * formCell = nil;
   NSMutableArray * overlapFormValues = nil;
   int selectedFormCellIndex = 0;
   CBBlockTime * oldBlockTime = nil;
   CBBlockTime * newBlockTime = nil;
   NSCalendarDate * cellDate = nil;
   NSDictionary * cellValue = nil;
   
   selectedFormCellIndex = [overlapForm indexOfSelectedItem];
   overlapFormValues = [[[self dataModel] overlapFormValues] mutableCopy];
   oldBlockTime = (CBBlockTime *)[[overlapFormValues objectAtIndex:selectedFormCellIndex] objectForKey:CBOverlapEntryBlockTimeKey];
   formCell = [overlapForm cellAtIndex:selectedFormCellIndex];
   newBlockTime = (CBBlockTime *)[formCell objectValue];
   if (![oldBlockTime isEqualToBlockTime:newBlockTime]) {
      cellDate = (NSCalendarDate *)[formCell representedObject];
      cellValue = [NSDictionary dictionaryWithObjectsAndKeys:newBlockTime, CBOverlapEntryBlockTimeKey, [cellDate dateByAddingYears:0 months:0 days:0 hours:CBOverlapNextDayHour minutes:0 seconds:0], CBOverlapEntryReleaseTimeKey, cellDate, CBOverlapEntryDateKey, nil];
      [overlapFormValues replaceObjectAtIndex:selectedFormCellIndex withObject:cellValue];
      [[self dataModel] setOverlapFormValues:[NSArray arrayWithArray:overlapFormValues]];
   }
}

- (void)overlapReleaseTimeTextFieldAction:(id)sender
{
   CBBlockTime * releaseTime = [[self overlapLastArrivalTimeTextField] objectValue];
   
   // make sure we've got a reasonable release time (between 00:00 and 24:00)
   if (/*[releaseTime totalMinutes] >= 0 &&*/ [releaseTime totalMinutes] <= 24 * 60) {
      float y = [[self overlapLastArrivalTimeTextField] frame].origin.y;
      int index = (int)(251.0 - y) / 27;
      CBBlockTime * blockTime = [[[self overlapDatesForm] cellAtIndex:index] objectValue];
      NSCalendarDate * date = [[[self overlapDatesForm] cellAtIndex:index] representedObject];
      NSCalendarDate * releaseDate = [date dateByAddingYears:0 months:0 days:([releaseTime hours] < CBOverlapNextDayHour ? 1 : 0) hours:[releaseTime hours] minutes:[releaseTime minutes] seconds:0];
      NSMutableArray * overlapFormValues = [[[self dataModel] overlapFormValues] mutableCopy];
      NSDictionary * overlapValue = [NSDictionary dictionaryWithObjectsAndKeys:blockTime, CBOverlapEntryBlockTimeKey, releaseDate, CBOverlapEntryReleaseTimeKey, date, CBOverlapEntryDateKey, nil];
      [overlapFormValues replaceObjectAtIndex:index withObject:overlapValue];
      [[self dataModel] setOverlapFormValues:[NSArray arrayWithArray:overlapFormValues]];
   } else {
      [self sheetForReleaseTimeInvalidValue];
   }
}

#pragma mark SPECIFIC INTERFACE ITEM UPDATERS

- (void)updateOverlapDatesForm:(NSNotification *)notification
{
   NSArray * overlapFormValues = nil;
   NSEnumerator * formCellsEnumerator = nil;
   NSFormCell * formCell = nil;
   NSEnumerator * overlapFormValuesEnumerator = nil;
   NSDictionary * overlapValue = nil;
   CBBlockTime * blockTime = nil;
   NSCalendarDate * releaseTime = nil;
   
   if (!(overlapFormValues = (NSArray *)[[notification userInfo] objectForKey:CBDataModelOverlapFormValuesChangedNotification])) {
   
      overlapFormValues = [[self dataModel] overlapFormValues];
   }
   
   formCellsEnumerator = [[[self overlapDatesForm] cells] objectEnumerator];
   overlapFormValuesEnumerator = [overlapFormValues objectEnumerator];
   while ((formCell = [formCellsEnumerator nextObject]) &&
          (overlapValue = [overlapFormValuesEnumerator nextObject])) {
   
      blockTime = [overlapValue objectForKey:CBOverlapEntryBlockTimeKey];
      [formCell setObjectValue:blockTime];
      
      if (![blockTime isZero]) {
      
         releaseTime = [overlapValue objectForKey:CBOverlapEntryReleaseTimeKey];
      } 
   }
   // set release time text field
   if (!releaseTime) {

      releaseTime = [[overlapFormValues objectAtIndex:0] objectForKey:CBOverlapEntryReleaseTimeKey];
   }

   [[[self overlapLastArrivalTimeTextField] cell] setRepresentedObject:releaseTime];
   blockTime = [[[CBBlockTime alloc] initWithHours:[releaseTime hourOfDay] minutes:[releaseTime minuteOfHour]] autorelease];
   [[self overlapLastArrivalTimeTextField] setObjectValue:blockTime];
   [self positionOverlapReleaseTimeTextField];
}

- (void)updateOverlapReleaseTimeTextField:(NSNotification *)notification
{
   NSCalendarDate * releaseDate = nil;
   unsigned releaseDateMinutes = 0;
   CBBlockTime * releaseTime = nil;

   if (notification) {
      releaseDate = [[notification userInfo] objectForKey:CBDataModelOverlapReleaseTimeValueChangedNotification];
   } else {
//      releaseDate = [[self dataModel] overlapReleaseTimeValue];
   }
   
   [[[self overlapLastArrivalTimeTextField] cell] setRepresentedObject:releaseDate];
   releaseDateMinutes = [releaseDate hourOfDay] * 60 + [releaseDate minuteOfHour];
   releaseTime = [CBBlockTime blockTimeWithMinutes:releaseDateMinutes];
   [[self overlapLastArrivalTimeTextField] setObjectValue:releaseTime];
   [self positionOverlapReleaseTimeTextField];
}

- (void)positionOverlapReleaseTimeTextField
{
   NSCalendarDate * releaseDate = nil;
   NSCalendarDate * firstFormDate = nil;
   NSInteger hoursSinceFirstFormDate = 0;
   NSInteger minutesSinceFirstFormDate = 0;
   NSInteger releaseDateIndex = 0;
   
   const float INITIAL_TEXT_X = 116.0;
   const float INITIAL_TEXT_Y = 253.0;
   const float INITIAL_FIELD_X = 199.0;
   const float INITIAL_FIELD_Y = 251.0;
   const float DELTA_Y = 27.0;
   
   releaseDate = [[[self overlapLastArrivalTimeTextField] cell] representedObject];
   firstFormDate = [[[[self overlapDatesForm] cells] objectAtIndex:0] representedObject];
   [releaseDate years:nil months:nil days:&releaseDateIndex hours:&hoursSinceFirstFormDate minutes:&minutesSinceFirstFormDate seconds:nil sinceDate:firstFormDate];
   
   // if release time is less than CBOverlapNextDayHour, then move release date back one day
   if ([releaseDate hourOfDay] < CBOverlapNextDayHour) {
      releaseDateIndex--;
   }

   // shift position of release time text fields
   [[self overlapLastArrivalTextField] setFrameOrigin:NSMakePoint(INITIAL_TEXT_X, INITIAL_TEXT_Y - (releaseDateIndex * DELTA_Y))];
   [[self overlapLastArrivalTimeTextField] setFrameOrigin:NSMakePoint(INITIAL_FIELD_X, INITIAL_FIELD_Y - (releaseDateIndex * DELTA_Y))];
   [[[self overlapLastArrivalTimeTextField] superview] setNeedsDisplay:YES];
}

#pragma mark NOTIFICATION REGISTRATION

- (void)registerNotificationsForOverlapTabView
{
   // TEMP CODE - remove when flight attendant overlap implemented
   if (![self isFlightAttendantBid]) {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOverlapDatesForm:) name:CBDataModelOverlapFormValuesChangedNotification object:[self dataModel]];

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOverlapDatesForm:) name:CBDataModelUnarchivedNotification 
         object:[self document]];
   }
}

#pragma mark INPUT VALIDATION AND FORMATTING

- (BOOL)sheetForBlockTimeTextFieldValidationFailure:(NSString *)string errorDescription:(NSString *)error
{
//   NSString * alertInformation = @"Type any of the digits \"0\" - \"9\" and at most a single colon \":\" in the time text field, such as \"12:30\".";
   
   NSBeginAlertSheet(error, nil, nil, nil, [self window], self, NULL, NULL, nil, @"Type any of the digits \"0\" - \"9\" and at most a single colon \":\" in the time text field, such as \"12:30\".");
   
   return NO;
}

- (BOOL)sheetForReleaseTimeInvalidValue
{
   NSString *title = nil;
//   NSString *message = @"Release time must be between 00:00 and 24:00.";
   
   CBBlockTime *relTime = [[self overlapLastArrivalTimeTextField] objectValue];
   int totMin = [relTime totalMinutes];

   if (totMin > 24 * 60) {
      title = [NSString stringWithFormat:@"Release time entered (%02d:%02d) is greater than maximum or 24:00.", [relTime hours], [relTime minutes]];
   }

   NSBeginAlertSheet(title, nil, nil, nil, [self window], self, @selector(invalidReleaseTimeSheetDidEnd:returnCode:contextInfo:), NULL, nil, @"Release time must be between 00:00 and 24:00.");

   return NO;
}

- (void)invalidReleaseTimeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   [NSApp endSheet:sheet];
   [sheet orderOut:nil];
   [[self overlapLastArrivalTimeTextField] selectText:nil];
}

#pragma mark CONTROL VALIDATION

- (void)validateUseSelectedDataButton
{
   if ([[[self lastMonthLineTextField] stringValue] isEqualToString:@""]) {
      [[self useSelectedDataButton] setEnabled:NO];
   } else {
      [[self useSelectedDataButton] setEnabled:YES];
   }
}

#pragma mark ACCESSORS

- (NSForm *)overlapDatesForm { return overlapDatesForm; }

- (NSTextField *)overlapLastArrivalTextField { return overlapLastArrivalTextField; }

- (NSTextField *)overlapLastArrivalTimeTextField { return overlapLastArrivalTimeTextField; }

- (NSPopUpButton *)lastMonthBidPopUpButton { return lastMonthBidPopUpButton; }

- (NSTextField *)lastMonthLineTextField { return lastMonthLineTextField; }

- (NSButton *)useSelectedDataButton { return useSelectedDataButton; }

- (NSButton *)computeOverlapButton { return computeOverlapButton; }

@end
