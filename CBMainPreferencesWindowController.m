//
//  CBMainPreferencesWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 22 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainPreferencesWindowController.h"

#pragma mark USER DEFAULT KEYS
NSString * CBSaveBidBeforeSubmitKey = @"Save Bid Before Submit";

@implementation CBMainPreferencesWindowController

#pragma mark INITIALIZATION

- (void)awakeFromNib
{
   [super awakeFromNib];
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   NSCellStateValue saveBidBeforeSubmitCheckboxState = (([[defaults objectForKey:CBSaveBidBeforeSubmitKey] boolValue] == YES) ? NSOnState : NSOffState);
   [[self saveBidBeforeSubmitCheckbox] setState:saveBidBeforeSubmitCheckboxState];
   [[self window] center];
}

#pragma mark ACTIONS

- (IBAction)doneButtonAction:(id)sender
{
   // setting first responder forces commit of pending edits, so values
   // are saved to user defaults when window is closed
   [[self window] makeFirstResponder:[self window]];
   
   // close window if there is not an attached sheet (which would indicate
   // a formatting error in one of the text fields
   if (nil == [[self window] attachedSheet])
   {
      // end modal session if window is being displayed modally (such as during
      // first start up
      if ([NSApp modalWindow])
      {
         [NSApp stopModal];
      }
      [[self window] orderOut:nil];
   }
}

- (IBAction)saveBidBeforeSubmitCheckboxAction:(id)sender
{
   NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
   BOOL saveBidBeforeSubmit = (NSOnState == [[self saveBidBeforeSubmitCheckbox] state]);
   NSNumber * saveBidBeforeSubmitNumber = [NSNumber numberWithBool:saveBidBeforeSubmit];
   [userDefaults setObject:saveBidBeforeSubmitNumber forKey:CBSaveBidBeforeSubmitKey];
}

#pragma mark ACCESSORS
// application tab
- (NSButton *)saveBidBeforeSubmitCheckbox { return saveBidBeforeSubmitCheckbox; }

@end
