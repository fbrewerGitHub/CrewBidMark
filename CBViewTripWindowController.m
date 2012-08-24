//
//  CBViewTripWindowController.m
//  CrewBid
//
//  Created by mark on 10/19/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import "CBViewTripWindowController.h"
#import "CBDataModel.h"
#import "CBTrip.h"

@implementation CBViewTripWindowController

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBViewTrip"])
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
   [[self window] center];
   // Insetead of a toolbar, the view trip window now has two buttons for
   // viewing a different trip and copying legs to clipboard
//   [self setupToolbar];
   [self showViewTripDialog:nil];
}

- (void)dealloc
{
   [tripStartDate release];
   [super dealloc];
}

#pragma mark TOOLBAR

static NSString *CBViewTripToolbarIdentifier = @"View Trip Toolbar";
static NSString *CBViewTripToolbarTripMenuIdentifier = @"Trip";
static NSString *CBViewTripToolbarCopyLegsMenuItem = @"Copy Legs to Clipboard";
static NSString *CBViewTripToolbarViewDifferentTripMenuItem = @"View a Different Trip...";

- (void)setupToolbar
{
   NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:CBViewTripToolbarIdentifier];
   [toolbar setAllowsUserCustomization:NO];
   [toolbar setAutosavesConfiguration:NO];
   [toolbar setDisplayMode:NSToolbarDisplayModeLabelOnly];
    // Suppress complier warning for incompatible pointer type. Self is not
    // declared as NSToolbarDelegate since that protocol was introduced in
    // OS 10.6.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wno-protocol"
    [toolbar setValue:self forKey:@"delegate"];
//   [toolbar setDelegate:self];
#pragma clang diagnostic pop
   [[self window] setToolbar:toolbar];
   [toolbar release];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemId willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar
{
   NSToolbarItem *tbItem = nil;
   if ([itemId isEqualToString:CBViewTripToolbarTripMenuIdentifier]) {
      // create toolbar item (a menu in this case) and set label
      tbItem = [[NSToolbarItem alloc] initWithItemIdentifier:CBViewTripToolbarTripMenuIdentifier];
      [tbItem setLabel:CBViewTripToolbarTripMenuIdentifier];
      // create menu for toolbar item
      NSMenu *tbMenu = [[NSMenu alloc] init];
      // add copy legs menu item
      NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:CBViewTripToolbarCopyLegsMenuItem action:@selector(copyLegs:) keyEquivalent:@""];
      [menuItem setTarget:self];
      [tbMenu addItem:menuItem];
      [menuItem release];
      // add separator
      [tbMenu addItem:[NSMenuItem separatorItem]];
      // add view different trip menu item
      menuItem = [[NSMenuItem alloc] initWithTitle:CBViewTripToolbarViewDifferentTripMenuItem action:@selector(showViewTripDialog:) keyEquivalent:@""];
      [menuItem setTarget:self];
      [tbMenu addItem:menuItem];
      [menuItem release];
      // toolbar menu form representation
      NSMenuItem *menuFormRep = [[NSMenuItem alloc] init];
      [menuFormRep setSubmenu:tbMenu];
      [menuFormRep setTitle:[tbItem label]];
      [tbItem setMenuFormRepresentation:menuFormRep];
      [menuFormRep release];
   }
   return tbItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
   return [NSArray arrayWithObject:CBViewTripToolbarTripMenuIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
   return [NSArray arrayWithObject:CBViewTripToolbarTripMenuIdentifier];
}

#pragma mark ACTIONS

- (void)showViewTripDialog:(id)sender
{
   [[self tripNumberTextField] selectText:nil];
   [[self window] makeKeyAndOrderFront:nil];
   [NSApp beginSheet:[self viewTripDialog] modalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)copyLegs:(id)sender
{
   if ([self trip] && [self tripStartDate]) {
      NSString *clipboardText = [[self trip] clipboardTextWithStartDate:[self tripStartDate]];
      if (0 != [clipboardText length]) {
         [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
         [[NSPasteboard generalPasteboard] setString:[clipboardText substringToIndex:[clipboardText length] - 1] forType:NSStringPboardType];
      }
   }
}

- (void)viewTripButtonAction:(id)sender
{
   // remove view trip dialog sheet
   [NSApp endSheet:[self viewTripDialog]];
   [[self viewTripDialog] orderOut:nil];
   [[self window] makeKeyAndOrderFront:nil];
   // change trip number text view to uppercase string
   NSString *tripNumber = [[[self tripNumberTextField] stringValue] uppercaseString];
   [[self tripNumberTextField] setStringValue:tripNumber];
   // get trip
	NSDictionary * tripDictionary = [dataModel trips];
	CBTrip *theTrip = [tripDictionary objectForKey:tripNumber];
   [self setTrip:theTrip];
   // get start date
   int lastDay = [[[[self dataModel] month] dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0] dayOfMonth];
   int day = [[self startDayTextField] intValue];
   if (day < 1) {
      day = 1;
   } else if (day > lastDay) {
      day = lastDay;
   }
   NSCalendarDate *theDate = [[[self dataModel] month] dateByAddingYears:0 months:0 days:day - 1 hours:0 minutes:0 seconds:0];
   [self setTripStartDate:theDate];
   // if trip exists, put text in trip text view
	if ([self trip])
	{
		NSString *tripText = [trip descriptionWithDate:[self tripStartDate] generic:NO];
		[self setTripText:tripText];
		[[self window] setTitle:[NSString stringWithFormat:@"Trip %@", [[self trip] number]]];
	}
	// show alert if trip could not be found
	else
	{
		NSBeginAlertSheet
		(
			@"Trip Not Found",
			@"OK",
			nil,
			nil,
			[self window],
			self,
			@selector(errorSheetDidEnd:returnCode:contextInfo:),
			NULL,
			nil,
			@"Could not find trip %@.", [[self tripNumberTextField] stringValue]);
	}
}

- (void)cancelButtonAction:(id)sender
{
   [NSApp endSheet:[self viewTripDialog]];
	[[self viewTripDialog] orderOut:nil];
   [[self window] makeKeyAndOrderFront:nil];
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
	// validate showTrip button in view trip dialog sheet
	if ([notification object] == [self tripNumberTextField])
	{
		[self validateViewTripButton];
	}
}

- (void)validateViewTripButton
{
   [[self viewTripButton] setEnabled:(4 == [[[self tripNumberTextField] stringValue] length])];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
   BOOL enable = YES;
   if ([[menuItem title] isEqualToString:CBViewTripToolbarCopyLegsMenuItem]) {
      enable = ![[self trip] isReserve] && [[[self tripTextView] string] length] > 0;
   }
   return enable;
}

#pragma mark ERROR HANDLING

- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
   [NSApp endSheet:sheet];
   [sheet orderOut:nil];
   [self showViewTripDialog:nil];
}

#pragma mark ACCESSORS

- (NSWindow *)viewTripDialog
{
	return viewTripDialog;
}
- (NSTextField *)tripNumberTextField
{
   return tripNumberTextField;
}
- (NSTextField *)startDayTextField
{
   return startDayTextField;
}
- (NSTextView *)tripTextView;
{
	return tripTextView;
}
- (NSButton *)viewTripButton
{
	return viewTripButton;
}
- (NSButton *)cancelButton
{
	return cancelButton;
}
- (CBDataModel *)dataModel
{
	return dataModel;
}
- (CBTrip *)trip
{
   return trip;
}
- (void)setTrip:(CBTrip *)inValue
{
   trip = inValue;
}
- (NSCalendarDate *)tripStartDate
{
   return tripStartDate;
}
- (void)setTripStartDate:(NSCalendarDate *)inValue
{
   [inValue retain];
   [tripStartDate release];
   tripStartDate = inValue;
}

@end
