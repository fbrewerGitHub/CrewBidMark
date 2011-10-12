//
//  CBPreferencesWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CBPreferencesWindowController : NSWindowController
{
   // user info tab
   IBOutlet NSTextField *employeeNumberTextField;
   IBOutlet NSTextField *employeeBid1TextField;
   IBOutlet NSTextField *employeeBid2TextField;
   IBOutlet NSTextField *employeeBid3TextField;
   IBOutlet NSTextField *employee1StaticText;
   IBOutlet NSTextField *employee2StaticText;
   IBOutlet NSTextField *employee3StaticText;
   IBOutlet NSMatrix    *crewPositionMatrix;
   // application tab
   IBOutlet NSTextField * amEarliestDepartTimeTextField;
   IBOutlet NSTextField * amLatestArrivalTimeTextField;
}

#pragma mark INITIALIZATION
- (void)initializeValuesFromUserDefaults;
- (void)updateEmployeeBidTextFieldsAfterCrewPositionChange;

#pragma mark ACTIONS
// user info tab
- (IBAction)employeeNumberTextFieldAction:(id)sender;
- (IBAction)employeeBid1TextFieldAction:(id)sender;
- (IBAction)employeeBid2TextFieldAction:(id)sender;
- (IBAction)employeeBid3TextFieldAction:(id)sender;
- (IBAction)crewPositionMatrixAction:(id)sender;
// application tab
- (IBAction)amEarliestDepartTimeTextFieldAction:(id)sender;
- (IBAction)amLatestArrivalTimeTextFieldAction:(id)sender;

#pragma mark INPUT VALIDATION
- (BOOL)sheetForEmployeeNumberTextFieldFormatFailure:(NSString *)string errorDescription:(NSString *)error control:(NSControl *)control;
- (void)employeeTextFieldSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (NSString *)textFieldWithControl:(NSControl *)control;

#pragma mark ACCESSORS
// user info tab
- (NSTextField *)employeeNumberTextField;
- (NSTextField *)employeeBid1TextField;
- (NSTextField *)employeeBid2TextField;
- (NSTextField *)employeeBid3TextField;
- (NSTextField *)employee1StaticText;
- (NSTextField *)employee2StaticText;
- (NSTextField *)employee3StaticText;
- (NSMatrix *)crewPositionMatrix;
// application tab
- (NSTextField *)amEarliestDepartTimeTextField;
- (NSTextField *)amLatestArrivalTimeTextField;

@end

#pragma mark USER DEFAULT KEYS
extern NSString *CBEmployeeNumberKey;
extern NSString *CBEmployeeBid1Key;
extern NSString *CBEmployeeBid2Key;
extern NSString *CBEmployeeBid3Key;
extern NSString *CBCrewPositionKey;
extern NSString *CBAmArrivalTimePreferencesKey;
extern NSString *CBAmDepartTimePreferencesKey;
#pragma mark NOTIFICATIONS
extern NSString *CBAmTimePreferencesChangedNotification;
