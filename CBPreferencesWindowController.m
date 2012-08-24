//
//  CBPreferencesWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBPreferencesWindowController.h"

#pragma mark USER DEFAULT KEYS
NSString *CBEmployeeNumberKey = @"Employee Number";
NSString *CBEmployeeBid1Key = @"Employee Bid 1";
NSString *CBEmployeeBid2Key = @"Employee Bid 2";
NSString *CBEmployeeBid3Key = @"Employee Bid 3";
NSString *CBCrewPositionKey = @"Crew Position";
NSString *CBAmDepartTimePreferencesKey = @"AM Depart Time";
NSString *CBAmArrivalTimePreferencesKey = @"AM Arrival Time";
NSString *CBAmTimePreferencesChangedNotification = @"AM Time Preferences Changed";

@implementation CBPreferencesWindowController

#pragma mark INITIALIZATION

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBPreferences"]) {
      [self setShouldCascadeWindows:NO];
   }
   return self;
}

- (void)awakeFromNib
{
   // do not allow decimal points in employee number or time text fields
   [[[self employeeNumberTextField] formatter] setAllowsFloats:NO];
   [[[self amEarliestDepartTimeTextField] formatter] setAllowsFloats:NO];
   // get values from user defaults
   [self initializeValuesFromUserDefaults];
   // update employee static text fields
   [self updateEmployeeBidTextFieldsAfterCrewPositionChange];
}

- (void)initializeValuesFromUserDefaults
{
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   // user info tab
   [[self employeeNumberTextField] setStringValue:[userDefaults objectForKey:CBEmployeeNumberKey]];
   [[self employeeBid1TextField] setStringValue:[userDefaults objectForKey:CBEmployeeBid1Key]];
   [[self employeeBid2TextField] setStringValue:[userDefaults objectForKey:CBEmployeeBid2Key]];
   [[self employeeBid3TextField] setStringValue:[userDefaults objectForKey:CBEmployeeBid3Key]];
   // application tab
    [[self amEarliestDepartTimeTextField] setObjectValue:[userDefaults objectForKey:CBAmDepartTimePreferencesKey]];
   [[self amLatestArrivalTimeTextField] setObjectValue:[userDefaults objectForKey:CBAmArrivalTimePreferencesKey]];
   // select crew position in crew position matrix
   NSString *crewPos = [userDefaults objectForKey:CBCrewPositionKey];
   NSEnumerator *e = [[[self crewPositionMatrix] cells] objectEnumerator];
   NSButtonCell *bc = nil;
   while (bc = [e nextObject])
   {
      if ([[bc title] isEqualToString:crewPos])
      {
         [[self crewPositionMatrix] selectCell:bc];
      }
   }
}

- (void)updateEmployeeBidTextFieldsAfterCrewPositionChange
{
   NSString *crewPos = [[NSUserDefaults standardUserDefaults] objectForKey:CBCrewPositionKey];

   if ([crewPos isEqualToString:@"Flight Attendant"])
   {
      [[self employee1StaticText] setStringValue:@"Buddy Bid 1:"];
      [[self employee2StaticText] setStringValue:@"Buddy Bid 2:"];
      [[self employee3StaticText] retain];
      [[self employeeBid3TextField] retain];
      [[self employee3StaticText] removeFromSuperview];
      [[self employeeBid3TextField] removeFromSuperview];
   }
   else
   {
      if (![[[[self employee1StaticText] superview] subviews] containsObject:[self employee3StaticText]])
      {
         [[[self employee1StaticText] superview] addSubview:[self employee3StaticText]];
         [employee3StaticText release];
      }
      if (![[[[self employee1StaticText] superview] subviews] containsObject:[self employeeBid3TextField]])
      {
         [[[self employee1StaticText] superview] addSubview:[self employeeBid3TextField]];
         [employeeBid3TextField release];
      }
      [[self employee1StaticText] setStringValue:@"Avoidance Bid 1:"];
      [[self employee2StaticText] setStringValue:@"Avoidance Bid 2:"];
      [[self employee3StaticText] setStringValue:@"Avoidance Bid 3:"];
   }
}

#pragma mark WINDOW DELEGATE METHODS

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
   [self initializeValuesFromUserDefaults];
   [self updateEmployeeBidTextFieldsAfterCrewPositionChange];
}

#pragma mark ACTIONS

- (IBAction)employeeNumberTextFieldAction:(id)sender
{
   // set employee number in user defaults
   NSString * employeeNumber = [[self employeeNumberTextField] stringValue];
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   [userDefaults setObject:employeeNumber forKey:CBEmployeeNumberKey];
}

- (IBAction)employeeBid1TextFieldAction:(id)sender
{
   // set employee bid in user defaults
   NSString * employeeBid = [[self employeeBid1TextField] stringValue];
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   [userDefaults setObject:employeeBid forKey:CBEmployeeBid1Key];
}

- (IBAction)employeeBid2TextFieldAction:(id)sender
{
   // set employee bid in user defaults
   NSString * employeeBid = [[self employeeBid2TextField] stringValue];
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   [userDefaults setObject:employeeBid forKey:CBEmployeeBid2Key];
}

- (IBAction)employeeBid3TextFieldAction:(id)sender
{
   // set employee bid in user defaults
   NSString * employeeBid = [[self employeeBid3TextField] stringValue];
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   [userDefaults setObject:employeeBid forKey:CBEmployeeBid3Key];
}

- (IBAction)crewPositionMatrixAction:(id)sender
{
   NSString *crewPos = [(NSButton *)[(NSMatrix *)sender selectedCell] title];
   if (crewPos)
   {
      [[NSUserDefaults standardUserDefaults] setObject:crewPos forKey:CBCrewPositionKey];
      [self updateEmployeeBidTextFieldsAfterCrewPositionChange];
   }
}

- (IBAction)amEarliestDepartTimeTextFieldAction:(id)sender
{
   // set time in user defaults
   NSNumber * amTime = [NSNumber numberWithInt:[(NSTextField *)sender intValue]];
   [[NSUserDefaults standardUserDefaults] setObject:amTime forKey:CBAmDepartTimePreferencesKey];
   // post notification, which will be received by data model and which will
   // cause am/pm for lines to be updated
   [[NSNotificationCenter defaultCenter] postNotificationName:CBAmTimePreferencesChangedNotification object:nil];
}

- (IBAction)amLatestArrivalTimeTextFieldAction:(id)sender
{
   // set time in user defaults
   NSNumber * amTime = [NSNumber numberWithInt:[(NSTextField *)sender intValue]];
   [[NSUserDefaults standardUserDefaults] setObject:amTime forKey:CBAmArrivalTimePreferencesKey];
   // post notification, which will be received by data model and which will
   // cause am/pm for lines to be updated
   [[NSNotificationCenter defaultCenter] postNotificationName:CBAmTimePreferencesChangedNotification object:nil];
}

#pragma mark INPUT VALIDATION

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
   NSString *textField = nil;
   
   if (0 == [[fieldEditor string] length] &&
         (control == [self employeeNumberTextField] ||
          control == [self amEarliestDepartTimeTextField] ||
          control == [self amLatestArrivalTimeTextField])) {
      textField = [self textFieldWithControl:control];
      return [self sheetForEmployeeNumberTextFieldFormatFailure:[fieldEditor string] errorDescription:[NSString stringWithFormat:@"%@ is empty", textField] control:control];
   }
   return YES;
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
   // find which text field in which the formatting error occurred
   NSString * textField = [self textFieldWithControl:control];
   // greater than 2400 in am time text field
   if ([string intValue] > 2400 &&
          (control == [self amEarliestDepartTimeTextField] ||
          control == [self amLatestArrivalTimeTextField])) {
      // present sheet
      return [self sheetForEmployeeNumberTextFieldFormatFailure:string errorDescription:[NSString stringWithFormat:@"%@ is not a valid time", textField] control:control];
   }
   // non-numeric character error
   else
   {
      return [self sheetForEmployeeNumberTextFieldFormatFailure:string errorDescription:[NSString stringWithFormat:@"%@ contains non-numeric characters", textField] control:control];
   }
}

- (BOOL)sheetForEmployeeNumberTextFieldFormatFailure:(NSString *)string errorDescription:(NSString *)error control:(NSControl *)control
{
   NSString * defaultButtonTitle = nil;
   NSString * alternateButtonTitle = nil;
   NSMutableDictionary * contextInfo = nil;
   NSString *errorDescription = nil;
   // if control is employee number text field and string is blank, then
   // present alert stating that employee number is blank
   if (control == [self employeeNumberTextField] && 0 == [string length])
   {
      defaultButtonTitle = @"Edit";
      errorDescription = @"Please enter your employee number.";
   }
   else if (control == [self amEarliestDepartTimeTextField] ||
      control == [self amLatestArrivalTimeTextField])
   {
      defaultButtonTitle = @"Edit";
      errorDescription = @"Please enter the time using four digits, without any other characters.";
   }
   else
   {
      // create string from user entry that contains only digits 0-9, for use in
      // default button and proposed employee number
      NSMutableString * proposedString = [NSMutableString string];
      NSScanner * scanner = [NSScanner scannerWithString:string];
      [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
      while ([scanner isAtEnd] == NO) {
         NSString * temp = [NSString string];
         [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&temp];
         [proposedString appendString:temp];
      }
      // context info to pass the text field in which the formatting error
      // occurred and the proposed employee number
      // note: must retain the context info, or it will be released when the
      // begin alert sheet method returns
      // context info will be released in sheet did end method
      contextInfo = [[NSMutableDictionary dictionaryWithObjectsAndKeys:control, @"control", proposedString, @"proposed string", nil] retain];
      defaultButtonTitle = [NSString stringWithFormat:@"Use \"%@\"", proposedString];
      alternateButtonTitle = @"Edit";
      errorDescription = @"Please enter just the employee number (no leading \"e\" or other such junk).";
   }
   // if self's window is being run as a sheet (as in a sheet for a bid
   // document main window), then end sheet and include the document window
   // in context info
   NSWindow * sheetModalWindow = nil;
   if ([[self window] isSheet]) {
      sheetModalWindow = [NSApp makeWindowsPerform:@selector(attachedSheet) inOrder:YES];
      if (sheetModalWindow)
      {
         [contextInfo setObject:sheetModalWindow forKey:@"document window"];
      }
      // endSheet:returnCode: calls main document window controller's 
      // bidSubmitSheetDidEnd:returnCode:contextInfo: method, which closes
      // self's window
      // NSAlertErrorReturn causes document window controller to close
      // self's window only
      // NSAlertDefaultReturn or NSAlertAlternate return would cause document
      // window controller to release the bid submit window controller
      [NSApp endSheet:[self window] returnCode:NSAlertErrorReturn];
   } else {
      sheetModalWindow = [self window];
   }

    // Supress compiler warning for possible insecure format string
    // ('errorDescription' not a literal string).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
   NSBeginAlertSheet(error, defaultButtonTitle, alternateButtonTitle, nil, sheetModalWindow, self, @selector(employeeTextFieldSheetDidEnd:returnCode:contextInfo:), NULL, contextInfo, errorDescription);
#pragma clang diagnostic pop
    
   return NO;
}

- (void)employeeTextFieldSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   // if there is context info, then error was that text field contained
   // non-numeric characters
   // if no context info, error was that employee number was blank
   if (contextInfo)
   {
      NSTextField * textField = [(NSDictionary *)contextInfo objectForKey:@"control"];
      NSString * proposedString = [(NSDictionary *)contextInfo objectForKey:@"proposed string"];
      NSWindow * documentWindow = [(NSDictionary *)contextInfo objectForKey:@"document window"];
      // if default button (use proposed employee number), put proposed string
      // in text field and perform control's action so that value is placed
      // in user defaults
      if (NSAlertDefaultReturn == returnCode) {
         if (textField == [self amEarliestDepartTimeTextField] ||
             textField == [self amLatestArrivalTimeTextField]) {
            [textField setIntValue:[proposedString intValue]];
         } else {
            [textField setStringValue:proposedString];
            [textField sendAction:[textField action] to:self];
         }
      // if alternate button (edit), select text in employee number text field
      } else if (NSAlertAlternateReturn == returnCode) {
         [textField abortEditing];
         [textField selectText:nil];
      }
      // if document window is included in context info, then self's window was
      // being run as a sheet for a bid document window, so we should show self's
      // window as a sheet for the document window
      if (documentWindow) {
         [sheet close];
         [NSApp beginSheet:[self window] modalForWindow:documentWindow modalDelegate:[documentWindow windowController] didEndSelector:@selector(bidSubmitSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
      }
      else
      {
         [[self window] makeKeyAndOrderFront:nil];
      }
      // context info was retained in sheet for employee number method, so it
      // must be released here
      [(NSDictionary *)contextInfo release];
   }
}

- (NSString *)textFieldWithControl:(NSControl *)control
{
   NSString *textField = nil;
   NSString *staticText = nil;
   if (control == [self employeeNumberTextField])
   {
      textField = @"Employee Number";
   }
   else if (control == [self amEarliestDepartTimeTextField])
   {
      textField = @"AM trip earliest departure time";
   }
   else if (control == [self amLatestArrivalTimeTextField])
   {
      textField = @"AM trip latest arrival time";
   }
   else
   {
      if (control == [self employeeBid1TextField])
      {
         staticText = [[self employee1StaticText] stringValue];
      }
      else if (control == [self employeeBid2TextField])
      {
         staticText = [[self employee2StaticText] stringValue];
      }
      else if (control == [self employeeBid3TextField])
      {
         staticText = [[self employee3StaticText] stringValue];
      }
      textField = [staticText substringToIndex:[staticText length] - 1];
   }
   return textField;
}

#pragma mark ACCESSORS

// user info tab
- (NSTextField *)employeeNumberTextField { return employeeNumberTextField; }

- (NSTextField *)employeeBid1TextField { return employeeBid1TextField; }

- (NSTextField *)employeeBid2TextField { return employeeBid2TextField; }

- (NSTextField *)employeeBid3TextField { return employeeBid3TextField; }

- (NSTextField *)employee1StaticText { return employee1StaticText; }

- (NSTextField *)employee2StaticText { return employee2StaticText; }

- (NSTextField *)employee3StaticText { return employee3StaticText; }

- (NSMatrix *)crewPositionMatrix { return crewPositionMatrix; }

- (NSTextField *)amEarliestDepartTimeTextField { return amEarliestDepartTimeTextField; }

- (NSTextField *)amLatestArrivalTimeTextField { return amLatestArrivalTimeTextField; }

@end
