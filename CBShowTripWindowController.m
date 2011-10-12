//
//  CBShowTripWindowController.m
//  CrewBid
//
//  Created by mark on 10/19/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBShowTripWindowController.h"
#import "CBDataModel.h"
#import "CBTrip.h"

@implementation CBShowTripWindowController

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBShowTrip"])
	{
   }
   return self;
}

- (id)initWithDataModel:(CBDataModel *)inDataModel
{
	if (self = [self init])
	{
		dataModel = inDataModel; 
	}
	return self;
}

- (void)awakeFromNib
{
	[[self showTripDialog] center];
	[[self tripTextField] selectText:self];
}

#pragma mark ACTIONS

- (void)showTripButtonAction:(id)sender
{
	NSString * tripNumber = nil;
	NSDictionary * tripDictionary = nil;
	CBTrip * trip = nil;
	NSCalendarDate * date = nil;
	NSString * tripText = nil;
	
	tripNumber = [[[self tripTextField] stringValue] uppercaseString];
	tripDictionary = [dataModel trips];
	trip = [tripDictionary objectForKey:tripNumber];
	
	if (trip)
	{
		date = [dataModel month];
		tripText = [trip descriptionWithDate:date generic:YES];
		[self setTripText:tripText];
		[[self showTripDialog] orderOut:self];
		[[self tripPanel] center];
		[[self tripPanel] setTitle:[NSString stringWithFormat:@"Trip %@", tripNumber]];
		[[self tripPanel] makeKeyAndOrderFront:self];
	}
	
	else
	{
		NSBeginAlertSheet
		(
			@"Trip Not Found",
			@"OK",
			nil,
			nil,
			[self showTripDialog],
			self,
			@selector(errorSheetDidEnd:returnCode:contextInfo:),
			NULL,
			nil,
			@"Could not find trip %@.", tripNumber);
	}
}

- (void)cancelButtonAction:(id)sender
{
	[[self showTripDialog] orderOut:self];
}

#pragma mark DISPLAY TRIP TEXT
- (void)setTripText:(NSString *)text
{
	NSDictionary * textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont userFixedPitchFontOfSize:9.0], NSFontAttributeName, nil];
	[[[self tripTextView] textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:text attributes:textAttributes] autorelease]];
}

#pragma mark CONTROL VALIDATION

- (void)controlTextDidChange:(NSNotification *)notification
{
	// validate showTrip button in showTripDialog
	if ([notification object] == [self tripTextField])
	{
		[self validateShowTripButton];
	}
}

- (void)validateShowTripButton
{
   if ([[[self tripTextField] stringValue] isEqualToString:@""])
	{
      [[self showTripButton] setEnabled:NO];
   }
	else
	{
      [[self showTripButton] setEnabled:YES];
   }
}

#pragma mark ERROR HANDLING

- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
	[[self tripTextField] selectText:self];
	[[self showTripDialog] makeKeyAndOrderFront:self];
}

#pragma mark ACCESSORS

- (NSWindow *)showTripDialog
{
	return [self window];
}
- (NSPanel *)tripPanel
{
	return tripPanel;
}
- (NSTextField *)tripTextField
{
	return tripTextField;
}
- (NSTextView *)tripTextView;
{
	return tripTextView;
}
- (NSButton *)showTripButton
{
	return showTripButton;
}
- (NSButton *)cancelButton
{
	return cancelButton;
}
- (CBDataModel *)dataModel
{
	return dataModel;
}

@end
