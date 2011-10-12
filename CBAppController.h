/*
CBAppController.h
CrewBid

Created by Mark Ackerman on Fri Apr 23 2004.
Copyright © 2004 Mark Ackerman. All rights reserved.

The CBAppController class is the delegate of NSApplication and is instantiated
in the MainMenu nib. It implements actions for menu items that are available
at all times (as opposed to menu items that are available only when a
document is open). It also implements methods that check that required system
resources are available, creates required directories, displays appropriate
windows at startup, and implements application delegate methods.

*/

#import <Cocoa/Cocoa.h>

@class CBMainPreferencesWindowController;
@class CBNewBidWindowController;
@class CBFileSelectWindowController;

@interface CBAppController : NSObject
{
   // preferences
   CBMainPreferencesWindowController * preferencesController;
   // new bid
   CBNewBidWindowController * newBidController;
   // open bid file
   CBFileSelectWindowController *openFileController;
   // progress window for opening files
   NSWindow * progressWindow;
	// version check
	NSMutableData *_appVersionData;

}

#pragma mark INITIALIZATION
/* Checks that system 10.2 or later is installed. */
- (BOOL)checkEnvironment;
/* Releases the registration window controller. Called when notification is
received from the registration window controller when the OK button is clicked.
Registration window controller is created in the applicationDidFinishLaunching
method if there is no employee number in the user defaults. */
- (void)registrationDidFinish:(NSNotification *)notification;

#pragma mark ACTIONS
/* Opens the preferences window. */
- (IBAction)openPreferences:(id)sender;
/* Opens the new bid dialog. */
- (IBAction)newBid:(id)sender;
/* Releases the new bid window controller. Called when notification is received
from the new bid window controller if the new bid action is cancelled, the new
bid is downloaded and opened, or an error occurs when downloading the new bid
file. */
- (void)newBidDidFinish:(NSNotification *)notification;
/* Opens the open bid window. */
- (IBAction)openBidFile:(id)sender;
/* Opens the most recent bid receeipt (identified in the user defaults by the
CBMostRecentBidReceiptKey) in the default text editor. */
- (void)openBidReceipt:(id)sender;
/* Opens the remove old files window. Presents an alert sheet to confirm
the user's intention to move the files to the trash. */
- (void)removeOldFiles:(id)sender;
/* Moves files selected in the remove old files window, after confirmation
is obtained by the alert sheet displayed in the removeOldFiles: methd. */
- (void)removeFilesSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
/* Ends the modal session for the preferences window. Used only on first-time
startup, when the preferences window is displayed modally to ensure that the
user enters an empolyee number. */
- (void)preferencesSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

#pragma mark FILE SYSTEM METHODS
/* Creates the CrewBid directory in the user's home Library folder, if the
folder doesn't already exitst. */
- (BOOL)createCrewBidDirectory;
/* Returns path to the CrewBid directory in the user's home Library folder. */
- (NSString *)crewBidDirectoryPath;
/* Returns NSCalendarDate created from first two words of filename, Used for 
sorting filenames in NSOpenPanel. */
- (NSCalendarDate *)dateWithFilename:(NSString *)filename;
- (NSString *)bidPeriodsDataFilePath;

#pragma mark HELP
/* Creates email to support<at>macrewsoft.com in the default mail 
application. */
- (void)emailSupport:(id)sender;

#pragma mark VERSION
/* Connects to macrewsoft.com to check if new version is available */
- (void)checkForNewerVersion:(id)sender;

#pragma mark ACCESSORS
- (CBMainPreferencesWindowController *)preferencesController;
- (CBNewBidWindowController *)newBidController;
- (CBFileSelectWindowController *)openFileController;
- (NSWindow *)progressWindow;

@end

extern NSString * CBMostRecentBidReceiptKey;
extern NSString * CBMostRecentBidDocumentKey;
extern NSString * CBAmDepartTimePreferencesKey;
extern NSString * CBAmArrivalTimePreferencesKey;
