//
//  CBNewBidWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBNewBidWindowController.h"
#import "CBProgressWindowController.h"
#import "CBDocument.h"
#import "CBDataModel.h"
#import "CBDataFileUnzip.h"
#import "CBTripFileReader.h"
#import "CBLineFileReader.h"
#import "CBFATripFileReader.h"
#import "CBFALineFileReader.h"
#import "CBNotificationAndKeyStrings.h"
#import "CBBidFileOpener.h"

// FOR TESTING
#import "CBBidFileDownload.h"

NSString * BID_DATA_FILE_REQUEST = @"REQUEST=ZIPPACKET&CREDENTIALS=%@&NAME=";


#pragma mark USER DEFAULT KEYS
NSString * CBCrewBaseKey = @"Crew Base";
//NSString * CBSeatPositionKey = @"Seat Position";
NSString * CBMostRecentOpenedBidFileKey = @"Most Recent Opened Bid File";

#pragma mark NOTIFICATION AND KEYS
NSString * CBNewBidControllerDidFinish = @"CBNewBidController Did Finish Notification";

@implementation CBNewBidWindowController

#pragma mark INITIALIZATION

- (id)initWithCrewBidDirectory:(NSString *)path
{
   if (self = [super initWithWindowNibName:@"CBBidSelect"]) {
      [self setCrewBidDirectoryPath:path];
      [self setShouldCascadeWindows:NO];
   }
   return self;
}

- (void)awakeFromNib
{
   // set up month popup button
   [self initializeMonthPopUpButton];
   // set up crew base popup button
   [self initializeBasePopUpButton];
   // set up seat position popup button
   [self initializeSeatPopUpButton];
   // initialze round popup button
   [self initializeRoundPopUpButton];
   // center window 
   [[self window] center];
}

- (void)initializeMonthPopUpButton
{
   [[self monthPopUpButton] removeAllItems];
   NSCalendarDate *now = [NSCalendarDate calendarDate];
   NSCalendarDate *thisMonthDate = [NSCalendarDate 
      dateWithYear:[now yearOfCommonEra] 
      month:[now monthOfYear] 
      day:1 
      hour:0 
      minute:0 
      second:0 
      timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-21600]];
   NSCalendarDate *nextMonthDate = [thisMonthDate 
      dateByAddingYears:0 
      months:1 
      days:0 
      hours:0 
      minutes:0 
      seconds:0];
   [[self monthPopUpButton] addItemWithTitle:[thisMonthDate descriptionWithCalendarFormat:@"%B %Y"]];
   NSMenuItem *monthMenuItem = [[self monthPopUpButton] itemAtIndex:0];
   [monthMenuItem setRepresentedObject:thisMonthDate];
   [[self monthPopUpButton] addItemWithTitle:[nextMonthDate descriptionWithCalendarFormat:@"%B %Y"]];
   monthMenuItem = (NSMenuItem *)[[self monthPopUpButton] itemAtIndex:1];
   [monthMenuItem setRepresentedObject:nextMonthDate];
   [[self monthPopUpButton] selectItemAtIndex:1];
}

- (void)initializeBasePopUpButton
{ 
   NSArray * crewBases = [NSArray arrayWithObjects:@"BWI", @"DAL", @"HOU", @"MCO", @"MDW", @"OAK", @"PHX", nil];
   [[self basePopUpButton] removeAllItems];
   [[self basePopUpButton] addItemsWithTitles:crewBases];
   [[self basePopUpButton] selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:CBCrewBaseKey]];
}

- (void)initializeSeatPopUpButton
{
   [[self seatPopUpButton] removeAllItems];
   NSArray *seats = [NSArray arrayWithObjects:@"Captain", @"First Officer", @"Flight Attendant", nil];
   [[self seatPopUpButton] addItemsWithTitles:seats];
   NSArray *abbreviatedSeats = [NSArray arrayWithObjects:@"CA", @"FO", @"FA", nil];
//   NSArray *seatChars = [NSArray arrayWithObjects:@"C", @"F", @"A", nil];
   int i = 0;
   for (i = 0; 
        i < [abbreviatedSeats count] && 
//            i < [seatChars count] && 
            i < [[[self seatPopUpButton] itemArray] count]; 
        ++i) {
      NSMenuItem *menuItem = [[[self seatPopUpButton] itemArray] objectAtIndex:i];
      [menuItem setRepresentedObject:[abbreviatedSeats objectAtIndex:i]];
   }
   [[self seatPopUpButton] selectItemWithTitle:[[NSUserDefaults standardUserDefaults] objectForKey:CBCrewPositionKey]];
}

- (void)initializeRoundPopUpButton
{
//	[[self seatPopUpButton] setAutoenablesItems:NO];
   NSCalendarDate *now = [NSCalendarDate calendarDate];
   int nowDayOfMonth = [now dayOfMonth];
   if ([[(NSMenuItem *)[[self seatPopUpButton] selectedItem] title] isEqualToString:@"Flight Attendant"])
	{
		if (nowDayOfMonth > 10) {
			[[self roundPopUpButton] selectItemWithTitle:@"2"];
		}
   }
}

- (void)dealloc
{
   [crewBidDirectoryPath release];
   [progressController release];
   [bidMonth release];
   [crewBase release];
   [seatPosition release];
   [super dealloc];
}

#pragma mark MENU VALIDATION

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	BOOL validateMenuItem = YES;
	
	// disable round 2 bidding for Captain and First Officer
	if ([[(NSMenuItem *)menuItem title] isEqualToString:@"2"]) {
		if (![[[self seatPopUpButton] titleOfSelectedItem] isEqualToString:@"Flight Attendant"]) {
			validateMenuItem = NO;
		}
	}
	return validateMenuItem;
}

#pragma mark ACTIONS

- (IBAction)okButtonAction:(id)sender
{
   // get document file name from user selections
   NSString * documentFileName = [self documentFileName];

   // if document file already exists, open document file
   NSString * documentFilePath = [[self crewBidDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.crewbid", documentFileName]];

   if ([[NSFileManager defaultManager] fileExistsAtPath:documentFilePath]) {
   
      CBBidFileOpener * opener = [[CBBidFileOpener alloc] initWithFile:documentFilePath modalWindow:[self window] progressController:nil];
      [opener openFile];
      [opener release];
   
      // remove window
      [[self window] orderOut:nil];

      // post notification which will be received by app controller, which will
      // release new bid controller (this object)
      [[NSNotificationCenter defaultCenter] postNotificationName:CBNewBidControllerDidFinish object:self userInfo:nil];

   // if document file doesn't exist, download data file
   } else {
      // bid month 
      NSCalendarDate * month = [(NSMenuItem *)[[self monthPopUpButton] selectedItem] representedObject];
      [self setBidMonth:month];
      // crew base
      NSString * bidCrewBase = [[self basePopUpButton] titleOfSelectedItem];
      [self setCrewBase:bidCrewBase];
      // seat position
      NSString * bidSeatPosition = [[self seatPopUpButton] titleOfSelectedItem];
      [self setSeatPosition:bidSeatPosition];
      // get data file name from user selections
      NSString * dataFileName = [self dataFileName];
      
      NSString * bidRequestBody = [BID_DATA_FILE_REQUEST stringByAppendingString:dataFileName];

      if (nil == bidFileDownload) {
         bidFileDownload = [[CBBidFileDownload alloc] initWithBidDataFile:dataFileName directory:[self crewBidDirectoryPath] requestBody:bidRequestBody owner:self];
      } else {
         // update bid data file name and bid request body
         [[self bidFileDownload] setFilename:dataFileName];
         [[self bidFileDownload] setRequestBody:bidRequestBody];
      }
      
      // start bid file download
      [[self bidFileDownload] showCredentialWindow];
   }
}

- (IBAction)cancelButtonAction:(id)sender
{
   // remove window
   [[self window] orderOut:nil];
   // post notification which will be received by app controller, which will
   // release new bid controller (this object)
   [[NSNotificationCenter defaultCenter] postNotificationName:CBNewBidControllerDidFinish object:self userInfo:nil];
}

- (IBAction)basePopUpButtonAction:(id)sender
{
   // put crew base in user defaults
   [[NSUserDefaults standardUserDefaults] setObject:[[self basePopUpButton] titleOfSelectedItem] forKey:CBCrewBaseKey];
}
- (IBAction)seatPopUpButtonAction:(id)sender
{
   // put position in user defaults
   [[NSUserDefaults standardUserDefaults] setObject:[[self seatPopUpButton] titleOfSelectedItem] forKey:CBCrewPositionKey];
	// select round 1 and disable round 2 menu items foa all except flight attendant
	if (![[[self seatPopUpButton] titleOfSelectedItem] isEqualToString:@"Flight Attendant"]) {
		NSMenuItem *round1 = [[self roundPopUpButton] itemWithTitle:@"1"];
		NSMenuItem *round2 = [[self roundPopUpButton] itemWithTitle:@"2"];
		[[self roundPopUpButton] selectItem:round1];
		[round2 setEnabled:NO];
	}
}

- (IBAction)roundPopUpButtonAction:(id)sender
{
	// this method exists only so that validateMenuItem: method will be called,
	// so do nothing
	return;
}

#pragma mark DOCUMENT CREATION

- (void)openDocumentWithDataFile:(NSString *)path
{
   NSString * documentName = [self documentFileName];
   NSCalendarDate * month = [self bidMonth];
   NSString * bidCrewBase = [self crewBase];
   NSString * bidSeatPosition = [self seatPosition];
   NSString * crewBidDirectory = [self crewBidDirectoryPath];

   // make new document
   CBDocument * newDocument = [[[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"CrewBid document"] retain];

   // create data model from zipped data file
   CBDataFileUnzip * fileUnzip = [[CBDataFileUnzip alloc] initWithDataFile:path];

   // unzip file, if successful, continue
   if ([fileUnzip unzipDataFile]) {
      // release unzip
      [fileUnzip release];
      // create data model
      [newDocument setDataModel:[[[CBDataModel alloc] initWithDocument:newDocument] autorelease]];
      // create month and add to data model
      [[newDocument dataModel] setMonth:month];
      // create crew base and add to data model
      [[newDocument dataModel] setCrewBase:bidCrewBase];
      // create seat position and add to data model
      [[newDocument dataModel] setCrewPosition:bidSeatPosition];
      // set data model bid round
      [[newDocument dataModel] setBidRound:[[[self roundPopUpButton] titleOfSelectedItem] intValue]];
      // create trips and lines, adding to data model
      NSString * tripsFilePath = [crewBidDirectory stringByAppendingPathComponent:@"TRIPS"];
      NSString * linesFilePath = [crewBidDirectory stringByAppendingPathComponent:@"PS"];
      BOOL isFAFile = ('A' == [[path lastPathComponent] characterAtIndex:0]);
      NSDictionary *trips = nil;
      NSArray *lines = nil;
      if (isFAFile)
      {
         CBFATripFileReader *tr = [[CBFATripFileReader alloc] initWithTripsDataFile:tripsFilePath tripsTextFile:nil];
         trips = [tr tripsDictionary];
         [tr release];
         CBFALineFileReader *fr = [[CBFALineFileReader alloc] initWithPath:linesFilePath end:@""];
         lines = [fr readLines];
         [fr release];
      }
      else
      {
         CBTripFileReader * tripReader = [[CBTripFileReader alloc] initWithTripsFile:tripsFilePath];
         trips = [tripReader tripsDictionary];
         [tripReader release];
		  CBLineFileReader * lineReader = [[CBLineFileReader alloc] initWithLinesFile:linesFilePath trips:trips];
         lines = [lineReader linesArray];
         [lineReader release];
      }
      [[newDocument dataModel] setTrips:trips];
      [[newDocument dataModel] setLines:lines];
      // set top and bottom freeze indexes
      [[newDocument dataModel] setTopFreezeIndex:-1];
      [[newDocument dataModel] setBottomFreezeIndex:[lines count]];
      // delete trips and lines files
      NSFileManager * fileManager = [NSFileManager defaultManager];
      [fileManager removeFileAtPath:tripsFilePath handler:nil];
      [fileManager removeFileAtPath:linesFilePath handler:nil];
      // write new document to file
      NSString * newDocumentPath = [crewBidDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.crewbid", documentName]];
      [newDocument writeToFile:newDocumentPath ofType:@"CrewBid document"];
      // hide file extension
      NSMutableDictionary * fileExtensionHiddenAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden];
      [fileManager changeFileAttributes:fileExtensionHiddenAttributes atPath:newDocumentPath];
      // set user defaults for most recently opened bid
      [[NSUserDefaults standardUserDefaults] setObject:[documentName stringByAppendingPathExtension:@"crewbid"] forKey:CBMostRecentOpenedBidFileKey];
      // release newly created document
      [newDocument release];
      // open new document
      CBBidFileOpener * opener = [[CBBidFileOpener alloc] initWithFile:newDocumentPath modalWindow:[self window] progressController:[[self bidFileDownload] progressController]];
      [opener openFile];
      [opener release];
      // post notification which will be received by app controller, which will
      // release new bid controller (this object)
      [[NSNotificationCenter defaultCenter] postNotificationName:CBNewBidControllerDidFinish object:self userInfo:nil];

  // unzip unsuccessful: notify user if problem with reading and unzipping data file
   } else {
      NSString * errorTitle = @"Error reading bid data";
      NSString * errorMessage = [NSString stringWithFormat:@"CrewBid could not read bid data for %@.\n\nReason: Bid data file could not be found or an error occurred while reading data file", [self documentFileName]];
      [self handleErrorTitle:errorTitle message:errorMessage];
   }
}

#pragma mark ERROR HANDLING

- (void)handleErrorTitle:(NSString *)title message:(NSString *)message
{
   // remove progress sheet, which was shown by bid session
   [NSApp endSheet:[[[self bidFileDownload] progressController] window]];
   [[[[self bidFileDownload] progressController] window] orderOut:nil];
   // show alert sheet with error title and message
   NSBeginAlertSheet(title, @"Try Again", @"Cancel", nil, [self window], self, @selector(errorSheetDidEnd:returnCode:contextInfo:), NULL, nil, message);
}

- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)conetextInfo
{
   switch (returnCode)
   {
      // try again, do nothing
      case NSAlertDefaultReturn:
         break;

      // cancel
      case NSAlertAlternateReturn:
         // post notification which will be received by app controller, which will
         // release new bid controller (this object)
         [[self window] orderOut:nil];
         [[NSNotificationCenter defaultCenter] postNotificationName:CBNewBidControllerDidFinish object:self userInfo:nil];
         break;

      default:
         break;
   }
}

#pragma mark BID FILE WINDOW CONTROLLER METHODS

- (void)handleDownloadedBidFile:(NSString *)path
{
   [[self bidFileDownload] setProgressText:[NSString stringWithFormat:@"Reading %@...", [self documentFileName]]];
   [self openDocumentWithDataFile:path];
}

#pragma mark FILE AND PATH METHODS

- (NSString *)dataFileName
{
   // first character of seat position
   char seatChar = [[[self seatPopUpButton] titleOfSelectedItem] characterAtIndex:0u];

   // ***** FLIGHT ATTENDANT TESTING *****
   if ([[self seatPosition] isEqualToString:@"Flight Attendant"])
   {
      seatChar = 'A';
   }
   
   // title of crew base
   NSString *base = [[self basePopUpButton] titleOfSelectedItem];
   // selected month, converted to hex
   NSCalendarDate *selectedMonth = [(NSMenuItem *)[[self monthPopUpButton] selectedItem] representedObject];
   int selectedMonthIndex = [selectedMonth monthOfYear];
   NSString *month = [NSString stringWithFormat:@"%X", selectedMonthIndex];

   // D for first round bid, B for second round bid
   char bidRoundChar = 'D';
   if ([[self roundPopUpButton] indexOfSelectedItem] > 0) {
      bidRoundChar = 'B';
   }
   return [NSString stringWithFormat:@"%c%c%@%@.737", seatChar, bidRoundChar, base, month];
}

- (NSString *)documentFileName
{
   NSCalendarDate *month = [[[self monthPopUpButton] selectedItem] representedObject];
   NSString *base = [[self basePopUpButton] titleOfSelectedItem];
   NSString *seat = [[[self seatPopUpButton] selectedItem] representedObject];
   NSString *round = [NSString stringWithFormat:@"Rnd %@", [[self roundPopUpButton] titleOfSelectedItem]];

   return [NSString stringWithFormat:@"%@ %@ %@ %@", [month descriptionWithCalendarFormat:@"%b %y"], base, seat, round];
}

- (NSString *)textFileName
{
   // title of crew base
   NSString * base = [[self basePopUpButton] titleOfSelectedItem];
   return [NSString stringWithFormat:@"%@FAP.TXT", base];
}

#pragma mark ACCESSORS

- (NSPopUpButton *)monthPopUpButton { return monthPopUpButton; }

- (NSPopUpButton *)basePopUpButton { return basePopUpButton; }

- (NSPopUpButton *)seatPopUpButton { return seatPopUpButton; }

- (NSPopUpButton *)roundPopUpButton { return roundPopUpButton; }

- (NSString *)crewBidDirectoryPath { return crewBidDirectoryPath; }
- (void)setCrewBidDirectoryPath:(NSString *)inValue
{
   if (crewBidDirectoryPath != inValue) {
      [crewBidDirectoryPath release];
      crewBidDirectoryPath = [inValue retain];
   }
}

- (CBBidFileDownload *)bidFileDownload { return bidFileDownload; }

- (CBProgressWindowController *)progressController { return progressController; }

- (NSCalendarDate *)bidMonth { return bidMonth; }
- (void)setBidMonth:(NSCalendarDate *)inValue
{
   if (bidMonth != inValue) {
      [bidMonth release];
      bidMonth = [inValue retain];
   }
}

- (NSString *)crewBase { return crewBase; }
- (void)setCrewBase:(NSString *)inValue
{
   if (crewBase != inValue) {
      [crewBase release];
      crewBase = [inValue retain];
   }
}

- (NSString *)seatPosition { return seatPosition; }
- (void)setSeatPosition:(NSString *)inValue
{
   if (seatPosition != inValue) {
      [seatPosition release];
      seatPosition = [inValue retain];
   }
}

@end
