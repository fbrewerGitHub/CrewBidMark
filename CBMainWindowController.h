//
//  CBMainWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 03 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// superclass
#import "CBBidFileWindowController.h"
// implements CBInterfaceItemOwner category
#import "CBInterfaceItemOwner.h"

@class CBDataModel;
@class CBLine;
@class CBCalendarMatrix;
@class CBSelectCalendarMatrix;
@class CBMatrixController;
@class CBInterfaceItemController;
@class CBPopUpButtonController;
@class CBCheckboxController;
@class CBIntegerTextFieldController;
@class CBBidSubmitPreferencesWindowController;
@class CBBidFileDownload;
@class CBViewTripWindowController;

typedef enum enumCBSelectTabItem {
   CBAmPmSelectTab = 1,
   CBAircraftChangesSelectTab
} CBSelectTabItem;

typedef enum enumCBMenuItemTag {
   // file menu
   CBShowCoverLetterMenuItemTag = 10300,
   CBShowSeniorityListMenuItemTag = 10400,
   CBShowBidLinesTextMenuItemTag = 10500,
   CBShowTripsTextMenuItemTag = 10600,
   CBShowBidReceiptMenuItemTag = 10800,
   CBPrintLineMenuItemTag = 11200,
   CBPrintMenuItemTag = 11300,
   // lines menu
   CBLinesMenuItemTag = 40000,
   CBFreezeTopLinesMenuItemTag = 40100,
   CBUnfreezeTopLinesMenuItemTag = 40200,
   CBFreezeBottomLinesMenuItemTag = 40300,
   CBUnfreezeBottomLinesMenuItemTag = 40400,
   CBMoveSelectedLinesToBottomMenuItemTag = 40500,
   CBMove3on3offLinesToBottomMenuItemTag = 40550,
   CBMoveReserveLinesToBottomMenuItemTag = 40600,
   CBMoveBlankLinesToBottomMenuItemTag = 40700,
   CBCopyLineLegsMenuItemTag = 40800,
   CBInsertReserveBidMenuItemTag = 40900,
   CBInsertMrtBidMenuItemTag = 41000,
   // trip menu
   CBTripMenuItemTag = 50000,
   CBViewTripMenuItemTag = 50100,
   CBCopyTripLegsMenuItemTag = 50200
} CBMenuItemTag;

@interface CBMainWindowController : CBBidFileWindowController < CBInterfaceItemOwner >
{
    // Workaround for retain cycles
    IBOutlet NSObjectController *selfObjectController;
    
   // lines table view
	IBOutlet NSTableView *             linesTableView;
   NSDictionary *                     linesTableToolTips;
   // line calendar
   IBOutlet NSTextField *             lineCalendarTitleTextField;
   IBOutlet NSMatrix *                lineCalendarDateMatrix;
   IBOutlet CBCalendarMatrix *        lineCalendarEntryMatrix;
   CBMatrixController *               lineCalendarDatesController;
   CBMatrixController *               lineCalendarEntryController;
   // main tab view
   IBOutlet NSTabView *               mainWindowTabView;
   // sort tab view
   IBOutlet NSTableView *             availableSortSelectionsTableView;
   IBOutlet NSTableView *             inUseSortSelectionsTableView;
   IBOutlet NSTableView *             faPositionTableView;
   IBOutlet NSBox *                   faPositionBox;
   // select tab view
   IBOutlet NSTabView *               selectTabView;
   IBOutlet NSTableView *             selectTabTableView;
   NSArray *                          selectTabItems;
   // days of month tab item
   IBOutlet CBSelectCalendarMatrix   *daysOfMonthSelectMatrix;
   IBOutlet NSMatrix                 *daysOfMonthPointsMatrix;
   IBOutlet NSMatrix                 *daysOfWeekSelectMatrix;
   IBOutlet NSMatrix                 *daysOfWeekPointsMatrix;
   // overnight cities tab item
   NSArray                           *overnightCitiesValues;
   // overlap tab view
   IBOutlet NSForm *                  overlapDatesForm;
   IBOutlet NSTextField *             overlapLastArrivalTextField;
   IBOutlet NSTextField *             overlapLastArrivalTimeTextField;
   IBOutlet NSPopUpButton *           lastMonthBidPopUpButton;
   IBOutlet NSTextField *             lastMonthLineTextField;
   IBOutlet NSButton *                useSelectedDataButton;
   IBOutlet NSButton *                computeOverlapButton;
   // configure tab view
   IBOutlet NSTableView *             availableLinesTableColumns;
   // bid submission
   CBBidSubmitPreferencesWindowController * bidSubmitWindowController;
	// show trip
	CBViewTripWindowController *       viewTripController;
}

#pragma mark ACTIONS
// LINES MENU
// freeze top lines
- (void)freezeTopLines:(id)sender;
// unfreeze top lines
- (void)unfreezeTopLines:(id)sender;
// freeze bottom lines
- (void)freezeBottomLines:(id)sender;
// unfreeze bottom lines
- (void)unfreezeBottomLines:(id)sender;
// move lines selected in lines table view to top of bottom freeze range
- (void)freezeSelectedLinesAtBottom:(id)sender;
// move 3-on/3-off lines to bottom
- (void)move3on3offLinesToBottom:(id)sender;
// move reserve lines to bottom
- (void)moveReserveLinesToBottom:(id)sender;
// move blank lines to bottom
- (void)moveBlankLinesToBottom:(id)sender;
// copy legs for trips for line to clipboard
- (void)copyLineLegs:(id)sender;
// insert flight attendant reserve bid
- (void)insertReserveBid:(id)sender;
// insert flight attendant MRT bid
- (void)insertMrtBid:(id)sender;
// TRIPS MENU
// show trip text view by trip identifier
- (void)viewTrip:(id)sender;
// copy legs for trip to clipboard
- (void)copyTripLegs:(id)sender;

#pragma mark INTERFACE MANAGEMENT
- (void)updateWindow;

#pragma mark NOTIFICATIONS
- (void)registerNotifications;

#pragma mark CALENDAR METHODS
- (NSArray *)calendarDatesWithMonth:(NSCalendarDate *)month;
- (NSArray *)calendarDateStringsWithMonth:(NSCalendarDate *)month;

#pragma mark DRAG AND DROP - TABLE VIEW ROWS
- (int)moveRows:(NSArray *)rows fromArray:(NSMutableArray *)fromArray toRow:(int)toRow ofArray:(NSMutableArray *)toArray;
- (int)moveRows:(NSArray *)rows ofArray:(NSMutableArray *)array toRow:(int)toRow;
- (void)adjustDataModelFreezeIndexesAfterMovingRows:(NSArray *)rowIndices toRow:(int)toRow;
- (void)adjustDataModelFaBidIndexesAfterMovingRows;

#pragma mark DRAG AND DROP - TABLE VIEW COLUMNS
- (void)createTableViewHeaderViews;

#pragma mark ACCESSORS
// for CBInterfaceItemOwner protocol
- (CBDocument *)document;
- (CBDataModel *)dataModel;
- (NSUndoManager *)undoManager;
- (NSTabView *)mainWindowTabView;
//- (CBCheckboxController *)pointsIncludePayCheckboxController;

// for showing trips by trip identifier
- (CBViewTripWindowController *)viewTripController;

// for adjusting the interface
- (BOOL)isFlightAttendantBid;
- (BOOL)isFlightAttendantFirstRoundBid;
- (BOOL)isPilotSecondRoundBid;
- (BOOL)isFirstRoundBid;

#pragma mark COLUMNS
- (NSTableView *)availableLinesTableColumns;
- (void)initializeLinesTableColumns;
- (IBAction)moveColumn:(id)sender;
- (void)assignLinesTableColumnToolTips;
- (NSDictionary *)toolTipsForLinesTable;


@end

/******************************************************************************/
//
//  Lines TableView Controller
//
/******************************************************************************/
@interface CBMainWindowController ( CBLinesTableViewController )

#pragma mark INTERFACE MANAGEMENT
- (void)updateLinesTableView:(NSNotification *)notification;
- (void)updateLinesTableViewSelectedRows:(NSNotification *)notification;

#pragma mark MOVE LINES TABLE VIEW ROWS
- (void)moveLinesTableRows:(NSArray *)fromRows toRow:(int)row;

#pragma mark NOTIFICATIONS
- (void)registerNotificationsForLinesTableView;

#pragma mark ACCESSORS
- (NSTableView *)linesTableView;
- (NSDictionary *)linesTableToolTips;
- (void)setLinesTableToolTips:(NSDictionary *)inValue;

@end

/******************************************************************************/
//
//  Line Calendar Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBLineCalendarController )

#pragma mark INITIALIZATION
- (void)initializeLineCalendar;

#pragma mark INTERFACE MANAGEMENT
- (void)updateLineCalendar;

#pragma mark ACCESSORS
- (NSTextField *)lineCalendarTitleTextField;
- (NSMatrix *)lineCalendarDateMatrix;
- (CBCalendarMatrix *)lineCalendarEntryMatrix;
- (CBMatrixController *)lineCalendarDatesController;
- (void)setLineCalendarDatesController:(CBMatrixController *)inValue;
- (CBMatrixController *)lineCalendarEntryController;
- (void)setLineCalendarEntryController:(CBMatrixController *)inValue;

@end

/******************************************************************************/
//
//  Sort Tab Controller
//
/******************************************************************************/
@interface CBMainWindowController ( CBSortTabViewController )

#pragma mark INITIALIZATION
- (void)initializeSortTab;
- (void)initializeSortTabSubviews;

#pragma mark ACTIONS
- (void)moveSortSelections:(id)sender;

#pragma mark INTERFACE MANAGEMENT
- (void)updateSortSelections:(NSNotification *)notification;
- (void)updateSortTab;
- (void)updateFaPositionTableView:(NSNotification *)notification;
- (void)updateFaPositionTableView;

#pragma mark NOTIFICATIONS
- (void)registerNotificationsForSortTab;

#pragma mark ACCESSORS
- (NSTableView *)availableSortSelectionsTableView;
- (NSTableView *)inUseSortSelectionsTableView;
- (NSTableView *)faPositionTableView;
- (NSBox *)faPositionBox;

@end

/******************************************************************************/
//
//  Select Tab Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBSelectTabViewController )

#pragma mark INITIALIZATION
- (void)initializeSelectTabView;
- (void)registerNotificationsForSelectTabView;
- (NSArray *)selectTabItemsArray;

#pragma mark ACCESSORS
- (NSTableView *)selectTabTableView;
- (NSTabView *)selectTabView;
- (NSArray *)selectTabItems;
- (void)setSelectTabItems:(NSArray *)inValue;

@end

/******************************************************************************/
//
//  Days of Month Tab Item Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBDaysOfMonthTabItemController )

#pragma mark Intitialization
- (void)registerDaysOfMonthNotifications;
- (void)initializeDaysOfMonthTabItem;

#pragma mark Actions
- (IBAction)daysOfMonthSelectMatrixAction:(id)sender;
- (IBAction)daysOfMonthPointsMatrixAction:(id)sender;
- (IBAction)daysOfWeekSelectMatrixAction:(id)sender;
- (IBAction)daysOfWeekPointsMatrixAction:(id)sender;

#pragma mark Interface Updating
- (void)updateDaysOfMonthSelectMatrix:(NSNotification *)notification;
- (void)updateDaysOfMonthPointsMatrix:(NSNotification *)notification;
- (void)updateDaysOfWeekSelectMatrix:(NSNotification *)notification;
- (void)updateDaysOfWeekPointsMatrix:(NSNotification *)notification;

@end

/******************************************************************************/
//
//  Overnight Cities Tab Item Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBOvernightCitiesTabItemController )

#pragma mark Intitialization
- (void)initializeOvernightCitiesTabItem;

#pragma mark Key-Value Observing
- (void)startObservingOvernightCitiesValues;
- (void)stopObservingOvernightCitiesValues;

#pragma mark Accessors
- (NSArray *)overnightCitiesValues;
- (void)setOvernightCitiesValues:(NSArray *)value;

@end

/******************************************************************************/
//
//  Overlap Tab Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBOverlapTabViewController )

#pragma mark INITIALIZATION
- (void)initializeOverlapTabView;
- (void)fillOverlapDates;
- (void)fillLastMonthPopUpButton;
- (NSString *)shortCrewPositionWithPosition:(NSString *)crewPos;
- (void)getPreviousMonth:(NSString **)month year:(NSString **)year documentName:(NSString **)name;

#pragma mark ACTIONS
- (void)useSelectedDataButtonAction:(id)sender;
- (void)computeOverlapButtonAction:(id)sender;
- (void)overlapDatesFormAction:(id)sender;
- (void)overlapReleaseTimeTextFieldAction:(id)sender;

#pragma mark SPECIFIC INTERFACE ITEM UPDATERS
- (void)updateOverlapDatesForm:(NSNotification *)notification;
- (void)updateOverlapReleaseTimeTextField:(NSNotification *)notification;
- (void)positionOverlapReleaseTimeTextField;

#pragma mark NOTIFICATION REGISTRATION
- (void)registerNotificationsForOverlapTabView;

#pragma mark INPUT VALIDATION AND FORMATTING
- (BOOL)sheetForBlockTimeTextFieldValidationFailure:(NSString *)string errorDescription:(NSString *)error;
- (BOOL)sheetForReleaseTimeInvalidValue;
- (void)invalidReleaseTimeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

#pragma mark CONTROL VALIDATION
- (void)validateUseSelectedDataButton;

#pragma mark ACCESSORS
- (NSForm *)overlapDatesForm;
- (NSTextField *)overlapLastArrivalTextField;
- (NSTextField *)overlapLastArrivalTimeTextField;
- (NSPopUpButton *)lastMonthBidPopUpButton;
- (NSTextField *)lastMonthLineTextField;
- (NSButton *)useSelectedDataButton;
- (NSButton *)computeOverlapButton;

@end

/******************************************************************************/
//
//  Bid Submit Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBBidSubmitController )

#pragma mark ACTIONS
//- (IBAction)submitBid:(id)sender;

#pragma mark BID SUBMISSION
- (void)bidSubmitSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)submitBid;
- (NSString *)bidReceiptFileNameWithBidder:(NSString *)bidder month:(NSCalendarDate *)month;

#pragma mark BID REQUEST BODY CREATION
- (NSString *)packetIDWithBase:(NSString *)base month:(NSCalendarDate *)month position:(NSString *)position round:(int)round;
- (NSString *)bidLines;
- (NSString *)employeeBidsFromUserDefaults;

#pragma mark SHEET HANDLING
- (void)bidReceiptSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

#pragma mark ACCESSORS
- (CBBidSubmitPreferencesWindowController *)bidSubmitWindowController;

@end

/******************************************************************************/
//
//  Print Controller
//
/******************************************************************************/

@interface CBMainWindowController ( CBPrintController )

#pragma mark PRINTING
- (IBAction)printLine:(id)sender;

@end

#pragma mark SELECT TAB LINE ATTRIBUTE KEYS
extern NSString * CBSelectTabLineAttributeTitleKey;
extern NSString * CBSelectTabLineAttributeTabNumberKey;

#pragma mark DRAG AND DROP STRINGS
extern NSString * CBTableViewDragDropPBoardType;

#pragma mark USER DEFAULTS - COLUMNS
extern NSString *CBLinesTableViewColumnsKey;
extern NSString *CBPilotSecondRoundLinesTableViewColumnsKey;