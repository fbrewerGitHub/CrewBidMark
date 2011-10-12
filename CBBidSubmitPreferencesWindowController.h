//
//  CBBidSubmitPreferencesWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 22 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBPreferencesWindowController.h"

@interface CBBidSubmitPreferencesWindowController : CBPreferencesWindowController
{
   IBOutlet NSButton * submitBidButton;
   IBOutlet NSButton * cancelButton;
   NSButton * actionButton;
   BOOL isFirstRoundBid;
}

#pragma mark Initialization
- (id)initWithRound:(int)round;

#pragma mark ACTIONS
// text field actions are in CBPreferencesWindowController
- (IBAction)submitBidButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

#pragma mark ACCESSORS
- (NSButton *)submitBidButton;
- (NSButton *)cancelButton;
- (NSButton *)actionButton;
- (BOOL)isFirstRoundBid;
- (void)setIsFirstRoundBid:(BOOL)value;

@end
