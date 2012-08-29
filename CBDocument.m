//
//  CBDocument.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBDocument.h"
#import "CBMainWindowController.h"
#import "CBDataModel.h"
#import "CSBidPeriod.h"
#import "CBProgressWindowController.h"
// for path to CrewBid directory
#import "CBAppController.h"

// show text files
#import "CSTextFileWindowController.h"
// bid awards
#import "CSRetrieveBidAwardsWindowController.h"
#import "CSPreferenceKeys.h"
// bid submission
#import "CSBidPeriod.h"
#import "CSSubmitBidWindowController.h"
// bid receipts
#import "CSBidReceiptWindowController.h"
#import "CSBidReceipt.h"

 
@implementation CBDocument

#pragma mark INITIALIZATION


+ (void)initialize {

   static BOOL initialized = NO;
   if (!initialized && (self == [CBDocument class])) {
      [self setVersion:1];
      initialized = YES;
   }
}


// no override of NSDocument required for initialization

- (void)dealloc
{
   [dataModel release];
   [super dealloc];
}

#pragma mark ACTIONS

//- (IBAction)saveDocument:(id)sender
//{
////   CBProgressWindowController * progressController = [[CBProgressWindowController alloc] init];
////   [progressController setProgressText:[NSString stringWithFormat:@"Saving %@...", [[[self fileName] lastPathComponent] stringByDeletingPathExtension]]];
////   [progressController disableCancelButton];
////   [NSApp beginSheet:[progressController window] modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:NULL contextInfo:nil];
//   [super saveDocument:sender];
////   [NSApp endSheet:[progressController window]];
////   [[progressController window] close];
////   [progressController release];
//}

- (void)saveChoices:(id)sender
{
   NSWindow * mainWindow = nil;
   NSSavePanel * savePanel = nil;
      
   if ((mainWindow = [[self mainWindowController] window]))
   {
      savePanel = [NSSavePanel savePanel];
      [savePanel beginSheetForDirectory:[[NSApp delegate] crewBidDirectoryPath] file:nil modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(choicesSavePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
   }
   // else raise exception
}

- (void)applyChoices:(id)sender
{
   NSWindow * mainWindow = nil;
   NSOpenPanel * openPanel = nil;
   
   if ((mainWindow = [[self mainWindowController] window]))
   {
      openPanel = [NSOpenPanel openPanel];
      [openPanel setPrompt:@"Apply"];
      [openPanel beginSheetForDirectory:[[NSApp delegate] crewBidDirectoryPath] file:nil types:[NSArray arrayWithObject:@"plist"] modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(choicesOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
   }
}

- (void)choicesSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   NSString * pathToChoicesFile = nil;
   
   if (NSOKButton == returnCode)
   {
      pathToChoicesFile = [sheet filename];
      [[self dataModel] saveChoices:pathToChoicesFile];
   }
}

- (void)choicesOpenPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   NSString * pathToChoicesFile = nil;
   
   if (NSOKButton == returnCode)
   {
      pathToChoicesFile = [sheet filename];
      [[self dataModel] applyChoices:pathToChoicesFile];
      
      // Hack to get overnight cities to update
      [[self mainWindowController] initializeOvernightCitiesTabItem];
   }
}

- (void)showCoverLetter:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[self dataModel] bidPeriod] coverFilePath]];
//    [CSTextFileWindowController 
//        showTextFile:[[[self dataModel] bidPeriod] coverFilePath] 
//        title:[NSString stringWithFormat:@"Cover Letter for %@", [self displayName]]];
}

- (void)showSeniorityList:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[self dataModel] bidPeriod] seniorityFilePath]];
//    [CSTextFileWindowController 
//        showTextFile:[[[self dataModel] bidPeriod] seniorityFilePath] 
//        title:[NSString stringWithFormat:@"Seniority List for %@", [self displayName]]];
}

- (void)showBidLinesText:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[self dataModel] bidPeriod] linesTextFilePath]];
//    [CSTextFileWindowController 
//        showTextFile:[[[self dataModel] bidPeriod] linesTextFilePath] 
//        title:[NSString stringWithFormat:@"Bid Lines for %@", [self displayName]]];
}

- (void)showTripsText:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[self dataModel] bidPeriod] tripsTextFilePath]];
//    [CSTextFileWindowController 
//        showTextFile:[[[self dataModel] bidPeriod] tripsTextFilePath] 
//        title:[NSString stringWithFormat:@"Trips for %@", [self displayName]]];
}

// Bid Awards

- (IBAction)retrieveBidAwards:(id)sender
{
    CSBidPeriod *bidPeriod = [[self dataModel] bidPeriod];
    // show bid awards if it already exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:[bidPeriod bidAwardFilePath]])
    {
        [self showBidAwards:nil];
    }
    // otherwise retrieve bid awards
    else
    {
        CSRetrieveBidAwardsWindowController *rbawc = [[CSRetrieveBidAwardsWindowController alloc] initWithBidPeriod:bidPeriod];
        [rbawc setDocument:self];
        [rbawc setShouldCloseDocument:NO];
        
        [NSApp 
            beginSheet:[rbawc window] 
            modalForWindow:[self windowForSheet] 
            modalDelegate:nil 
            didEndSelector:NULL 
            contextInfo:nil];
    }
}

- (IBAction)showBidAwards:(id)sender
{
    CSBidPeriod *bidPeriod = [[self dataModel] bidPeriod];
    NSString *bidAwardFilePath = [bidPeriod bidAwardFilePath];
    
    // Bid awards file exists, so show it
    if ([[NSFileManager defaultManager] fileExistsAtPath:bidAwardFilePath])
    {
		[[NSWorkspace sharedWorkspace] openFile:bidAwardFilePath];
//        NSString *title = [NSString stringWithFormat:@"Bid Awards for %@", [bidPeriod displayName]];
//        CSTextFileWindowController *tfwc = [[CSTextFileWindowController alloc] initWithTextFilePath:bidAwardFilePath title:title];
//        [[tfwc window] center];
//        [tfwc showWindow:nil];
//        
//        // Highligh and scroll to employee number and bid award if it's in the
//        // bid award text
//        NSTextView *textView = [tfwc textView];
//        NSString *text = [[textView textStorage] string];
//        NSString *empNum = [[NSUserDefaults standardUserDefaults] objectForKey:CSPreferencesEmployeeNumberKey];
//        NSRange empNumRange = [text rangeOfString:empNum];
//        if (NSNotFound != empNumRange.location)
//        {
//            NSScanner *scanner = [NSScanner scannerWithString:text];
//            [scanner setScanLocation:empNumRange.location + empNumRange.length];
//            [scanner scanInt:nil];
//            unsigned bidNumEndIdx = [scanner scanLocation];
//            NSRange empNumWithBidAwdRange = NSMakeRange(empNumRange.location, bidNumEndIdx - empNumRange.location);
//            [textView setSelectedRange:empNumWithBidAwdRange];
//            [textView scrollRangeToVisible:empNumWithBidAwdRange];
//        }
    }
    // Bid awards have not been retrieved yet, so show alert
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Bid awards have not been retrieved."];
        [alert setInformativeText:[NSString stringWithFormat:@"Bid awards for %@ have not been retrieved. You must retrieve the bid awards before they can be shown.\n\nClick the Retrieve button to retrieve the bid awards.", [self displayName]]];
        [alert addButtonWithTitle:@"Retrieve Bid Awards"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert 
            beginSheetModalForWindow:[self windowForSheet] 
            modalDelegate:self 
            didEndSelector:@selector(bidAwardsAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)bidAwardsAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (NSAlertFirstButtonReturn == returnCode)
    {
        [[alert window] orderOut:nil];
        [self retrieveBidAwards:nil];
    }
    else
    {
        [[alert window] orderOut:nil];
    }
    [alert release];
}

// bid submission

- (void)submitBid:(id)sender
{
    // Don't allow bid submission if subscription required.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CBSubscriptionRequiredKey]) {
        NSBeep();
        return;
    }
    
	// create bid period
	CSBidPeriod *bidPeriod = [[CSBidPeriod alloc] init];
	[bidPeriod setMonth:[[self dataModel] month]];
	[bidPeriod setBase:[[self dataModel] crewBase]];
	[bidPeriod setPosition:[[self dataModel] crewPosition]];
	[bidPeriod setRound:[NSNumber numberWithInt:[[self dataModel] bidRound]]];
	[bidPeriod setBidLines:[[self dataModel] lines]];
	// create submit bid window controller
	CSSubmitBidWindowController *sbwc = [[CSSubmitBidWindowController alloc] initWithBidPeriod:bidPeriod];
	[sbwc setDocument:self];
	[bidPeriod release];
	// show submit bid window as sheet
	[NSApp beginSheet:[sbwc window] modalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)showBidReceipt:(id)sender
{
	// even if there is only one bid receipt, show the select bid receipt
	// dialog, so that the user can see for whom and by whom the bid was
	// submitted
	CSBidReceiptWindowController *brwc = [[CSBidReceiptWindowController alloc] initWithBidPeriod:[[self dataModel] bidPeriod]];
	[brwc setDelegate:self];
	[NSApp 
		beginSheet:[brwc window] 
		modalForWindow:[self windowForSheet] 
		modalDelegate:self 
		didEndSelector:@selector(showBidReceiptSheetDidEnd:returnCode:contextInfo:)
		contextInfo:brwc];
}

- (void)bidReceiptWindowController:(CSBidReceiptWindowController *)controller didSelectBidReceiptAtPath:(NSString *)bidReceiptPath
{
	[NSApp endSheet:[controller window] returnCode:NSOKButton];
}

- (void)showBidReceiptSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	// context info is CSBidReceiptWindowController *
	if (NSOKButton == returnCode) {
		NSString *selectedBidReceiptPath = [[(CSBidReceiptWindowController *)contextInfo selectedBidReceipt] path];
		[[NSWorkspace sharedWorkspace] openFile:selectedBidReceiptPath];
	}
	[sheet close];
	[(CSBidReceiptWindowController *)contextInfo release];
}

- (void)sortByColumns:(id)sender
{
    NSLog(@"CBDocument sortByColumns: %@", [(NSButton *)sender state] == NSOnState ? @"YES" : @"NO");
    
    if (NSOffState == [(NSButton *)sender state])
    {
        NSTableView *linesTableView = [[self mainWindowController] linesTableView];
        NSTableColumn *orderColumn = [linesTableView tableColumnWithIdentifier:@"number"];
//        [orderColumn setSortDescriptorPrototype:nil];
        [orderColumn addObserver:self forKeyPath:@"sortDescriptorPrototype" options:NSKeyValueObservingOptionNew context:nil];
        [orderColumn setSortDescriptorPrototype:[orderColumn sortDescriptorPrototype]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"sortDescriptorPrototype"])
    {
        NSString *identifier = [object valueForKey:@"identifier"];
        NSSortDescriptor *sort = [object valueForKey:@"sortDescriptorPrototype"];
        NSLog(@"%@ column sort descriptor: %@", identifier, sort ? [sort key] : @"nil");
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark WINDOW MANAGEMENT

- (void)makeWindowControllers
{
   CBMainWindowController * mainWindowController = [[CBMainWindowController alloc] init];
   [self addWindowController:mainWindowController];
   [mainWindowController release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

#pragma mark MENU MANAGEMENT

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    // Disable bid submit menu item if subscription required.
    if (@selector(submitBid:) == [menuItem action]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CBSubscriptionRequiredKey]) {
            return NO;
        }
    }
    
	BOOL enable = YES;
	int menuItemTag = [menuItem tag];

	// for show bid receipt menu item
	unsigned bidReceiptsCount = 0;

	switch (menuItemTag)
	{
		// FILE MENU

		// the menu item tag enumerations are in CBMainWindowController.h

		case CBShowCoverLetterMenuItemTag:
			enable = [[NSFileManager defaultManager] fileExistsAtPath:[[[self dataModel] bidPeriod] coverFilePath]];
			break;

		case CBShowSeniorityListMenuItemTag:
			enable = [[NSFileManager defaultManager] fileExistsAtPath:[[[self dataModel] bidPeriod] seniorityFilePath]];
			break;

		case CBShowBidLinesTextMenuItemTag:
			enable = [[NSFileManager defaultManager] fileExistsAtPath:[[[self dataModel] bidPeriod] linesTextFilePath]];
			break;

		case CBShowTripsTextMenuItemTag:
			enable = [[NSFileManager defaultManager] fileExistsAtPath:[[[self dataModel] bidPeriod] tripsTextFilePath]];
			break;

		case CBShowBidReceiptMenuItemTag:
			bidReceiptsCount  = [[[[self dataModel] bidPeriod] bidReceipts] count];
			if (0 == bidReceiptsCount) {
				enable = NO;
			} /* for now, leave name of menu item (Show Bid Receipt...) as 
			  single, since the user will be viewing only a single bid receipt
			  else {
				if (1 == bidReceiptsCount) {
					[menuItem setTitle:[NSString stringWithFormat:@"Show Bid Receipt%C", 0x2026]];
				} else {
					[menuItem setTitle:[NSString stringWithFormat:@"Show Bid Receipts%C", 0x2026]];
				}
			} */
			// most recent bid receipt path will nil if there are no bid receipts
			// in bid data directory
//			enable = nil != [[[self dataModel] bidPeriod] mostRecentBidReceiptPath];
			//         enable = [[NSFileManager defaultManager] fileExistsAtPath:[[[self dataModel] bidPeriod] mostRecentBidReceiptPath]];
			break;

		case CBPrintMenuItemTag:
			enable = NO;
			break;

		default:
			break;
	}

	return enable;
}

#pragma mark STORAGE

static NSString * CBDocumentType = @"CrewBid document";
//static int CBDocumentVersion = 1;
//static NSString * CBDocumentVersionKey = @"CBDocument Version";
//static NSString * CBDocumentDataModelKey = @"CBDocument Data Model";
//static NSString * CBDataFileType = @"CrewBid data file";

- (NSData *)dataRepresentationOfType:(NSString *)type
{
//   NSMutableData * documentData = nil;
//   NSKeyedArchiver * archiver = nil;
   NSData * documentData = nil;
   
   if ([type isEqualToString:CBDocumentType]) {
      // remove all pending undo/redo actions
      [[self undoManager] removeAllActions];
      // archive data
      documentData = [NSMutableData data];
//      archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:documentData];
      
//      [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
//      [archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
      
//      [archiver encodeInt:CBDocumentVersion forKey:CBDocumentVersionKey];
      
//      [archiver encodeObject:[self dataModel] forKey:CBDocumentDataModelKey];

//      [archiver finishEncoding];
      
//      [archiver release];
      
      documentData = [NSArchiver archivedDataWithRootObject:[self dataModel]];
   }

   return documentData;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
   BOOL dataLoaded = NO;
//   NSKeyedUnarchiver * unarchiver = nil;

   // already exisiting (saved) document
   if ([type isEqualToString:CBDocumentType]) {
   
      [[self undoManager] disableUndoRegistration];

      NS_DURING
          [self setDataModel:[NSUnarchiver unarchiveObjectWithData:data]];
      NS_HANDLER
          NSAlert *alert = [[[NSAlert alloc] init] autorelease];
          [alert setMessageText:[NSString stringWithFormat:@"Unable to read CrewBid document %@", [self fileName]]];
          [alert setInformativeText:[localException reason]];
          [alert addButtonWithTitle:@"Quit"];
          
          [alert runModal];
          [NSApp terminate:nil];
      NS_ENDHANDLER
      // disable undo registration
//      [[self undoManager] disableUndoRegistration];
      // create data model from archived data
//      @try {
//          [self setDataModel:[NSUnarchiver unarchiveObjectWithData:data]];
//      }
//      @catch (NSException * e) {
//          NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//          [alert setMessageText:[NSString stringWithFormat:@"Unable to read CrewBid document %@", [self displayName]]];
//          [alert setInformativeText:[e reason]];
//          [alert addButtonWithTitle:@"Quit"];
//          
//          [alert runModal];
//          [NSApp terminate:nil];
//      }
//      @finally {
////          <#statements#>
//      }
//      [self setDataModel:[NSUnarchiver unarchiveObjectWithData:data]];
      // enable undo registration
      [[self undoManager] enableUndoRegistration];
      
      // TEMP CODE
//      [self updateChangeCount:NSChangeCleared];

      // update data model after unarchiving (or revert)
      [[self dataModel] initializeAfterUnarchivingWithDocument:self];

      // indicate successful loading of data
      dataLoaded = YES;
   }

   return dataLoaded;
}

- (void)errorAlerDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [NSApp terminate:nil];
}

#pragma mark DISPLAY NAME

- (NSString *)displayName
{
   return [NSString stringWithFormat:@"%@ %@ %@ Round %d", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"], [[self dataModel] crewBase], [[self dataModel] crewPosition], [[self dataModel] bidRound]];
}

#pragma mark ACCESSORS

- (CBDataModel *)dataModel  { return dataModel; }
- (void)setDataModel:(CBDataModel *)inValue
{
   if (dataModel != inValue) {
      [dataModel release];
      dataModel = [inValue retain];
   }
}

- (CBMainWindowController *)mainWindowController
{
   NSArray * windowControllers = nil;
   CBMainWindowController * mainWindowController = nil;

   windowControllers = [self windowControllers];
   
   if ([windowControllers count] > 0)
   {
      mainWindowController = [windowControllers objectAtIndex:0];
   }
   
   return mainWindowController;
}

@end
