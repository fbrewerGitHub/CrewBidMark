//
//  CSNewBidWindowController.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 6/21/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSNewBidWindowController.h"

#import "CSBidPeriod.h"
#import "CSPreferenceKeys.h"
#import "CSCrewPositions.h"
#import "CSBidFileDownload.h"
//#import "CSBidDataImporter.h"
#import "CSBidDataReader.h"
#import "CSMissingTripsWindowController.h"

// TEMP HACK TO READ BID DATA
#import "CBDocument.h"
#import "CBDataModel.h"
#import "CBTripFileReader.h"
#import "CBLineFileReader.h"
#import "CBFATripFileReader.h"
#import "CBFALineFileReader.h"
#import "CBBidFileOpener.h"


@implementation CSNewBidWindowController

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod
{
    if (self = [super initWithWindowNibName:@"NewBid" bidPeriod:bidPeriod])
    {
        // For system 10.3...
//        NSCalendarDate *today = [NSCalendarDate date];
//        NSCalendarDate *thisMonth = [NSCalendarDate 
//            dateWithYear:[today yearOfCommonEra] 
//            month:[today monthOfYear] 
//            day:1 
//            hour:0 
//            minute:0 
//            second:0 
//            timeZone:[NSTimeZone defaultTimeZone]];
//        [self setSelectedMonth:thisMonth];

        [[self bidFileDownload] setType:CSBidFileDownloadBidDataType];
    }
    return self;
}

#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)okButtonAction:(id)sender
{
    // Update user defaults
    [[NSUserDefaults standardUserDefaults] setObject:[[self bidPeriod] position] forKey:CSPreferencesCrewPositionKey];
    [[NSUserDefaults standardUserDefaults] setObject:[[self bidPeriod] base] forKey:CSPreferencesCrewBaseKey];

    // Set bid period month. This is required for System 10.3 because
    // contentObjects binding requires System 10.4.
    [[self bidPeriod] setMonth:[[self selectedMonth] objectForKey:@"month"]];

    // Bid data already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self bidPeriod] bidDocumentPath]])
    {
        [[self bidFileDownload] setProgressText:@"Opening existing bid data..."];
        [[self bidFileDownload] setIsDownloading:YES];
        [self showProgressInterface];
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[[self bidPeriod] bidDocumentPath] display:YES];
        [[self window] orderOut:nil];
        [self autorelease];
    }
    else if ([[self bidPeriod] bidDataExists])
    {
        [[self bidFileDownload] setProgressText:@"Opening existing bid data..."];
        [[self bidFileDownload] setIsDownloading:YES];
        [self showProgressInterface];
        [self bidFileDownloadDidFinish];
    }
    else
    {
        // This will start bid file download and show progress interface
        [super okButtonAction:sender];
    }
}

- (void)bidFileDownloadDidFinish
{
    // TEMP HACK TO READ BID DATA
    CBDocument *newDocument = [[[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"CrewBid document"] retain];

    // create data model
    [newDocument setDataModel:[[[CBDataModel alloc] initWithDocument:newDocument] autorelease]];
    // create month and add to data model
    [[newDocument dataModel] setMonth:[[self bidPeriod] month]];
    // create crew base and add to data model
    [[newDocument dataModel] setCrewBase:[[self bidPeriod] base]];
    // create seat position and add to data model
    [[newDocument dataModel] setCrewPosition:[[self bidPeriod] position]];
    // set data model bid round
    [[newDocument dataModel] setBidRound:[[[self bidPeriod] round] intValue]];
    // create trips and lines, adding to data model
    NSString * tripsFilePath = [[self bidPeriod] tripsDataFilePath];
    NSString * linesFilePath = [[self bidPeriod] linesDataFilePath];
    BOOL isFAFile = [[self bidPeriod] isFlightAttendantBid];
    NSArray *lines = nil;
    if (isFAFile)
    {
        CBFATripFileReader *tr = [[CBFATripFileReader alloc] initWithTripsDataFile:tripsFilePath tripsTextFile:nil];
        [[newDocument dataModel] setTrips:[tr tripsDictionary]];
        [tr release];
        CBFALineFileReader *fr = [[CBFALineFileReader alloc] initWithPath:linesFilePath end:@""];
		[fr setBidMonth:[[self bidPeriod] month]];
        lines = [fr readLines];
        [fr release];
    }
    else
    {
        CBTripFileReader *tripReader = [[CBTripFileReader alloc] initWithTripsFile:tripsFilePath];
		NSDictionary *trips = [tripReader tripsDictionary];
        CBLineFileReader * lineReader = [[CBLineFileReader alloc] initWithLinesFile:linesFilePath trips:trips];
        lines = [lineReader linesArray];
		[[self bidPeriod] setBidLines:lines];
        [lineReader release];
        if ([[self bidPeriod] isSecondRoundBid])
        {
            CSBidDataReader *bdr = [[CSBidDataReader alloc] initWithBidPeriod:[self bidPeriod]];
            [bdr setTrips:trips];
            BOOL result = [bdr addSecondRoundTripsForBidPeriod:[self bidPeriod]];
			
			// If the bid data reader failed to successfully read the second 
			// round trips, display an alert with options to email support, 
			// try again, or cancel.
			
			if (NO == result)
			{
				// Remove downloaded files, so if the user attempts to try 
				// downloading the data again, new data will be downloaded 
				// rather than using the previously downloaded data. This will 
				// eliminate corrupted data as the source of the file reading 
				// error.
				NSFileManager *fm = [NSFileManager defaultManager];
				NSString *path = [[self bidPeriod] bidDataDirectoryPath];
				[fm removeItemAtPath:path error:NULL];
				// Create and display email.
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:@"An unrecoverable error occurred while reading the bid data."];
				[alert setInformativeText:@"Sorry about that.\n\nYou can help me fix this problem by sending an email to CrewBid Support. Information regarding this error will be included in the email automatically.\n\nOr you can try again to download the bid data. If you get an error again, further attempts to download the bid data are unlikely to fix the problem."];
				[alert addButtonWithTitle:@"Email CrewBid support"];
				[alert addButtonWithTitle:@"Try Again"];
				[alert addButtonWithTitle:@"Cancel"];
				[[self window] orderOut:nil];
				// Show the alert.
				NSInteger response = [alert runModal];
				// Send email
				if (NSAlertFirstButtonReturn == response) {
					NSDateFormatter *df = [[NSDateFormatter alloc] init];
					[df setDateFormat:@"MMMM yyyy"];
					NSString *month = [df stringFromDate:[[self bidPeriod] month]];
					[df release];
					// Make sure there is an error reason.
					if (nil == [bdr errorReason]) {
						[bdr setErrorReason:@"Unkonwn error."];
					}
					NSString *body = [NSString stringWithFormat:@"CrewBid failed to parse second round bid for %@ %@ %@.\n\n%@", month, [[self bidPeriod] base], [[self bidPeriod] position], [bdr errorReason]];
					NSString *email = [NSString stringWithFormat:@"mailto:support@macrewsoft.com?subject=CrewBid Bid Data Parsing Failure&body=%@", body];
					email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
					NSURL *mailtoURL = [NSURL URLWithString:email];
					[[NSWorkspace sharedWorkspace] openURL:mailtoURL];
				}
				// Try again.
				else if (NSAlertSecondButtonReturn == response) {
					[self showWindowInterface];
					[[self window] makeKeyAndOrderFront:nil];
					[self setEnableOkButton:YES];
				}
				// In any case, return so that bid data file is not written.
				[alert release];
				[bdr release];
				[tripReader release];
				return;
			}
			
            [[newDocument dataModel] setTrips:[bdr trips]];
            [bdr release];
        }
        else
        {
            [[newDocument dataModel] setTrips:trips];
        }
        [tripReader release];
    }
    [[newDocument dataModel] setLines:lines];
    // set top and bottom freeze indexes
    [[newDocument dataModel] setTopFreezeIndex:-1];
    [[newDocument dataModel] setBottomFreezeIndex:[lines count]];
    // delete trips and lines files
    NSFileManager * fileManager = [NSFileManager defaultManager];
    // write new document to file
    NSString *newDocumentName = [NSString stringWithFormat:@"%@ %@ %@ Rnd %@", 
        [[[self bidPeriod] month] descriptionWithCalendarFormat:@"%b %y"], 
        [[self bidPeriod] base], 
        [[self bidPeriod] positionAbbreviation], 
        [[self bidPeriod] round]];
    NSString *crewBidDir = [[NSApp delegate] valueForKey:@"crewBidDirectoryPath"];
    NSString * newDocumentPath = [crewBidDir stringByAppendingPathComponent:[newDocumentName stringByAppendingPathExtension:@"crewbid"]];
    [newDocument writeToURL:[NSURL fileURLWithPath:newDocumentPath] ofType:@"CrewBid document" error:NULL];
    // release newly created document
    [newDocument release];
    // hide file extension
    NSMutableDictionary * fileExtensionHiddenAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSFileExtensionHidden];
    [fileManager setAttributes:fileExtensionHiddenAttributes ofItemAtPath:newDocumentPath error:NULL];
    // open new document and add to archived array of bid periods
    if ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:newDocumentPath display:YES])
    {
    }
    // set user defaults for most recently opened bid
    [[NSUserDefaults standardUserDefaults] setObject:[newDocumentName stringByAppendingPathExtension:@"crewbid"] forKey:CBMostRecentOpenedBidFileKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CSBidFileDownloadWindowControllerDidFinishNotification object:self];
	
    [[self window] orderOut:nil];
    [self autorelease];
}

#pragma mark
#pragma mark New Bid Selection
#pragma mark

- (NSArray *)monthPopupButtonItems
{
    // Create an array of two dictionaries, with values for this and next month
    // with corresponding strings for display
    NSCalendarDate *today = [NSCalendarDate date];
    NSCalendarDate *thisMonth = [NSCalendarDate 
        dateWithYear:[today yearOfCommonEra] 
        month:[today monthOfYear] 
        day:1 
        hour:0 
        minute:0 
        second:0 
        timeZone:[NSTimeZone defaultTimeZone]];
        
    NSCalendarDate *nextMonth = [NSCalendarDate 
        dateWithYear:[today yearOfCommonEra] 
        month:[today monthOfYear] + 1 
        day:1 
        hour:0 
        minute:0 
        second:0 
        timeZone:[NSTimeZone defaultTimeZone]];
    
    // Because System 10.3 does not have contentObjects binding...
    [self setSelectedMonth:[NSDictionary dictionaryWithObjectsAndKeys:
            nextMonth , @"month",
            [nextMonth descriptionWithCalendarFormat:@"%B %Y"], @"description", nil]];
    
    
    NSArray *monthPopupButtonItems = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            thisMonth, @"month",
            [thisMonth descriptionWithCalendarFormat:@"%B %Y"], @"description", nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            nextMonth , @"month",
            [nextMonth descriptionWithCalendarFormat:@"%B %Y"], @"description", nil], nil];
    return monthPopupButtonItems;
}

- (NSArray *)crewBasePopupButtonMenuItems
{
    NSString *crewBasesPath = [[NSBundle mainBundle] pathForResource:@"Crew Bases" ofType:@"plist"];
    NSArray *crewBasePopupButtonMenuItems = [NSArray arrayWithContentsOfFile:crewBasesPath];
    return crewBasePopupButtonMenuItems;
}

- (NSArray *)crewPositionPopupButtonMenuItems
{
    NSArray *crewPositionPopupButtonMenuItems = [NSArray arrayWithObjects:
        CSCaptain,
        CSFirstOfficer,
        CSFlightAttendant, nil];
    return crewPositionPopupButtonMenuItems;
}

- (NSArray *)bidRoundPopupButtonMenuItems
{
    NSArray *bidRoundPopupButtonMenuItems = [NSArray arrayWithObjects:
        [NSNumber numberWithInt:1],
        [NSNumber numberWithInt:2], nil];
    return bidRoundPopupButtonMenuItems;
}

- (NSDictionary *)selectedMonth {
    return [[_selectedMonth retain] autorelease];
}

- (void)setSelectedMonth:(NSDictionary *)value {
    if (_selectedMonth != value) {
        [_selectedMonth release];
        _selectedMonth = [value copy];
    }
}

#pragma mark
#pragma mark Second Round Missing Trips
#pragma mark

-(void)showAlertForMissingTrips:(NSArray *)missingTrips
{}

@end
