//
//  CBMainWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 03 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDataModel.h"
#import "CSBidPeriod.h"
#import "CBLine.h"
#import "CBTrip.h"
#import "CBTripDay.h"
#import "CBTripDayLeg.h"
#import "CBCheckboxController.h"
#import "CBMatrixController.h"
#import "CBCalendarMatrix.h"
#import "CBDocument.h"
#import "CBViewTripWindowController.h"

extern NSString *CBMostRecentBidFile;
extern NSString *CBCrewPositionKey;

// for table view drag and drop columns
#import "CBTableHeaderView.h"

#pragma mark DRAG AND DROP STRINGS
NSString *CBTableViewDragDropPBoardType = @"CrewBid TableView DragAndDrop Pasteboard Type";

#pragma mark USER DEFAULTS - COLUMNS
NSString *CBLinesTableViewColumnsKey = @"Lines Table View Columns";
NSString *CBPilotSecondRoundLinesTableViewColumnsKey = @"Pilot Second Round Lines Table View Columns";

@implementation CBMainWindowController

#pragma mark INITIALIZATION

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBDocument"]) {
      [self setShouldCloseDocument:YES];
      [self setShouldCascadeWindows:NO];
   }
   return self;
}

- (void)awakeFromNib
{
    // Workaround for retain cycles
    [selfObjectController setContent:self];
    
   // register notifications
   [self registerNotifications];
   // create table header view subclasses for lines table view and available
   // columns table view
//   [self createTableViewHeaderViews];
   // register drag type for lines table view
   [[self linesTableView] registerForDraggedTypes:[NSArray arrayWithObject:CBTableViewDragDropPBoardType]];
   // initialize dates in line calendar
   [self initializeLineCalendar];
   // initialize main tab view
   [[self mainWindowTabView] selectFirstTabViewItem:nil];
    
    
   // initialize sort tab
   [self initializeSortTab];
   // initialize select tab view
   [self initializeSelectTabView];
   // initialize days of month tab item
   [self registerDaysOfMonthNotifications];
   [self initializeDaysOfMonthTabItem];
   // initialize overnight cities tab item
   [self initializeOvernightCitiesTabItem];
   // initialize overlap tab
   // update interface items
   [self updateWindow];
   
   // COLUMNS
   [self initializeLinesTableColumns];
   
   // position window in upper left corner of screen
//   NSRect visibleScreen = [[NSScreen mainScreen] visibleFrame];
//   NSPoint screenOrigin = visibleScreen.origin;
//   float screenHeight = NSMaxY(visibleScreen);
//   NSPoint screenUpperLeft = NSMakePoint(screenOrigin.x, screenOrigin.y + screenHeight);
//   [[self window] setFrameTopLeftPoint:screenUpperLeft];
    
    [[self window] center];
   // set crew position in user defaults
   [[NSUserDefaults standardUserDefaults] setObject:[[self dataModel] crewPosition] forKey:CBCrewPositionKey];
    
    // prevent restoration of windows at startup
    if ([[self window] respondsToSelector:@selector(setRestorable:)]) {
        [[self window] setRestorable:NO];
    }
}

- (void)dealloc
{
   // release stuff
   [linesTableToolTips release];
   [lineCalendarDatesController release];
   [lineCalendarEntryController release];
	[viewTripController release];
   // unregister notifications
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   // unregister drag typs
   [[self linesTableView] unregisterDraggedTypes];
   [[self availableSortSelectionsTableView] unregisterDraggedTypes];
   [[self inUseSortSelectionsTableView] unregisterDraggedTypes];
   
   // overnight cities
   [self setOvernightCitiesValues:nil];
   
   // dealloc super
   [super dealloc];
}

#pragma mark
#pragma mark ACTIONS
#pragma mark

- (void)freezeTopLines:(id)sender
{
    NSIndexSet *selectedRows = [[self linesTableView] selectedRowIndexes];
    NSUInteger selectedRow = [selectedRows lastIndex];
    if (NSNotFound == selectedRow) {
        return;
    }
   [[self dataModel] setTopFreezeIndex:selectedRow];
   // reset bottom freeze index if top freeze index set in bottom freeze range
   if (selectedRow >= [[self dataModel] bottomFreezeIndex]) {
      [[self dataModel] setBottomFreezeIndex:selectedRow + 1];
   }
    
    // After any update to lines table, all rows are deselected. Reselect the
    // previously selected rows.
    [[self linesTableView] selectRowIndexes:selectedRows byExtendingSelection:NO];
}

- (void)unfreezeTopLines:(id)sender
{
    NSIndexSet *selectedRows = [[self linesTableView] selectedRowIndexes];
    [[self dataModel] setTopFreezeIndex:-1];
    [[self linesTableView] selectRowIndexes:selectedRows byExtendingSelection:NO];
}

- (void)freezeBottomLines:(id)sender
{
    NSIndexSet *selectedRows = [[self linesTableView] selectedRowIndexes];
    NSUInteger selectedRow = [selectedRows firstIndex];
    if (NSNotFound == selectedRow) {
        return;
    }
   [[self dataModel] setBottomFreezeIndex:selectedRow];
   // reset bottom freeze index if top freeze index set in bottom freeze range
   if (selectedRow <= [[self dataModel] topFreezeIndex]) {
      [[self dataModel] setTopFreezeIndex:selectedRow - 1];
   }

    // After any update to lines table, all rows are deselected. Reselect the
    // previously selected rows.
    [[self linesTableView] selectRowIndexes:selectedRows byExtendingSelection:NO];
}

- (void)unfreezeBottomLines:(id)sender
{
    NSIndexSet *selectedRows = [[self linesTableView] selectedRowIndexes];
    [[self dataModel] setBottomFreezeIndex:[[[self dataModel] lines] count]];
    [[self linesTableView] selectRowIndexes:selectedRows byExtendingSelection:NO];
}

// move selected line up one row
- (IBAction)moveSelectedLineUp:(id)sender
{
    NSInteger selectedRow = [[self linesTableView] selectedRow];
    // Can't move a row at the top up.
    if (0 == selectedRow) {
        return;
    }
    
    NSArray *movedRows = [NSArray arrayWithObject:[NSNumber numberWithInteger:selectedRow]];
    NSArray *toRows = [NSArray arrayWithObject:[NSNumber numberWithInteger:selectedRow - 1]];
    [[self dataModel] moveLinesArrayRows:movedRows toRows:toRows];
    
    [[self linesTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow - 1] byExtendingSelection:NO];
}

// move selected lines to bottom of top freeze range
- (IBAction)freezeSelectedLinesAtTop:(id)sender
{
    NSInteger topFreeze = [[self dataModel] topFreezeIndex];
    NSInteger bottomFreeze = [[self dataModel] bottomFreezeIndex];
    NSInteger rowsMovedOutOfBottomFreeze = 0;
    
    // Create array of rows to be moved. Don't include rows already in top
    // freeze.
    NSIndexSet *selectedRowIndexes = [[self linesTableView] selectedRowIndexes];
    NSMutableArray *rowsArray = [NSMutableArray arrayWithCapacity:[selectedRowIndexes count]];
    NSUInteger selectedRow = selectedRowIndexes.firstIndex;
    while (NSNotFound != selectedRow) {
        // top freeze < 0 means no lines frozen at top
        if (topFreeze < 0 || selectedRow > topFreeze) {
            [rowsArray addObject:[NSNumber numberWithUnsignedInteger:selectedRow]];
        }
        if (selectedRow >= bottomFreeze) {
            rowsMovedOutOfBottomFreeze += 1;
        }
        selectedRow = [selectedRowIndexes indexGreaterThanIndex:selectedRow];
    }
    
    [self moveLinesTableRows:rowsArray toRow:topFreeze + 1];
    [[self dataModel] setTopFreezeIndex:topFreeze + [rowsArray count]];
    
    // Update bottom freeze index for lines moved from there.
    [[self dataModel] setBottomFreezeIndex:bottomFreeze + rowsMovedOutOfBottomFreeze];
}

// move selected line down one row
- (IBAction)moveSelectedLineDown:(id)sender
{
    NSInteger selectedRow = [[self linesTableView] selectedRow];
    // Can't move a row at the bottom down
    if ([[self linesTableView] numberOfRows] - 1 == selectedRow) {
        return;
    }
    
    NSArray *movedRows = [NSArray arrayWithObject:[NSNumber numberWithInteger:selectedRow]];
    NSArray *toRows = [NSArray arrayWithObject:[NSNumber numberWithInteger:selectedRow + 1]];
    [[self dataModel] moveLinesArrayRows:movedRows toRows:toRows];
    
    // Data model bottom freeze for move lines works for drag and drop but not
    // for moving row down.
    NSInteger bottomFreeze = [[self dataModel] bottomFreezeIndex];
    if (selectedRow == bottomFreeze - 1) {
        [[self dataModel] setBottomFreezeIndex:bottomFreeze - 1];
    }
    
    [[self linesTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow + 1] byExtendingSelection:NO];
}

- (void)freezeSelectedLinesAtBottom:(id)sender
{
    int bottomFreeze = [[self dataModel] bottomFreezeIndex];
    NSMutableArray *rowsArray = [NSMutableArray array];
    NSIndexSet *selectedRowIndexes = [[self linesTableView] selectedRowIndexes];
    NSUInteger selectedRow = selectedRowIndexes.firstIndex;
    while (NSNotFound != selectedRow) {
        if (selectedRow < bottomFreeze) {
            [rowsArray addObject:[NSNumber numberWithUnsignedInteger:selectedRow]];
        }
        selectedRow = [selectedRowIndexes indexGreaterThanIndex:selectedRow];
    }
    
    [self moveLinesTableRows:rowsArray toRow:bottomFreeze];
    [[self dataModel] setBottomFreezeIndex:bottomFreeze - [rowsArray count]];
}

- (void)move3on3offLinesToBottom:(id)sender
{
   BOOL threeOnThreeOffToBottom = [[self dataModel] threeOnThreeOffToBottomCheckboxValue];
   [[self dataModel] setThreeOnThreeOffToBottomCheckboxValue:threeOnThreeOffToBottom ? NO : YES];
}

- (void)moveReserveLinesToBottom:(id)sender
{
   BOOL reserveLinesToBottom = [[self dataModel] reserveLinesToBottomCheckboxValue];
   [[self dataModel] setReserveLinesToBottomCheckboxValue:reserveLinesToBottom ? NO : YES];
}

- (void)moveBlankLinesToBottom:(id)sender
{
   BOOL blankLinesToBottom = [[self dataModel] blankLinesToBottomCheckboxValue];
   [[self dataModel] setBlankLinesToBottomCheckboxValue:blankLinesToBottom ? NO : YES];
}

// copy legs for trips for line to clipboard
- (void)copyLineLegs:(id)sender
{   
	int selectedRow = [[self linesTableView] selectedRow];
	if (selectedRow > -1 && 1 == [[self linesTableView] numberOfSelectedRows]) {
		// get selected line
		CBLine *line = [[[self dataModel] lines] objectAtIndex:selectedRow];
      NSString *clipboardText = [[self dataModel] clipboardTextWithLine:line];
      if (0 != [clipboardText length]) {
         [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
         [[NSPasteboard generalPasteboard] setString:[clipboardText substringToIndex:[clipboardText length] - 1] forType:NSStringPboardType];
      }
	}
}

- (void)insertReserveBid:(id)sender
{
   if ([[self dataModel] hasFaReserveBid]) {
      [[self dataModel] removeFaReserveBid]; 
   } else {
      [[self dataModel] insertFaReserveBidAtIndex:[[self linesTableView] selectedRow]];
   }
}

- (void)insertMrtBid:(id)sender
{
   if ([[self dataModel] hasFaMrtBid]) {
      [[self dataModel] removeFaMrtBid]; 
   } else {
      [[self dataModel] insertFaMrtBidAtIndex:[[self linesTableView] selectedRow]];
   }
}

- (void)viewTrip:(id)sender
{
	[[self viewTripController] showWindow:self];
}

- (void)copyTripLegs:(id)sender
{
   NSTextFieldCell *calendarCell = [[self lineCalendarEntryMatrix] selectedCell];
   if (calendarCell) {
      NSDictionary *repObj = [calendarCell representedObject];
      CBTrip *trip = [repObj objectForKey:CBLineTripNumberKey];
      NSCalendarDate *startDate = [repObj objectForKey:CBLineTripDateKey];
      NSString *clipboardText = [trip clipboardTextWithStartDate:startDate];
      if (0 != [clipboardText length]) {
         [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
         [[NSPasteboard generalPasteboard] setString:[clipboardText substringToIndex:[clipboardText length] - 1] forType:NSStringPboardType];
      }
   }
}

#pragma mark
#pragma mark INTERFACE MANAGEMENT
#pragma mark

- (void)updateWindow
{
   [self updateLinesTableView:nil];
   [self updateLineCalendar];
   [self updateSortTab];
}

#pragma mark
#pragma mark MENU MANAGEMENT
#pragma mark

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
   BOOL enable = YES;
   int menuItemTag = [menuItem tag];
   NSTableView * linesTable = [self linesTableView];
   
   switch (menuItemTag)
   {
      // FILE MENU

      case CBPrintLineMenuItemTag:
         enable = 1 == [[self linesTableView] numberOfSelectedRows];
         break;
      // show cover letter, seniority letter, bid lines text, and trips text
      // menu validation are in CBDocument
      case CBPrintMenuItemTag:
         enable = NO;
         break;

      // LINES MENU

      case CBFreezeTopLinesMenuItemTag:
         if ([linesTable numberOfSelectedRows] > 0) {
            if (0 == [[self linesTableView] selectedRow]) {
               [menuItem setTitle:@"Freeze Top Line"];
            } else {
               [menuItem setTitle:[NSString stringWithFormat:@"Freeze Top %ld Lines", (long)[[self linesTableView] selectedRow] + 1]];
            }
         } else {
            [menuItem setTitle:@"Freeze Top Lines"];
            enable = NO;
         }
         break;
         
      case CBUnfreezeTopLinesMenuItemTag:
         enable = [[self dataModel] topFreezeIndex] > -1;
         break;

      case CBFreezeBottomLinesMenuItemTag:
         if ([[self linesTableView] numberOfSelectedRows] > 0) {
            if ([[[self dataModel] lines] count] == [[self linesTableView] selectedRow]) {
               [menuItem setTitle:@"Freeze Bottom Line"];
            } else {
               [menuItem setTitle:[NSString stringWithFormat:@"Freeze Bottom %lu Lines", (unsigned long)[[[self dataModel] lines] count] - [[self linesTableView] selectedRow]]];
            }
         } else {
            [menuItem setTitle:@"Freeze Bottom Lines"];
            enable = NO;
         }
         break;

      case CBUnfreezeBottomLinesMenuItemTag:
         enable = [[self dataModel] bottomFreezeIndex] < [[[self dataModel] lines] count];
         break;

       case CBMoveSelectedLineUpMenuItemTag:
           enable = [linesTable numberOfSelectedRows] == 1 && [linesTable selectedRow] > 0;
           break;
           
       case CBMoveSelectedLinesToTopMenuItemTag:
           switch ([[self linesTableView] numberOfSelectedRows])
           {
               case 0:
                   [menuItem setTitle:@"Move Selected Row(s) to Top"];
                   enable = NO;
                   break;
               case 1:
                   [menuItem setTitle:@"Move Selected Row to Top"];
                   break;
               default:
                   [menuItem setTitle:[NSString stringWithFormat:@"Move %ld Selected Rows to Top", (long)[[self linesTableView] numberOfSelectedRows]]];
                   break;
               }
           break;
           
       case CBMoveSelectedLineDownMenuItemTag:
           enable = [linesTable numberOfSelectedRows] == 1 && [linesTable selectedRow] < [linesTable numberOfRows] - 1;
           break;
           
      case CBMoveSelectedLinesToBottomMenuItemTag:
         switch ([[self linesTableView] numberOfSelectedRows])
         {
            case 0:
               [menuItem setTitle:@"Move Selected Row(s) to Bottom"];
               enable = NO;
               break;
            case 1:
               [menuItem setTitle:@"Move Selected Row to Bottom"];
               break;
            default:
               [menuItem setTitle:[NSString stringWithFormat:@"Move %ld Selected Rows to Bottom", (long)[[self linesTableView] numberOfSelectedRows]]];
               break;
         }
         break;
      
      case CBMove3on3offLinesToBottomMenuItemTag:
         [menuItem setState:[[self dataModel] threeOnThreeOffToBottomCheckboxValue] ? NSOnState : NSOffState];
         break;

      case CBMoveReserveLinesToBottomMenuItemTag:
         if ([self isFlightAttendantFirstRoundBid]) {
            enable = NO;
            [menuItem setState:NSOffState];
         } else {
            [menuItem setState:[[self dataModel] reserveLinesToBottomCheckboxValue] ? NSOnState : NSOffState];
         }
         break;
   
      case CBMoveBlankLinesToBottomMenuItemTag:
         if ([self isFlightAttendantBid]) {
            enable = NO;
            [menuItem setState:NSOffState];
         } else {
            [menuItem setState:[[self dataModel] blankLinesToBottomCheckboxValue] ? NSOnState : NSOffState];
         }
         break;
      
      case CBCopyLineLegsMenuItemTag:
         enable = 1 == [[self linesTableView] numberOfSelectedRows];
         break;
           
      case CBInsertReserveBidMenuItemTag:
         if ([self isFlightAttendantFirstRoundBid]) {
            if ([[self dataModel] hasFaReserveBid]) {
               [menuItem setTitle:@"Remove Reserve Bid"];
            } else {
               [menuItem setTitle:@"Insert Reserve Bid"];
               enable = 1 == [[self linesTableView] numberOfSelectedRows];
            }
         } else {
            [menuItem setTitle:@"Insert Reserve Bid"];
            enable = NO;
         }
         break;

      case CBInsertMrtBidMenuItemTag:
         if ([self isFlightAttendantFirstRoundBid]) {
            if ([[self dataModel] hasFaMrtBid]) {
               [menuItem setTitle:@"Remove MRT Bid"];
            } else {
               [menuItem setTitle:@"Insert MRT Bid"];
               enable = 1 == [[self linesTableView] numberOfSelectedRows];
            }
         } else {
            [menuItem setTitle:@"Insert MRT Bid"];
            enable = NO;
         }
         break;

      // TRIPS MENU
      
      case CBCopyTripLegsMenuItemTag:
         enable = nil != [[self lineCalendarEntryMatrix] selectedCell];
         break;
      
      default:
         break;
   }
   
   return enable;
}

#pragma mark
#pragma mark INPUT VALIDATION AND FORMATTING
#pragma mark


- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
   if (control == [self overlapDatesForm]) {
      if (error) {
         [self sheetForBlockTimeTextFieldValidationFailure:string errorDescription:error];
      }
   }

   return NO;
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error
{
   if (control == [self overlapDatesForm]) {
      if (error) {
         [self sheetForBlockTimeTextFieldValidationFailure:string errorDescription:error];
      }
   }
}

#pragma mark
#pragma mark WINDOW DELEGATE METHODS
#pragma mark


- (void)windowWillClose:(NSNotification *)n
{
    // Workaround for retain cycles
    [selfObjectController setContent:nil];
    
   NSEnumerator * e = nil;
   NSTableColumn * column = nil;
   NSMutableArray * linesTableColumnIdentifiers = nil; 
   
   linesTableColumnIdentifiers = [NSMutableArray arrayWithCapacity:[[[self linesTableView] tableColumns] count]];
   
   e = [[[self linesTableView] tableColumns] objectEnumerator];
   while (column = [e nextObject])
   {
      // to accomodate line number string that includes 'R' for reserve lines
	  // and 'B' for blank lines, the identifier for the line number has been
	  // changed from 'number' to 'numberString'; to allow compatibility of 
	  // user defaults with earlier versions, the number column identifier 
	  // must remain 'number'; so we'll change 'numberString' to 'number' when
	  // it's saved to user defaults; note that 'number' will be changed back
	  // to 'numberString' when the user defaults are read
	  NSString *columnIdentifier = [column identifier];
	  if ([columnIdentifier isEqualToString:@"numberString"]) {
	     columnIdentifier = @"number";
	  }
      [linesTableColumnIdentifiers addObject:columnIdentifier];
   }
   
   if ([self isPilotSecondRoundBid])
   {
       [[NSUserDefaults standardUserDefaults] setObject:linesTableColumnIdentifiers forKey:CBPilotSecondRoundLinesTableViewColumnsKey];
   }
   else
   {
       [[NSUserDefaults standardUserDefaults] setObject:linesTableColumnIdentifiers forKey:CBLinesTableViewColumnsKey];
   }
   [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
   return [[self document] undoManager];
}

#pragma mark
#pragma mark CONTROL DELEGATE METHODS
#pragma mark

- (void)controlTextDidChange:(NSNotification *)notification
{
	// validate useSelectedDataButton in overlap tab view
   if ([notification object] == [self lastMonthLineTextField])
	{
      [self validateUseSelectedDataButton];
   }
}

#pragma mark
#pragma mark NOTIFICATIONS
#pragma mark

- (void)registerNotifications
{
   [self registerNotificationsForLinesTableView];
   [self registerNotificationsForSortTab];
   [self registerNotificationsForOverlapTabView];
}

#pragma mark
#pragma mark CALENDAR METHODS
#pragma mark

- (NSArray *)calendarDatesWithMonth:(NSCalendarDate *)month
{
   // get first date that will appear in calendar
//   NSCalendarDate * firstDate = [month dateByAddingYears:0 months:0 days:-[month dayOfWeek] hours:0 minutes:0 seconds:0];
	NSCalendarDate * firstDate = [[self dataModel] firstCalendarDate];
   // create and fill data array
   const unsigned NUM_CALENDAR_CELLS = 42;
   NSMutableArray * calendarDates = [NSMutableArray arrayWithCapacity:NUM_CALENDAR_CELLS];
   int index = 0;
   for (index = 0; index < NUM_CALENDAR_CELLS; index++) {
      NSCalendarDate * date = [firstDate dateByAddingYears:0 months:0 days:index hours:0 minutes:0 seconds:0];
      [calendarDates addObject:date];
   }
   return [NSArray arrayWithArray: calendarDates];
}

- (NSArray *)calendarDateStringsWithMonth:(NSCalendarDate *)month
{
	// replace array of calendar dates with strings that represent date of month
	NSMutableArray * calendarStrings = [NSMutableArray arrayWithArray:[self calendarDatesWithMonth:month]];
	unsigned calendarStringsCount = [calendarStrings count];
	unsigned index = 0;
   for (index = 0; index < calendarStringsCount; index++) {
		NSCalendarDate * date = [calendarStrings objectAtIndex:index];
      NSString * dateString = [NSString stringWithFormat:@"%ld", (long)[date dayOfMonth]];
      [calendarStrings replaceObjectAtIndex:index withObject:dateString];
   }
   return [NSArray arrayWithArray:calendarStrings];
}

#pragma mark
#pragma mark TABLE VIEW DATA SOURCE METHODS
#pragma mark

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
   NSInteger numberOfRows = 0;
   NSArray * dataSourceArray = nil;
   // lines table view
   if (tableView == [self linesTableView] || tableView == [self availableLinesTableColumns]) {
      dataSourceArray = [[self dataModel] lines];
   // sort tab available sort selections table view
   } else if (tableView == [self availableSortSelectionsTableView]) {
      dataSourceArray = [[self dataModel] availableSortSelections];
   // sort tab in use sort selections table view
   } else if (tableView == [self inUseSortSelectionsTableView]) {
      dataSourceArray = [[self dataModel] inUseSortSelections];
   // sort table FA positions
   } else if (tableView == [self faPositionTableView]) {
      dataSourceArray = [[self dataModel] faPositions];
   }
   // return count of data source array or 0 if no data source array
   if (dataSourceArray) {
      numberOfRows = [dataSourceArray count];
   }
   
   return numberOfRows;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	id columnObject = nil;
   NSArray * dataSourceArray = nil;
	NSString * tableColumnIdentifier = [tableColumn identifier];
   //lines table view or available table columns
   if (tableView == [self linesTableView] || tableView == [self availableLinesTableColumns]) {
      // sort order column
      if ([tableColumnIdentifier isEqualToString:@"sortOrder"]) {
         columnObject =  [NSNumber numberWithInt:(rowIndex + 1)];
      // columns other than sort order
      } else {
         dataSourceArray = [[self dataModel] lines];
         CBLine *line = [dataSourceArray objectAtIndex:rowIndex];
         // fa reserve bid
         if (CBFaReserveLineNumber == [line number]) {
            if ([tableColumnIdentifier isEqualToString:@"numberString"]) {
               columnObject = @"Resv";
            } else {
               columnObject = @"";
            }
         // fa MRT bid
         } else if (CBFaMrtLineNumber == [line number]) {
            if ([tableColumnIdentifier isEqualToString:@"numberString"]) {
               columnObject = @"MRT";
            } else {
               columnObject = @"";
            }
         // fa aircraft changes
         } else if ([self isFlightAttendantBid] && 
                    [tableColumnIdentifier isEqualToString:@"aircraftChanges"]) {
            columnObject = @"NA";
         // columns other than fa reserve bid, fa MRT bid, or fa aircraft changes
         } else {
            columnObject = [line valueForKey:tableColumnIdentifier];
         }
      }
   // avaliable sort selections table view
   } else if (tableView == [self availableSortSelectionsTableView]) {
      dataSourceArray = [[self dataModel] availableSortSelections];
      columnObject = [dataSourceArray objectAtIndex:rowIndex];
   // in use sort selections table view
   } else if (tableView == [self inUseSortSelectionsTableView]) {
      dataSourceArray = [[self dataModel] inUseSortSelections];
      columnObject = [dataSourceArray objectAtIndex:rowIndex];
   // FA positions
   } else if (tableView == [self faPositionTableView]) {
      dataSourceArray = [[self dataModel] faPositions];
      columnObject = [dataSourceArray objectAtIndex:rowIndex];
   }
   
   return columnObject;
}

#pragma mark
#pragma mark TABLE VIEW DELEGATE METHODS
#pragma mark

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
   // lines table
   if (tableView == [self linesTableView]) {
      CBLine * line = nil;
      // cache colors
      NSColor *blackColor = [NSColor blackColor];
      NSColor *greenColor = [NSColor colorWithRed:0.0 green:0.90 blue:0.0 alpha:1.0];
      NSColor *orangeColor = [NSColor orangeColor];
      NSColor *redColor = [NSColor redColor];
      NSColor *brownColor = [NSColor brownColor];
      // cache top and bottom freeze indexes
      int topFreezeIndex = [[self dataModel] topFreezeIndex];
      int bottomFreezeIndex = [[self dataModel] bottomFreezeIndex];
      // color sort order numbers green if top frozen or orange if bottom frozen
      NSString * tableColumnIdentifier = [tableColumn identifier];
      if ([tableColumnIdentifier isEqualToString:@"sortOrder"]) {
         if (rowIndex <= topFreezeIndex) {
            [(NSTextFieldCell *)cell setTextColor:greenColor];
         } else if (rowIndex >= bottomFreezeIndex) {
            [(NSTextFieldCell *)cell setTextColor:orangeColor];
         } else {
            [(NSTextFieldCell *)cell setTextColor:blackColor];
         }
      // color line number red if line is deselected
      } else if ([tableColumnIdentifier isEqualToString:@"numberString"]) {
         line =  [[[self dataModel] lines] objectAtIndex:rowIndex];
         if ([line deselectedFlags] > 0) {
            [(NSTextFieldCell *)cell setTextColor:redColor];
         } else {
            [(NSTextFieldCell *)cell setTextColor:blackColor];
         }
      // color line pay brown if line has overlap
      } else if ([tableColumnIdentifier isEqualToString:@"credit"]) {
         line =  [[[self dataModel] lines] objectAtIndex:rowIndex];
         if ([line hasOverlap]) {
            [(NSTextFieldCell *)cell setTextColor:brownColor];
         } else {
            [(NSTextFieldCell *)cell setTextColor:blackColor];
         }
      }
   }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
   NSTableView * tableView = [notification object];
   int selectedRow = [tableView selectedRow];
   // if tableView is linesTableView, fill lines calendar
   if (tableView == [self linesTableView]) {
      // set all calendar cells to blue and set selected cell to nil
      [[[self lineCalendarEntryMatrix] cells] makeObjectsPerformSelector:@selector(setTextColor:) withObject:[NSColor blueColor]];
      [[self lineCalendarEntryMatrix] setSelectedCell:nil];
      // set trip pairing view to no trip
      [[self lineCalendarEntryMatrix] setTripText:@"No trip selected."];
      int numberOfSelectedRows = [tableView numberOfSelectedRows];
      NSString * calendarTitle = nil;
      // if single line selected, set calendar title and fill calendar matrix
      if (1 == numberOfSelectedRows) {
         CBLine * line = [[[self dataModel] lines] objectAtIndex:selectedRow];
         switch ([line number]) {
            // reserve bid
            case CBFaMrtLineNumber:
               calendarTitle = [NSString stringWithFormat:@"%@ - Reserve", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"]];
               [[self lineCalendarEntryController] loadEntries:[[self dataModel] emptyCalendarEntries] objects:[[self dataModel] emptyCalendarObjects] tags:[[self dataModel] emptyCalendarTags]];
               break;
            case CBFaReserveLineNumber:
               calendarTitle = [NSString stringWithFormat:@"%@ - MRT", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"]];
               [[self lineCalendarEntryController] loadEntries:[[self dataModel] emptyCalendarEntries] objects:[[self dataModel] emptyCalendarObjects] tags:[[self dataModel] emptyCalendarTags]];
               break;
            default:
            calendarTitle = [NSString stringWithFormat:@"%@ - Line %d", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"], [line number]];
            // fill line calendar entries with trips for selected line
            [[self lineCalendarEntryController] loadEntries:[line lineCalendarEntries] objects:[line lineCalendarObjects] tags:[line lineCalendarTags]];
               break;
         }
      // if no line selected, set calendar title
      }
      else if (0 == numberOfSelectedRows)
      {
         calendarTitle = [NSString stringWithFormat:@"%@ - No line selected", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"]];
         [[self lineCalendarEntryController] loadEntries:[[self dataModel] emptyCalendarEntries] objects:[[self dataModel] emptyCalendarObjects] tags:[[self dataModel] emptyCalendarTags]];
      }
      // else (multiple lines selected) set calendar title
      else
      {
         calendarTitle = [NSString stringWithFormat:@"%@ - Multiple lines selected", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"]];
         [[self lineCalendarEntryController] loadEntries:[[self dataModel] emptyCalendarEntries] objects:[[self dataModel] emptyCalendarObjects] tags:[[self dataModel] emptyCalendarTags]];
      }
      // set line calendar title
      [lineCalendarTitleTextField setStringValue:calendarTitle];
   }
}

- (void)tableViewColumnDidMove:(NSNotification *)notification
{
   NSTableView * tableView = [notification object];
   // if columns moved in lines table or configure tab, assign tool tips
   if ((tableView == [self linesTableView]) || (tableView == [self availableLinesTableColumns])) {
      [self assignLinesTableColumnToolTips];
   }
}

#pragma mark
#pragma mark DRAG AND DROP - TABLE VIEW ROWS
#pragma mark

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
   // rows argument is an array of NSNumber(s) that represent indexes of rows being dragged
   
   // return value
   BOOL tableViewShouldStartDragSession = NO;
   // determine table view in which drag session is starting
   if (tableView == [self availableSortSelectionsTableView] ||
       tableView == [self inUseSortSelectionsTableView] ||
       tableView == [self linesTableView] ||
       tableView == [self faPositionTableView]) {
      // table view should start drag session
      tableViewShouldStartDragSession = YES;
      // declare pasteboard type
      [pboard declareTypes:[NSArray arrayWithObjects:CBTableViewDragDropPBoardType, nil] owner:self];
      // archive data (rows, the array of NSNumber(s))
      NSData * rowsData = [NSArchiver archivedDataWithRootObject:rows];
      // write data to pasteboard
      [pboard setData:rowsData forType:CBTableViewDragDropPBoardType];
   }
	return tableViewShouldStartDragSession;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
   // return value for allowed drag operation
   NSDragOperation allowedDragOperation = NSDragOperationNone;
   // table view from which drag started
   NSTableView * dragSource = [info draggingSource];
   // allow drops within lines table view, in use sort selections table view, 
   // and fa positions table view, or drag between available sort selections
   // table view and in use sort selections table view
   if ((dragSource == tableView && tableView != [self availableSortSelectionsTableView]) ||
       (dragSource == [self availableSortSelectionsTableView] && 
         tableView == [self inUseSortSelectionsTableView]) ||
       (dragSource == [self inUseSortSelectionsTableView] && 
         tableView == [self availableSortSelectionsTableView])) {
      allowedDragOperation = NSDragOperationMove;
   }
   [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	return allowedDragOperation;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
   BOOL tableViewShouldAcceptDrop = NO;
   // dragging source
   NSTableView * dragSource = [info draggingSource];
	// rows being dragged (array of NSNumber(s) representing row numbers being dragged)
   NSData * rowsData = [[info draggingPasteboard] dataForType:CBTableViewDragDropPBoardType];
	// unarchive rows data
	NSArray * rowsArray = [NSUnarchiver unarchiveObjectWithData:rowsData];
   // mutable arrays for moving data
   NSMutableArray * fromArray = nil;
   NSMutableArray * toArray = nil;
   // variables used for selecting lines in table view after moving rows
   int firstSelectedRow = 0;
   int rowIndex = 0;
   int numberOfRowsToSelect = 0;
   
   // move from available to in use sort selections
   if (dragSource == [self availableSortSelectionsTableView] && 
       tableView == [self inUseSortSelectionsTableView]) {
      // table view should accept drop
      tableViewShouldAcceptDrop = YES;
      // set to and from arrays
      fromArray = [NSMutableArray arrayWithArray:[[self dataModel] availableSortSelections]];
      toArray = [NSMutableArray arrayWithArray:[[self dataModel] inUseSortSelections]];
      // move rows
      firstSelectedRow = [self moveRows:rowsArray fromArray:fromArray toRow:row ofArray:toArray];
      // set data model
      [[self dataModel] setAvailableSortSelections:[NSArray arrayWithArray:fromArray]];
      [[self dataModel] setInUseSortSelections:[NSArray arrayWithArray:toArray]];
      // select moved rows
      numberOfRowsToSelect = [rowsArray count];
      for (rowIndex = 0; rowIndex < numberOfRowsToSelect; rowIndex++ ) {
          [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:firstSelectedRow + rowIndex] byExtendingSelection:YES];
      }

   // move from in use sort selections to available sort selections
   } else if (dragSource == [self inUseSortSelectionsTableView] &&
              tableView == [self availableSortSelectionsTableView]) {
      // table view should accept drop
      tableViewShouldAcceptDrop = YES;
      // set to and from arrays
      fromArray = [NSMutableArray arrayWithArray:[[self dataModel] inUseSortSelections]];
      toArray = [NSMutableArray arrayWithArray:[[self dataModel] availableSortSelections]];
      // move rows
      [self moveRows:rowsArray fromArray:fromArray toRow:row ofArray:toArray];
      // set data model
      [[self dataModel] setInUseSortSelections:[NSArray arrayWithArray:fromArray]];
      [[self dataModel] setAvailableSortSelections:[toArray sortedArrayUsingFunction:compareSortSelection context:nil]];

   // move within in use sort selections
   } else if (dragSource == [self inUseSortSelectionsTableView] &&
              tableView == [self inUseSortSelectionsTableView]) {
      // table view should accept drop
      tableViewShouldAcceptDrop = YES;
      // only one array needed
      fromArray = [NSMutableArray arrayWithArray:[[self dataModel] inUseSortSelections]];
      // move rows
      firstSelectedRow = [self moveRows:rowsArray ofArray:fromArray toRow:row];
      // set data model
      [[self dataModel] setInUseSortSelections:[NSArray arrayWithArray:fromArray]];
      // select moved rows
      numberOfRowsToSelect = [rowsArray count];
      for (rowIndex = 0; rowIndex < numberOfRowsToSelect; rowIndex++ ) {
          [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:firstSelectedRow + rowIndex] byExtendingSelection:YES];
      }

   // move within lines table view
   } else if (dragSource == [self linesTableView] &&
              tableView == [self linesTableView]) {
      // table view should accept drop
      tableViewShouldAcceptDrop = YES;
      
      // only one array needed
      fromArray = [NSMutableArray arrayWithArray:[[self dataModel] lines]];
      // move rows
      firstSelectedRow = [self moveRows:rowsArray ofArray:fromArray toRow:row];
      // set data model
      [[self dataModel] setLines:[NSArray arrayWithArray:fromArray]];
      // select moved rows
      numberOfRowsToSelect = [rowsArray count];
      for (rowIndex = 0; rowIndex < numberOfRowsToSelect; rowIndex++ ) {
          [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:firstSelectedRow + rowIndex] byExtendingSelection:YES];
      }
      
      [self adjustDataModelFreezeIndexesAfterMovingRows:rowsArray toRow:row];

      // TEST CODE
//		NSString *undoActionName = nil;
//		if ([rowsArray count] > 1) {
//			undoActionName = @"Drag Rows";
//		} else {
//			undoActionName = @"Drag Row";
//		}
//		[[self undoManager] setActionName:undoActionName];
//		[self moveLinesTableRows:rowsArray toRow:row];

   // move within FA positions table view
   } else if (dragSource == [self faPositionTableView] &&
              tableView == [self faPositionTableView]) {
      // table view should accept drop
      tableViewShouldAcceptDrop = YES;
      // only one array needed
      fromArray = [NSMutableArray arrayWithArray:[[self dataModel] faPositions]];
      // move rows
      firstSelectedRow = [self moveRows:rowsArray ofArray:fromArray toRow:row];
      // set data model
      [[self dataModel] setFaPositions:fromArray];
      // select moved rows
      numberOfRowsToSelect = [rowsArray count];
      for (rowIndex = 0; rowIndex < numberOfRowsToSelect; rowIndex++ ) {
          [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:firstSelectedRow + rowIndex] byExtendingSelection:YES];
      }
   }

	return tableViewShouldAcceptDrop;
}

- (int)moveRows:(NSArray *)rows fromArray:(NSMutableArray *)fromArray toRow:(int)toRow ofArray:(NSMutableArray *)toArray
{
   // rows is an array of NSNumber(s) that represent index of row(s) to be moved
   // int return value is row in toArray at which rows were moved
   int toRowInsertIndex = toRow;
   // not same array
   if (fromArray != toArray) {
      NSEnumerator * rowsEnumerator = [rows objectEnumerator];
      NSNumber * rowIndexNumber = nil;
      int rowIndex = 0;
      // add to toArray
      while (rowIndexNumber = [rowsEnumerator nextObject]) {
         rowIndex = [rowIndexNumber intValue];
         id movedObject = [fromArray objectAtIndex:rowIndex];
         if (toRow > -1) {
            [toArray insertObject:movedObject atIndex:toRow];
            toRow++;
         } else {
            toRowInsertIndex = 0;
            [toArray addObject:movedObject];
         }
      }
      // remove from fromArray
      NSEnumerator * reverseRowsEnumerator = [rows reverseObjectEnumerator];
      rowIndexNumber = nil;
      while (rowIndexNumber = [reverseRowsEnumerator nextObject]) {
         rowIndex = [rowIndexNumber intValue];
         [fromArray removeObjectAtIndex:rowIndex];
      }
   }
   return toRowInsertIndex;
}


- (int)moveRows:(NSArray *)rows ofArray:(NSMutableArray *)array toRow:(int)toRow
{
	// create array to keep track of moved objects
	NSMutableArray *originalArray = [NSMutableArray arrayWithArray:array];
   // enumerate rows to be moved, removing those in rows, and keeping track of the number of rows 
   // removed from above or equal to insert row, so that insert row may be adjusted to correctly reinsert moved rows
   int numRowsRemovedAboveInsertRow = 0;
   NSNumber * moveRowNumber = nil;
   NSEnumerator * moveRowNumberEnumerator = [rows reverseObjectEnumerator];
   while (moveRowNumber = [moveRowNumberEnumerator nextObject]) {
      // remove row
      int moveRowIndex = [moveRowNumber intValue];
      [array removeObjectAtIndex:moveRowIndex];
      // increment counter for number of rows removed from above (or equal to) insert row
      if (moveRowIndex < toRow) {
         numRowsRemovedAboveInsertRow++;
      }
   }
   // row at which to insert rows (is also return value for use by linesTableView for selecting moved rows
   int insertIndex = toRow - numRowsRemovedAboveInsertRow;
   // insert lines, starting from end of indices and moving up
   moveRowNumberEnumerator = [rows reverseObjectEnumerator];
   while (moveRowNumber = [moveRowNumberEnumerator nextObject]) {
      int moveRowIndex = [moveRowNumber intValue];
      [array insertObject:[originalArray objectAtIndex:moveRowIndex] atIndex:insertIndex];
   }
   // adjust top and bottom freeze indices
   // return row to which rows were moved, to be used by linesTableView to select moved rows
   return insertIndex;
}

- (void)adjustDataModelFreezeIndexesAfterMovingRows:(NSArray *)rowIndices toRow:(int)toRow
{
   CBDataModel * dataModel = [self dataModel];
   unsigned numMovedRows = [rowIndices count];
   // disable sorting until after freeze indexes are set
   // lines will be sorted in drag and drop method
   [dataModel setSortingEnabled:NO];
   // top
   int topFreezeAdjustment = 0;
   int topFreeze = [dataModel topFreezeIndex];
   int numRowsInTopFreezeRange = 0;
   // bottom
   int bottomFreezeAdjustment = 0;
   int bottomFreeze = [dataModel bottomFreezeIndex];
   int numRowsInBottomFreezeRange = 0;
   // enumerate row indices to determine number of rows moved in top and bottom freeze ranges
   NSNumber * row = nil;
   NSEnumerator * rowEnumerator = [rowIndices reverseObjectEnumerator];
   while (row = [rowEnumerator nextObject]) {
      int rowIndex = [row intValue];
      // top and bottom freeze indexes
      if (rowIndex <= topFreeze) {
         numRowsInTopFreezeRange++;
      } else if (rowIndex >= bottomFreeze) {
         numRowsInBottomFreezeRange++;
      }
   }
   // drop in top freeze range
   if (toRow <= topFreeze) {
      // adjust top freeze by number of moved lines less those already in top freeze range
      topFreezeAdjustment = numMovedRows - numRowsInTopFreezeRange;
   // drop below top freeze range
   } else {
      // adjust top freeze by number of moved lines that were already in top freeze range
      topFreezeAdjustment = -numRowsInTopFreezeRange;
   }
   [dataModel setTopFreezeIndex:( topFreeze + topFreezeAdjustment )];
   // drop in bottom freeze range
   if (toRow > bottomFreeze) {
      bottomFreezeAdjustment = numMovedRows - numRowsInBottomFreezeRange;
   // drop above bottom freeze range
   } else {
      bottomFreezeAdjustment = -numRowsInBottomFreezeRange;
   }
   [dataModel setBottomFreezeIndex:( bottomFreeze - bottomFreezeAdjustment )];
   // enable sorting
   [dataModel setSortingEnabled:YES];
}

- (void)adjustDataModelFaBidIndexesAfterMovingRows
{
   CBLine *resvBidLine = [[self dataModel] faReserveBidLine];
   CBLine *mrtBidLine = [[self dataModel] faMrtBidLine];
   NSArray *lines = [[self dataModel] lines];
   NSEnumerator *linesEnum = [lines objectEnumerator];
   CBLine *line = nil;
   int lineIndex = 0;
   int faReserveBidIndex = -1;
   int faMrtBidIndex = -1;
   // line number == 0 indicates reserve bid
   while ((line = [linesEnum nextObject])) {
      if ([line isEqualToLine:resvBidLine]) {
         faReserveBidIndex = lineIndex;
      } else if ([line isEqualToLine:mrtBidLine]) {
         faMrtBidIndex = lineIndex;
      }
      if (faReserveBidIndex > -1 && faMrtBidIndex > -1) {
         break;
      }
      lineIndex ++;
   }
   if (faReserveBidIndex < [lines count]) {
//      [[self dataModel] setFaReserveBidIndex:faReserveBidIndex];
   }
   if (faReserveBidIndex < [lines count]) {
//      [[self dataModel] setFaReserveBidIndex:faReserveBidIndex];
   }
}

#pragma mark
#pragma mark DRAG AND DROP - TABLE VIEW COLUMNS
#pragma mark

- (void)createTableViewHeaderViews
{
   CBTableHeaderView * linesTableHeaderView = nil;
   CBTableHeaderView * availableColumnsHeaderView = nil;
   NSRect linesTableHeaderFrame = NSMakeRect(0, 0, 0, 0);
   NSRect availableColumnsHeaderFrame = NSMakeRect(0, 0, 0, 0);
   
   linesTableHeaderFrame = [[[self linesTableView] headerView] frame];
   availableColumnsHeaderFrame = [[[self availableLinesTableColumns] headerView] frame];
   
   linesTableHeaderView = [[CBTableHeaderView alloc] initWithFrame:linesTableHeaderFrame];
   availableColumnsHeaderView = [[CBTableHeaderView alloc] initWithFrame:availableColumnsHeaderFrame];
   
   [[self linesTableView] setHeaderView:linesTableHeaderView];
   [[self availableLinesTableColumns] setHeaderView:availableColumnsHeaderView];
   
   [linesTableHeaderView release];
   [availableColumnsHeaderView release];
}

#pragma mark
#pragma mark ACCESSORS
#pragma mark

- (CBDocument *)document
{
   return [super document];
}

- (CBDataModel *)dataModel
{
   return [[self document] dataModel];
}

- (NSUndoManager *)undoManager
{
   return [[self document] undoManager];
}

- (NSTabView *)mainWindowTabView { return mainWindowTabView; }

//- (CBCheckboxController *)pointsIncludePayCheckboxController { return pointsIncludePayCheckboxController; }

// for showing trips by trip identifier
- (CBViewTripWindowController *)viewTripController
{
	if (!viewTripController)
	{
		viewTripController = [[CBViewTripWindowController alloc] initWithDataModel:[self dataModel]];
	}
	return viewTripController;
}

// for adjusting the interface
- (BOOL)isFlightAttendantBid
{
   return [[self dataModel] isFlightAttendantBid];
}

- (BOOL)isFlightAttendantFirstRoundBid
{
   return [[self dataModel] isFlightAttendantFirstRoundBid];
}

- (BOOL)isPilotSecondRoundBid
{
    return [[self dataModel] isPilotSecondRoundBid];
}

- (BOOL)isFirstRoundBid
{
    return [[[[self dataModel] bidPeriod] round] intValue] == 1;
}

#pragma mark COLUMNS

- (NSTableView *)availableLinesTableColumns { return availableLinesTableColumns; }

- (void)initializeLinesTableColumns
{
   NSArray * columns = nil;  // columns from user defaults
   NSEnumerator * e = nil;   // columns enumerator
   NSString * cid = nil;     // column identifier
   NSTableView * ltv = nil;  // lines table view
   NSTableView * atc = nil;  // available lines table columns
   NSTableColumn * tc = nil; // table column
   int i = 0;                // index of columns from user defaults
   int c = 0;                // column in lines table view or available columns
   
   ltv = [self linesTableView];
   atc = [self availableLinesTableColumns];
   
   // initialize table columns to those contained in user defaults
   // proceed only if user defaults contains column identifiers
   if ([self isPilotSecondRoundBid])
   {
      columns = [[NSUserDefaults standardUserDefaults] arrayForKey:CBPilotSecondRoundLinesTableViewColumnsKey];
   }
   else
   {
      columns = [[NSUserDefaults standardUserDefaults] arrayForKey:CBLinesTableViewColumnsKey];
   }
  // remove unwanted table columns from lines table view
  if (columns)
  {
	  // To avoid mutating an array while enumerating, get object enumerator from 
	  // immutable copy of lines table view columns (as opposed to using enumerator 
	  // from the lines table view columns).
	  e = [[NSArray arrayWithArray:[ltv tableColumns]]  objectEnumerator];
     while (tc = [e nextObject])
     {
        cid = [tc identifier];
		// identifier for line number column in lines table view has been 
		// changed from 'number' to 'number string'
		// if column identifier (cid) is 'number' change to 'numberString'
		if ([cid isEqualToString:@"number"]) {
		   cid = @"numberString";
		}
        if (![columns containsObject:cid])
        {
           [atc addTableColumn:tc];
           [ltv removeTableColumn:tc];
        }
     }
  }
  // add table columns that aren't in lines table view, and move table
  // columns to correct position
  e = [columns objectEnumerator];
  while (cid = [e nextObject])
  {
	// identifier for line number column in lines table view has been 
	// changed from 'number' to 'number string'
	// if column identifier (cid) is 'number' change to 'numberString'
	if ([cid isEqualToString:@"number"]) {
	   cid = @"numberString";
	}
     // determine if column is in lines table view
     c = [ltv columnWithIdentifier:cid];
     // if not in lines table view, add column from available table columns,
     // move to correct position, and remove from available table columns
     if (c < 0)
     {
        tc = [atc tableColumnWithIdentifier:cid];
        [ltv addTableColumn:tc];
        [ltv moveColumn:([[ltv tableColumns] count] - 1) toColumn:i];
        [atc removeTableColumn:tc];
     }
     // if in lines table view, but not in correct position, move column
     // to correct position
     else if (c != i)
     {
        [ltv moveColumn:c toColumn:i];
     }
     i++;
  }

   if ([self isFlightAttendantBid])
   {
      // if there are not columns in user defaults (first time the bid has been
      // opened), put Pos column in lines table view for flight attendants
      cid = @"faPosition";
      tc = [ltv tableColumnWithIdentifier:cid];
      if (!tc) // Pos column not in lines table view
      {
         tc = [atc tableColumnWithIdentifier:cid];
         c = [ltv columnWithIdentifier:@"numberString"];
         if (tc && c >= 0) // # column is in lines table view
         {
            [ltv addTableColumn:tc];
            [atc removeTableColumn:tc];
            [ltv moveColumn:([[ltv tableColumns] count] - 1) toColumn:c + 1];
         }
      }
      // remove aircraft changes table column
      cid = @"aircraftChanges";
      if ((tc = [atc tableColumnWithIdentifier:cid])) {
         [atc removeTableColumn:tc];
      } else if ((tc = [ltv tableColumnWithIdentifier:cid])) {
         [ltv removeTableColumn:tc];
      }
   }
   // remove Pos column from lines table view for pilots
   else
   {
      cid = @"faPosition";
      if ((tc = [atc tableColumnWithIdentifier:cid]))
      {
         [atc removeTableColumn:tc];
      }
      else if ((tc = [ltv tableColumnWithIdentifier:cid]))
      {
         [ltv removeTableColumn:tc];
      }
   }

    // remove inappropriate table columns for pilot second round bids
    if ([self isPilotSecondRoundBid])
    {
        columns = [[ltv tableColumns] arrayByAddingObjectsFromArray:[atc tableColumns]];
        e = [columns objectEnumerator];
        while (tc = [e nextObject])
        {
            // fa positions
            if ((tc = [atc tableColumnWithIdentifier:@"faPosition"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"faPosition"]))
            {
                [ltv removeTableColumn:tc];
            }
            // pay per duty
            if ((tc = [atc tableColumnWithIdentifier:@"payPerDuty"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"payPerDuty"]))
            {
                [ltv removeTableColumn:tc];
            }
            // pay per leg
            if ((tc = [atc tableColumnWithIdentifier:@"payPerLeg"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"payPerLeg"]))
            {
                [ltv removeTableColumn:tc];
            }
            // pay per tafb
            if ((tc = [atc tableColumnWithIdentifier:@"payPerTafb"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"payPerTafb"]))
            {
                [ltv removeTableColumn:tc];
            }
            // aircraft changes
            if ((tc = [atc tableColumnWithIdentifier:@"aircraftChanges"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"aircraftChanges"]))
            {
                [ltv removeTableColumn:tc];
            }
            // legs
            if ((tc = [atc tableColumnWithIdentifier:@"legs"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"legs"]))
            {
                [ltv removeTableColumn:tc];
            }
            // max legs
            if ((tc = [atc tableColumnWithIdentifier:@"maxLegs"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"maxLegs"]))
            {
                [ltv removeTableColumn:tc];
            }
            // passes through domicile
            if ((tc = [atc tableColumnWithIdentifier:@"passesThroughDomicile"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"passesThroughDomicile"]))
            {
                [ltv removeTableColumn:tc];
            }
            // vacation pay
            if ((tc = [atc tableColumnWithIdentifier:@"vacationPay"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"vacationPay"]))
            {
                [ltv removeTableColumn:tc];
            }
            // vacation drop
            if ((tc = [atc tableColumnWithIdentifier:@"vacationDrop"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"vacationDrop"]))
            {
                [ltv removeTableColumn:tc];
            }
            // pay with vacation
            if ((tc = [atc tableColumnWithIdentifier:@"payWithVacation"]))
            {
                [atc removeTableColumn:tc];
            }
            else if ((tc = [ltv tableColumnWithIdentifier:@"payWithVacation"]))
            {
                [ltv removeTableColumn:tc];
            }
        }
    }

    // TEMP UNTIL VACATION DATA MODEL IS SET UP
    columns = [[ltv tableColumns] arrayByAddingObjectsFromArray:[atc tableColumns]];
    e = [columns objectEnumerator];
    while (tc = [e nextObject])
    {
        // vacation pay
        if ((tc = [atc tableColumnWithIdentifier:@"vacationPay"]))
        {
            [atc removeTableColumn:tc];
        }
        else if ((tc = [ltv tableColumnWithIdentifier:@"vacationPay"]))
        {
            [ltv removeTableColumn:tc];
        }
        // vacation drop
        if ((tc = [atc tableColumnWithIdentifier:@"vacationDrop"]))
        {
            [atc removeTableColumn:tc];
        }
        else if ((tc = [ltv tableColumnWithIdentifier:@"vacationDrop"]))
        {
            [ltv removeTableColumn:tc];
        }
        // pay with vacation
        if ((tc = [atc tableColumnWithIdentifier:@"payWithVacation"]))
        {
            [atc removeTableColumn:tc];
        }
        else if ((tc = [ltv tableColumnWithIdentifier:@"payWithVacation"]))
        {
            [ltv removeTableColumn:tc];
        }
        // vacation days off
        if ((tc = [atc tableColumnWithIdentifier:@"vacationDaysOff"]))
        {
            [atc removeTableColumn:tc];
        }
        else if ((tc = [ltv tableColumnWithIdentifier:@"vacationDaysOff"]))
        {
            [ltv removeTableColumn:tc];
        }
    }
        
   // set double action so that double-clicking the header of a table column
   // will move that column to the other table view
   [[self linesTableView] setDoubleAction:@selector(moveColumn:)];
   [[self availableLinesTableColumns] setDoubleAction:@selector(moveColumn:)];
   // set tool tips for lines table view and available table columns
   [self setLinesTableToolTips:[self toolTipsForLinesTable]];
   [self assignLinesTableColumnToolTips];
   // update lines table view so that, if a horizontal scroller is added at
   // the bottom as columns are added, the last line in the lines table view
   // is not obscured
   [linesTableView reloadData];
}

- (IBAction)moveColumn:(id)sender
{
   // move columns only if double-click was in header (clicked row == -1)
   if (-1 == [(NSTableView *)sender clickedRow]) {
      NSTableColumn * columnToMove = [[(NSTableView *)sender tableColumns] objectAtIndex:[(NSTableView *)sender clickedColumn]];
	   // move from lines table to available columns
      if (sender == [self linesTableView]) {
		  // Prevent removing sort order and line number from lines table view.
		  if ([[columnToMove identifier] isEqualToString:@"numberString"] ||
			  [[columnToMove identifier] isEqualToString:@"sortOrder"]) {
			  return;
		  }
		  [[self availableLinesTableColumns] addTableColumn:columnToMove];
      // move from available columns to lines table
      } else if (sender == [self availableLinesTableColumns]) {
         [[self linesTableView] addTableColumn:columnToMove];
      }
      [(NSTableView *)sender removeTableColumn:columnToMove];
      [self assignLinesTableColumnToolTips];
	   // update lines table view so that, if a horizontal scroller is added at
	   // the bottom as columns are added, the last line in the lines table view
	   // is not obscured
	   [linesTableView reloadData];
   }
}

- (void)assignLinesTableColumnToolTips
{
   NSDictionary * tt = [self linesTableToolTips];
   NSTableView * ltv = [self linesTableView];
   NSTableView * atv = [self availableLinesTableColumns];
   NSTableHeaderView * lthv = [ltv headerView];
   NSTableHeaderView * athv = [atv headerView];
   [lthv removeAllToolTips];
   [athv removeAllToolTips];
   NSArray * ltvColumns = [ltv tableColumns];
   NSArray * atvColumns = [atv tableColumns];
   int ltvColCount = [ltvColumns count];
   int atvColCount = [atvColumns count];
   int i = 0;
   for (i = 0; i < ltvColCount; i++) {
      NSTableColumn * tc = [ltvColumns objectAtIndex:i];
      NSString * key = [[tc headerCell] stringValue];
      NSString * tip = [tt objectForKey:key];
      NSRect hvcRect = [lthv headerRectOfColumn:i];
      [lthv addToolTipRect:hvcRect owner:tip userData:nil];
   }
   for (i = 0; i < atvColCount; i++) {
      NSTableColumn * tc = [atvColumns objectAtIndex:i];
      NSString * key = [[tc headerCell] stringValue];
      NSString * tip = [tt objectForKey:key];
      NSRect hvcRect = [athv headerRectOfColumn:i];
      [athv addToolTipRect:hvcRect owner:tip userData:nil];
   }
}

- (NSDictionary *)toolTipsForLinesTable
{
   return [NSDictionary dictionaryWithObjectsAndKeys:
      @"Sort order", @"Ord",
      @"Line number", @"#",
      @"Points", @"Pts",
      @"Line pay", @"Pay",
      @"Flight (block) time", @"Blk",
      @"Number of turn, 2-day, 3-day, and 4-day trips", @"T234",
      @"Number of days off in month", @"Off",
      @"Pay per flight (block) hour", @"$/blk",
      @"Pay per day", @"$/day",
      @"Pay per duty hour", @"$/dty",
      @"Pay per leg", @"$/leg",
      @"Pay per time (hours) away from base", @"$/tafb",
      @"AM or PM line", @"A/P",
      @"Number of weekend days", @"Wknd",
      @"Earliest departure time", @"EDep",
      @"Latest arrival time", @"LArr",
      @"Number of aircraft changes", @"Chgs",
      @"Number of trips", @"Trips",
      @"Total number of work days", @"Work",
      @"Number of legs", @"Legs",
      @"Maximum number of legs in a day", @"MLgs",
      @"Passes through domicile", @"PTDs",
      @"Longest block of consecutive days off", @"BkOff",
      @"Flight attendant position", @"Pos",
      @"Commutes required", @"CRqd",
      @"Overnights in domicile", @"OIDs",
      @"Vacation drop: maximum possible pay drop for selected vacation week", @"VDrp",
      @"Vacation pay: pay for days that fall within selected vacation week", @"VPay",
      nil];
}

@end
