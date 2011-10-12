//
//  CBRegistrationWindowController.m
//  CrewBid
//
//  Created by Mark on 3/2/05.
//  Copyright 2005 Mark Ackerman. All rights reserved.
//

#import "CBRegistrationWindowController.h"

NSString *CBRegistrationWindowControllerDidFinish = 
   @"CBRegistration Window Controller Did Finish";
   
@implementation CBRegistrationWindowController

#pragma mark INITIALIZATION

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBRegistration"]) {
      [self setShouldCascadeWindows:NO];
   }
   return self;
}

- (IBAction)doneButtonAction:(id)sender
{
   [super doneButtonAction:sender];
   // if window is not visible, then it was ordered out in super's
   // doneButtonAction: method
   // app controller will receive notification that registration window is
   // finished and will stop modal and release registration window controller
   if (![[self window] isVisible])
   {
      [[NSNotificationCenter defaultCenter] postNotificationName:CBRegistrationWindowControllerDidFinish object:self userInfo:nil];
   }
}

- (void)controlTextDidChange:(NSNotification *)notification
{
   NSControl *control = [notification object];
   if (control == [self employeeNumberTextField]) {
      [[self okButton] setEnabled:([[[self employeeNumberTextField] stringValue] length] > 0)];
   }
}

- (NSButton *)okButton
{
   return okButton;
}

@end
