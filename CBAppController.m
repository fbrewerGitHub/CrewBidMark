//
//  CBAppController.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBAppController.h"
#import "CBPreferencesWindowController.h"
#import "CBMainPreferencesWindowController.h"
#import "CBRegistrationWindowController.h"
#import "CBNewBidWindowController.h"

#import "CSNewBidWindowController.h"
#import "CSBidPeriod.h"
#import "CSOpenBidWindowController.h"

#import "CBFileSelectWindowController.h"
#import "CBBidFileOpener.h"

   // ***** FLIGHT ATTENDANT TESTING *****
#import "CBFATripFileReader.h"
#import "CBFileReader.h"
#import "CBFALineFileReader.h"

NSString * CBMostRecentBidReceiptKey = @"Most Recent Bid Receipt";
NSString * CBMostRecentBidDocumentKey = @"Most Recent Bid Document";

@implementation CBAppController

#pragma mark INITIALIZATION

+ (void)initialize
{
   static BOOL initialized = NO;
   if (!initialized && (self == [CBAppController class])) {
      [self setVersion:1];
   }
   // set application initial default values
   NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
   NSDictionary * initialUserDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
      @"", CBEmployeeNumberKey,
      @"", CBEmployeeBid1Key,
      @"", CBEmployeeBid2Key,
      @"", CBEmployeeBid3Key,
      @"DAL", CBCrewBaseKey,
      @"Captain", CBCrewPositionKey,
      [NSNumber numberWithBool:YES], CBSaveBidBeforeSubmitKey,
      @"", CBMostRecentBidReceiptKey,
      [NSNumber numberWithInt:1100], CBAmDepartTimePreferencesKey,
      [NSNumber numberWithInt:1800], CBAmArrivalTimePreferencesKey,
      nil];
   [defaults registerDefaults:initialUserDefaults];
   
   [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"US/Central"]];
   
//   [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:-21600]];
   
   initialized = YES;
}

- (id)init
{
   if (self = [super init])
   {
   }
   return self;
}

- (void)dealloc
{
   [preferencesController release];
   [newBidController release];
   [openFileController release];
   [super dealloc];
}


- (void)awakeFromNib
{
   // notify user and quit if not a good operating system environment
   BOOL isGoodEnvironment = [self checkEnvironment];
   if (!isGoodEnvironment) {
      NSRunAlertPanel(@"CrewBid requires System 10.5 or later", @"CrewBid requires operating system version 10.5 or later to run. Your computer appears to be operating an earlier version of the operating system. You must upgrade to 10.5 (Leopard) or later to run CrewBid.", @"Quit CrewBid", nil, nil);
      [NSApp terminate:self];
   }
   
   // create directories if they don't exist
   BOOL directoryExists = [self createCrewBidDirectory];
   if (!directoryExists) {
      NSRunAlertPanel(@"CrewBid could not create required directory", [NSString stringWithFormat:@"CrewBid could not create a required directory in your home library directory (%@).  Please check permissions for this directory.", [NSHomeDirectory() stringByAppendingPathComponent:@"Library"]], @"Quit CrewBid", nil, nil);
      [NSApp terminate:self];
   }
   
   // other initialization is performed in applicationDidFinishLaunching:
}

- (BOOL)checkEnvironment
{
	// This method uses the existence of the NSViewController class, new in 
	// OS 10.5 (Leopard) to determine if CrewBid can run on this system. Other 
	// sources of operating system information are shown below.
	BOOL goodEnvironemnt = NO;
	if (NSClassFromString(@"NSViewController")) {
		goodEnvironemnt = YES;
	}

   return goodEnvironemnt;
   
   // Other ways to get information about the operating system:
  
   // SInt32 macVersion;
   // Gestalt(gestaltSystemVersion, &macVersion);
   //
   // NSAppKitVersionNumber
   // NSFoundationVersionNumber
   //
   // [[NSProcessInfo processInfo] operatingSystemVersionString];
}

- (void)registrationDidFinish:(NSNotification *)notification
{
   CBRegistrationWindowController *rwc = [notification object];
   [NSApp stopModal];
   [[NSNotificationCenter defaultCenter] removeObserver:self name:CBRegistrationWindowControllerDidFinish object:rwc];
   [rwc release];
}

#pragma mark MENU MANAGEMENT

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
   BOOL validMenu = YES;
   NSString * menuTitle = [menuItem title];
   NSString * pathToBidReceipt = nil;
   // new bid menu item
   if ([menuTitle isEqualToString:@"New Bid..."]) {
      // new bid menu item is valid if there is not a new bid selection
      // and download in progress
      validMenu = (nil == [self newBidController]);
   }
   // open bid receipt menu item
   else if ([menuTitle isEqualToString:@"Open Bid Receipt..."]) {
      // open bid receipt menu is valid if there is a bid receipt path in
      // user defaults
      pathToBidReceipt = [[NSUserDefaults standardUserDefaults] objectForKey:CBMostRecentBidReceiptKey];
      if ((nil == pathToBidReceipt) || (0 == [pathToBidReceipt length])) {
         validMenu = NO;
      }
   }
   return validMenu;
}


#pragma mark ACTIONS

-(IBAction)openPreferences:(id)sender
{
   // this method allocates preferencesController if it doesn't exist
   // preferencesController is deallocated in dealloc method
   if (!preferencesController) {
      preferencesController = [[CBMainPreferencesWindowController alloc] init];
   }
   [preferencesController showWindow:sender];
}

- (IBAction)newBid:(id)sender
{
   // create new bid controller, which will be released when it's finished,
   // in newBidDidFinish: method
   // new bid controller will download bid data and open new document with
   // bid data
    CSNewBidWindowController *nbwc = [[CSNewBidWindowController alloc] initWithBidPeriod:[CSBidPeriod defaultBidPeriod]];
    [[nbwc window] center];
    [nbwc showWindow:nil];
}

- (void)newBidDidFinish:(NSNotification *)notification
{
   // remove self as notification observer
   [[NSNotificationCenter defaultCenter] removeObserver:self name:CBNewBidControllerDidFinish object:[notification object]];
   // release new bid controller controller
   [[self newBidController] release];
   newBidController = nil;
}

- (IBAction)openBidFile:(id)sender
{
   // create open bid panel
   NSOpenPanel * openPanel = [NSOpenPanel openPanel];
   [openPanel setDelegate:self];
   [openPanel setCanChooseDirectories:NO];
   [openPanel setAllowsMultipleSelection:NO];
   NSString * fileToSelect = [[NSUserDefaults standardUserDefaults] objectForKey:CBMostRecentOpenedBidFileKey];
   NSArray * fileTypes = [NSArray arrayWithObject:@"crewbid"];
   int result = [openPanel runModalForDirectory:[self crewBidDirectoryPath] file:fileToSelect types:fileTypes];
//   int result = [openPanel runModalForDirectory:[self crewBidDirectoryPath] file:fileToSelect types:nil];
   if (result == NSOKButton) {
      // get file to open
      NSArray * filesToOpen = [openPanel filenames];
      if ([filesToOpen count] > 0) {
	     // file to open
         NSString *fileToOpen = [filesToOpen objectAtIndex:0];
	     // set most recent opened file in user defaults
		 [[NSUserDefaults standardUserDefaults] setObject:[fileToOpen lastPathComponent] forKey:CBMostRecentOpenedBidFileKey];
		 // open bid file
		 [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:fileToOpen display:YES];
      }
   }
}

- (void)openBidReceipt:(id)sender
{
   NSString * pathToBidReceipt = [[NSUserDefaults standardUserDefaults] objectForKey:CBMostRecentBidReceiptKey];
   if (pathToBidReceipt && [[NSFileManager defaultManager] fileExistsAtPath:pathToBidReceipt]) {
      [[NSWorkspace sharedWorkspace] openFile:pathToBidReceipt];
   } else {
      NSRunAlertPanel(@"Could not find bid receipt", [NSString stringWithFormat:@"CrewBid could not find your most recent bid receipt (%@), possibly because it was removed from the CrewBid folder in your home Library folder.", [[pathToBidReceipt lastPathComponent] stringByDeletingPathExtension]], @"OK", nil, nil);
   }
}

- (void)removeOldFiles:(id)sender
{
   NSOpenPanel * panel = nil;
   NSArray * fileTypes = nil;
   int result = NSFileHandlingPanelOKButton;
   NSString * defaultButton = nil;
   
   panel = [NSOpenPanel openPanel];
   [panel setCanChooseDirectories:NO];
   [panel setAllowsMultipleSelection:YES];
   [panel setTitle:@"Remove Old Files"];
   [panel setPrompt:@"Remove"];
   fileTypes = [NSArray arrayWithObjects:@"crewbid", @"txt", @"plist", nil];
   
   result = [panel runModalForDirectory:[self crewBidDirectoryPath] file:nil types:fileTypes];
   
   if (NSFileHandlingPanelOKButton == result)
   {
      defaultButton = ([[panel filenames] count] > 1 ? @"Remove 'Em" : @"Remove It");

      NSBeginAlertSheet(
         @"Remove Old Files?",
         defaultButton,
         nil,
         @"No! No! Stop!",
         panel,
         self,
         @selector(removeFilesSheetDidEnd:returnCode:contextInfo:),
         NULL,
         [panel retain],
         @"Are you sure you want to remove %d %@?\n\nThe %@ will be moved to the Trash.",
         [[panel filenames] count], ([[panel filenames] count] > 1 ? @"files" : @"file"), ([[panel filenames] count] > 1 ? @"files" : @"file"));
   }
}

- (void)removeFilesSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (NSAlertDefaultReturn == returnCode)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSOpenPanel *openPanel = (NSOpenPanel *)contextInfo;
        NSMutableArray *filesToDelete = [NSMutableArray array];

        // Use open bid file window controller to convert bid document name to
        // bid data directory - TEMP CODE
        CSOpenBidWindowController *obwc = [[CSOpenBidWindowController alloc] init];
        CSBidPeriod *bidPeriod = [[CSBidPeriod alloc] init];
      
        NSEnumerator *e = [[openPanel filenames] objectEnumerator];
        NSString *filename = nil;
        while (filename = [e nextObject])
        {
             NSString *bidDocName = [filename lastPathComponent];
             [filesToDelete addObject:bidDocName];
             // if file is a crewbid document and a bid data directory exists for
             // that file, then also move the bid data directory to the trash
             // remove file - TEMP CODE
			 NSString *fileExtension = [bidDocName pathExtension];
			 if ([fileExtension isEqualToString:@"crewbid"]) {
				 NSMutableDictionary *bidPeriodValues = [NSMutableDictionary dictionaryWithDictionary:[obwc bidPeriodValuesForOldDocumentName:bidDocName]];
				 [bidPeriodValues removeObjectForKey:@"documentName"];
				 [bidPeriod setValuesForKeysWithDictionary:bidPeriodValues];
				 NSString *bidDataDirPath = [bidPeriod bidDataDirectoryPath];
				 BOOL isDir = NO;
				 if ([fileManager fileExistsAtPath:bidDataDirPath isDirectory:&isDir] && isDir)
				 {
					NSString *bidDataDirName = [bidPeriod bidDataDirectoryName];
					[filesToDelete addObject:bidDataDirName];
				 }
			 }
        }
    
        // remove bid document files and bid data directories (if they exist)
        NSString *crewBidDir = [self crewBidDirectoryPath];
        NSString *trashDir = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
        int tag = 0;
        NSWorkspace *sharedWorkspace = [NSWorkspace sharedWorkspace];
        [sharedWorkspace 
            performFileOperation:NSWorkspaceRecycleOperation 
            source:crewBidDir 
            destination:trashDir 
            files:filesToDelete 
            tag:&tag];
//        [sharedWorkspace noteFileSystemChanged:crewBidDir];
//        [sharedWorkspace noteFileSystemChanged:trashDir];
        // clean up
        [obwc release];
        [bidPeriod release];
        [openPanel release];
    }
}

- (void)preferencesSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   if (sheet == [preferencesController window])
   {
      [NSApp endSheet:[preferencesController window]];
      [preferencesController release];
      preferencesController = nil;
   }
}

#pragma mark APPLICATION DELEGATE METHODS

- (void)applicationDidFinishLaunching:(NSNotification *)n
{
	// begin check for new version assynchronously
	NSString *latestVersionURLString = @"http://www.macrewsoft.com/bin/CrewBidVersion.plist";
	NSURL *latestVersionURL = [NSURL URLWithString:latestVersionURLString];
	NSURLRequest *latestVersionRequest = [NSURLRequest requestWithURL:latestVersionURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
	[NSURLConnection connectionWithRequest:latestVersionRequest delegate:self];

   // TEMPORARY FIX FOR USER DEFAULTS THAT MAY HAVE SEAT POSITION AND 
   // AVOIDANCE BIDS
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   NSString *seatPos = [userDefaults objectForKey:@"Seat Position"];
   NSString *avoid1 = [userDefaults objectForKey:@"Avoidance Bid 1"];
   NSString *avoid2 = [userDefaults objectForKey:@"Avoidance Bid 2"];
   NSString *avoid3 = [userDefaults objectForKey:@"Avoidance Bid 3"];
   if (seatPos)
   {
      [userDefaults setObject:seatPos forKey:CBCrewPositionKey];
      [userDefaults removeObjectForKey:@"Seat Position"];
   }
   if (avoid1)
   {
      [userDefaults setObject:avoid1 forKey:CBEmployeeBid1Key];
      [userDefaults removeObjectForKey:@"Avoidance Bid 1"];
   }
   if (avoid2)
   {
      [userDefaults setObject:avoid2 forKey:CBEmployeeBid2Key];
      [userDefaults removeObjectForKey:@"Avoidance Bid 2"];
   }
   if (avoid3)
   {
      [userDefaults setObject:avoid3 forKey:CBEmployeeBid3Key];
      [userDefaults removeObjectForKey:@"Avoidance Bid 3"];
   }

   // open preferences window if preferences have not been initialized by user
    if (![userDefaults objectForKey:CBEmployeeNumberKey] || 
        [[userDefaults objectForKey:CBEmployeeNumberKey] isEqualToString:@""])
    {
        if (nil == preferencesController)
        {
            preferencesController = [[CBMainPreferencesWindowController alloc] init];
            [NSApp runModalForWindow:[preferencesController window]];
        }
//        [self openPreferences:nil];
    }

   // open last opened bid file, if month it was created is the same as current
   // month
   NSString *lastOpenedBid = [userDefaults objectForKey:CBMostRecentOpenedBidFileKey];

   if (lastOpenedBid)
   {
      NSString *lastOpenedBidPath = [[self crewBidDirectoryPath] stringByAppendingPathComponent:lastOpenedBid];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSDate *fileDate = [[fileManager fileAttributesAtPath:lastOpenedBidPath traverseLink:NO] objectForKey:NSFileCreationDate];
      NSCalendarDate *fileCreatedDate = [NSCalendarDate dateWithString:[fileDate description]];
      NSCalendarDate *now = [NSCalendarDate calendarDate];
      
      if ([fileCreatedDate monthOfYear] == [now monthOfYear])
      {
         [self openBidFile:nil];
      }
      // else open new bid window
      else
      {
         [self newBid:nil];
      }
   }
   // else open new bid window
   else
   {
      [self newBid:nil];
   }
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
   // application will not open a file unless opened by other means
   return NO;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
   BOOL fileOpened = NO;
   CBBidFileOpener * opener = [[CBBidFileOpener alloc] initWithFile:filename modalWindow:nil progressController:nil];
   fileOpened = [opener openFile];
   [opener release];
   return fileOpened;
}

#pragma mark FILE SYSTEM METHODS

- (BOOL)createCrewBidDirectory
{
   BOOL directoryCreated = NO;
   BOOL crewBidDirectoryExists = NO;
   BOOL isDirectory = NO;
   NSFileManager * defaultManager = [NSFileManager defaultManager];
   NSString * crewBidDirectoryPath = [self crewBidDirectoryPath];
 
   // create CrewBid directory if it doesn't exist
   crewBidDirectoryExists = [defaultManager fileExistsAtPath:crewBidDirectoryPath isDirectory:&isDirectory];
   if (!crewBidDirectoryExists) {
      // passing nil for attributes gives default values for attributes such
      // as grooup and owner permissions
      directoryCreated = [defaultManager createDirectoryAtPath:crewBidDirectoryPath attributes:nil];
   }
   // check that the directory is writeable
   directoryCreated = [defaultManager isWritableFileAtPath:crewBidDirectoryPath];
   
   return directoryCreated;
}

- (NSString *)crewBidDirectoryPath
{
   // /Users/mark/Library/CrewBid
   return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/CrewBid"];
}

- (NSCalendarDate *)dateWithFilename:(NSString *)filename
{
   NSCalendarDate *date = nil;
   NSScanner *scanner = [NSScanner scannerWithString:filename];
   NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
   NSString *monthName = nil;
   NSString *yearName = nil;
   NSString *dateFormat = nil;
   [scanner scanUpToCharactersFromSet:whitespace intoString:&monthName];
   [scanner scanUpToCharactersFromSet:whitespace intoString:&yearName];
   if ([yearName length] == 2) {
      dateFormat = @"%d %b %y";
   } else {
      dateFormat = @"%d %B %Y";
   }
   date = [NSCalendarDate dateWithString:[NSString stringWithFormat:@"1 %@ %@", monthName, yearName] calendarFormat:dateFormat];
   return date;
}

- (NSString *)bidPeriodsDataFilePath
{
    NSString *bidPeriodsDataFilePath = [[self crewBidDirectoryPath] stringByAppendingPathComponent:@"BidPeriods.cbbpdata"];
    return bidPeriodsDataFilePath;
}

#pragma mark HELP

- (void)emailSupport:(id)sender
{
   NSURL *url = [NSURL URLWithString:@"mailto:support@macrewsoft.com?subject=CrewBid%20Support&body=Your%20comments%20here"];
   
   [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark OPEN PANEL DELGATE METHODS

- (NSComparisonResult)panel:(id)sender compareFilename:(NSString *)fileName1 with:(NSString *)fileName2 caseSensitive:(BOOL)flag
{
   NSComparisonResult result = NSOrderedSame;
   // compare months
   NSCalendarDate *month1 = [self dateWithFilename:fileName1];
   NSCalendarDate *month2 = [self dateWithFilename:fileName2];
   // compare months represented by filenames, if they can be created, or
   // just filename if month could not be created from filename
   if (month1 && month2) {
      result = [month1 compare:month2];
   } else {
      result = [fileName1 compare:fileName2];
   }
   return result;
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
   BOOL shouldShowFilename = NO;
   if ([[filename pathExtension] isEqualToString:@"crewbid"]) {
      shouldShowFilename = YES;
   }
   
//   NSLog(@"\%@ should show filename: %@ %@", [sender class], filename, (shouldShowFilename ? @"YES" : @"NO"));
   
   return shouldShowFilename;
}

#pragma mark VERSION

- (void)checkForNewerVersion:(id)sender
{
   NSDictionary *currentVersion = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://www.macrewsoft.com/ver/cb_ver.plist"]];
   
   if (currentVersion) {
      // this version
      NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
      NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
      int ver = [version intValue];
      // most current version
      NSString *curVersion = [currentVersion objectForKey:@"CFBundleVersion"];
      NSString *curShortVersion = [currentVersion objectForKey:@"CFBundleShortVersionString"];
      int curVer = [curVersion intValue];
      // show alert if this version is less than most current version
      NSString *alertTitle = nil;
      NSString *alertMessage = nil;
      if (ver < curVer) {
         alertTitle = @"A newer version of CrewBid is available.";
         alertMessage = [NSString stringWithFormat:@"You are running an older version of CrewBid (%@). A newer version (%@) is available at the macrewsoft web site.", shortVersion, curShortVersion];
         NSRunAlertPanel(
            alertTitle,
            alertMessage,
            @"OK",
            @"Go to macrewsoft web site",
            nil);
      }
   }
}

#pragma mark Version Check

- (void)checkForNewVersion
{
	NSDictionary *latestVersionDict = [NSPropertyListSerialization propertyListFromData:_appVersionData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
	if (latestVersionDict)
	{
		NSString *latestVersion = [latestVersionDict objectForKey:@"CFBundleShortVersionString"];
		NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		if (NO == [version isEqualToString:latestVersion]) {
			NSString *changesURLString = @"http://www.macrewsoft.com/bin/CrewBidChanges.txt";
			NSURL *changesURL = [NSURL URLWithString:changesURLString];
			NSString *changes = [NSString stringWithContentsOfURL:changesURL encoding:NSUTF8StringEncoding error:NULL];
			NSAlert *newVersAlert = [[NSAlert alloc] init];
			NSString *msgText = [NSString stringWithFormat:@"A new version of CrewBid (%@) is available.", latestVersion];
			NSString *infoText = nil;
			[newVersAlert setMessageText:msgText];
			[newVersAlert setInformativeText:changes];
			[newVersAlert addButtonWithTitle:@"Download New Version"];
			[newVersAlert addButtonWithTitle:@"Later"];
			int returnCode = [newVersAlert runModal];
			if (NSAlertFirstButtonReturn == returnCode) {
				NSString *crewScheduleURLString = @"http://www.macrewsoft.com/bin/CrewBid.dmg.zip";
				NSURL *crewScheduleURL = [NSURL URLWithString:crewScheduleURLString];
				BOOL newVersionDownloaded = [[NSWorkspace sharedWorkspace] openURL:crewScheduleURL];
//				BOOL newVersionDownloaded = NO;
				[newVersAlert release];
				NSAlert *downloadAlert = [[NSAlert alloc] init];
				if (newVersionDownloaded) {
					msgText = [NSString stringWithFormat:@"CrewBid version %@ successfully downloaded.", latestVersion];
					infoText = @"You should now quit CrewBid and install the version that was just downloaded.";
					[downloadAlert addButtonWithTitle:@"Quit"];
					[downloadAlert addButtonWithTitle:@"Later"];
				} else {
					msgText = @"Download failed.";
					infoText = [NSString stringWithFormat:@"You may obtain the latest version of CrewBid at:\n\n%@\n", crewScheduleURLString];
					[downloadAlert setInformativeText:infoText];
					[downloadAlert addButtonWithTitle:@"OK"];
				}
				[downloadAlert setMessageText:msgText];
				[downloadAlert setInformativeText:infoText];
				returnCode = [downloadAlert runModal];
				if (NSAlertFirstButtonReturn == returnCode && newVersionDownloaded) {
					[NSApp terminate:nil];
				}
				[downloadAlert release];
			}
		} /*else {
			NSLog(@"You have the latest version.");
		}*/
	}
}

- (void)newVersionAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:nil];
	if (NSAlertDefaultReturn == returnCode) {
		NSURL *crewScheduleURL = [NSURL URLWithString:@"http://www.macrewsoft.com/bin/CrewBid.dmg.zip"];
		[[NSWorkspace sharedWorkspace] openURL:crewScheduleURL];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!_appVersionData) {
		_appVersionData = [[NSMutableData alloc] init];
	}
	[_appVersionData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self checkForNewVersion];
}

#pragma mark ACCESSORS

- (CBMainPreferencesWindowController *)preferencesController { return preferencesController; }
- (CBNewBidWindowController *)newBidController { return newBidController; }
- (CBFileSelectWindowController *)openFileController { return openFileController; }
- (NSWindow *)progressWindow { return progressWindow; }

@end
