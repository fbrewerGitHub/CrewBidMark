//
//  CSSubmitBidWindowController.m
//  CrewSchedule
//
//  Created by Mark Ackerman on 7/6/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import "CSSubmitBidWindowController.h"

#import "CSBidPeriod.h"
#import "CSCrewPositions.h"
#import "CSBidFileDownload.h"
// for employee number user defaults key
#import "CSPreferenceKeys.h"


@implementation CSSubmitBidWindowController

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;
{
	NSString *nibName = nil;
	if ([bidPeriod isSecondRoundBid] || [[bidPeriod position] isEqualToString:CSCaptain]) {
		nibName = @"SubmitBid";
	} else {
		if ([bidPeriod isFlightAttendantBid]) {
			nibName = @"BuddySubmitBid";
		} else {
			nibName = @"AvoidanceSubmitBid";
		}
	}
    if (self = [super initWithWindowNibName:nibName bidPeriod:bidPeriod])
    {
        [[self bidFileDownload] setType:CSBidFileDownloadBidSubmissionType];
		NSString *bidEmployeeNumber = [[NSUserDefaults standardUserDefaults] stringForKey:CSPreferencesEmployeeNumberKey];
		[[self bidFileDownload] setBidEmployeeNumber:bidEmployeeNumber];
		NSString *buttonTitle = [NSString stringWithFormat:@"Submit Bid for %@", bidEmployeeNumber];
		[self setSubmitBidButtonTitle:buttonTitle];
		[self setNewEmployeeNumber:bidEmployeeNumber];
    }
    return self;
}

#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)changeEmployeeNumberAction:(id)sender
{
	// remove submit bid dialog
	[NSApp endSheet:[self window]];
	[[self window] orderOut:nil];
	// show change employee number dialog
	[NSApp beginSheet:changeEmployeeNumberWindow modalForWindow:[[self document] windowForSheet] modalDelegate:self didEndSelector:@selector(employeeNumberChangeSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)employeeNumberChangeAction:(id)sender
{
	// update bid employee number
	[[self bidFileDownload] setBidEmployeeNumber:[self newEmployeeNumber]];
	// update submit bid button title
	NSString *buttonTitle = [NSString stringWithFormat:@"Submit Bid for %@", [[self bidFileDownload] bidEmployeeNumber]];
	[self setSubmitBidButtonTitle:buttonTitle];
	// if permanent change to bid employee number, set in user defaults
	if (CSSubmitBidEmployeeNumberChangePermanent == [self employeeNumberChangeType]) {
		[[NSUserDefaults standardUserDefaults] setObject:[[self bidFileDownload] bidEmployeeNumber] forKey:CSPreferencesEmployeeNumberKey];
	}
	// end sheet
	[NSApp endSheet:changeEmployeeNumberWindow returnCode:NSOKButton];
}

- (IBAction)employeeNumberCancelAction:(id)sender
{
	// return new employee number to previous value
	[self setNewEmployeeNumber:[[self bidFileDownload] bidEmployeeNumber]];
	// end sheet
	[NSApp endSheet:changeEmployeeNumberWindow returnCode:NSCancelButton];
}

- (void)employeeNumberChangeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// remove change employee number dialog
	[changeEmployeeNumberWindow orderOut:nil];
	// show submit bid dialog
	[NSApp beginSheet:[self window] modalForWindow:[[self document] windowForSheet] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

#pragma mark
#pragma mark Super Overrides
#pragma mark

- (void)bidFileDownloadDidFinish
{
	// remove sheet (should be progress-style sheet)
    [NSApp endSheet:[self window]];
    [[self window] orderOut:nil];
	// show successful bid alert
	NSString *bidReceiptPath = [[[self bidPeriod] bidDataDirectoryPath] stringByAppendingPathComponent:[[[self bidFileDownload] filesToDownload] lastObject]];
	[self handleDownloadedBidFile:bidReceiptPath];
}

#pragma mark Bid Receipt

- (void)handleDownloadedBidFile:(NSString *)path
{
	// context info is bid file path
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Bid Submitted Successfully"];
	[alert setInformativeText:[NSString stringWithFormat:@"Your bid was successfully submitted, and you have received a receipt (%@).\n\nYou should check your receipt to make sure your bid was correctly received.\n\nTo view your bid receipt, click the \"View Bid Receipt\" button, which will open the bid receipt in your default text editor.\n\nYou may view your most recent bid receipt at any time by selecting the \"Show Bid Receipt\" menu.", [[path lastPathComponent] stringByDeletingPathExtension]]];
	[alert addButtonWithTitle:@"View Bid Receipt"];
	[alert addButtonWithTitle:@"Not Now"];
	[alert beginSheetModalForWindow:[[self document] windowForSheet] 
		modalDelegate:self 
		didEndSelector:@selector(bidReceiptAlertDidEnd:returnCode:contextInfo:)
		contextInfo:[path retain]];
}

- (void)bidReceiptAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   // context info is path to downloaded bid receipt
	if (NSAlertFirstButtonReturn == returnCode) {
		// open bid receipt with default text editor
		[[NSWorkspace sharedWorkspace] openFile:(NSString *)contextInfo];
	}
   // release context info because it was retained in handleDownloadedFile:
   // method
   [(NSString *)contextInfo release];
   // release alert
   [alert release];
   // autorelease self
   [self autorelease];
}

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSString *)submitBidButtonTitle {
    return [[_submitBidButtonTitle retain] autorelease];
}

- (void)setSubmitBidButtonTitle:(NSString *)value {
    if (_submitBidButtonTitle != value) {
        [_submitBidButtonTitle release];
        _submitBidButtonTitle = [value copy];
    }
}

- (NSString *)newEmployeeNumber {
    return _newEmployeeNumber;
}

- (void)setNewEmployeeNumber:(NSString *)value {
    if (_newEmployeeNumber != value) {
        [_newEmployeeNumber release];
        _newEmployeeNumber = [value copy];
    }
}

- (int)employeeNumberChangeType {
    return _employeeNumberChangeType;
}

- (void)setEmployeeNumberChangeType:(int)value {
    if (_employeeNumberChangeType != value) {
        _employeeNumberChangeType = value;
    }
}

@end
