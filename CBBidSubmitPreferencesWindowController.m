//
//  CBBidSubmitPreferencesWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Thu Jul 22 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBBidSubmitPreferencesWindowController.h"
#import "CBMainWindowController.h"


@implementation CBBidSubmitPreferencesWindowController

#pragma mark INTIALIZATION

// used for bid submission
- (id)initWithRound:(int)round
{
    if (1 == round)
    {
        self = [self init];
        [self setIsFirstRoundBid:YES];
    }
    else
    {
        self = [super initWithWindowNibName:@"CBBidSubmitSecondRound"];
        [self setIsFirstRoundBid:NO];
    }
    return self;
}

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBBidSubmit"]) {
   }
   return self;
}

#pragma mark ACTIONS

- (IBAction)submitBidButtonAction:(id)sender
{
   actionButton = sender;
   [[self window] makeFirstResponder:[self window]];
   if ([[self window] isVisible])
   {
      [NSApp endSheet:[self window] returnCode:NSAlertDefaultReturn];
   }
}
- (IBAction)cancelButtonAction:(id)sender
{
   actionButton = sender;
   [NSApp endSheet:[self window] returnCode:NSAlertAlternateReturn];
}

#pragma mark ACCESSORS
- (NSButton *)submitBidButton { return submitBidButton; }
- (NSButton *)cancelButton { return cancelButton; }
- (NSButton *)actionButton { return actionButton; }

- (BOOL)isFirstRoundBid {
    return isFirstRoundBid;
}

- (void)setIsFirstRoundBid:(BOOL)value {
    if (isFirstRoundBid != value) {
        isFirstRoundBid = value;
    }
}

@end
