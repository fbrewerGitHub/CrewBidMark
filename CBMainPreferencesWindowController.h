//
//  CBMainPreferencesWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 22 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBPreferencesWindowController.h"

@interface CBMainPreferencesWindowController : CBPreferencesWindowController
{
   // user info tab outlets are in CBPreferencesWindowController
   
   // application tab
   IBOutlet NSButton *    saveBidBeforeSubmitCheckbox;
   // other application tab outlets are in CBPreferencesWindowController
}

#pragma mark ACTIONS
// other user info tab actions are in CBPreferencesWindowController
// user info tab
- (IBAction)doneButtonAction:(id)sender;
// application tab
- (IBAction)saveBidBeforeSubmitCheckboxAction:(id)sender;

#pragma mark ACCESSORS
// application tab
- (NSButton *)saveBidBeforeSubmitCheckbox;

@end

#pragma mark USER DEFAULT KEYS
extern NSString *CBSaveBidBeforeSubmitKey;
