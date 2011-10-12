//
//  CBBidCredentialWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon Apr 26 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBBidCredentialWindowController.h"

#pragma mark NOTFICATION AND KEYS
NSString * CBBidCredentialWindowControllerDidFinishNotification = @"CBCredentialWindowController Did Finish Notification";
NSString * CBBidCredentialUserIdKey = @"CBBidCredential UserId Key";
NSString * CBBidCredentialPasswordKey = @"CBBidCredential Password Key";

@implementation CBBidCredentialWindowController

- (id)init
{
   if (self = [super initWithWindowNibName:@"CBBidCredentials"]) {
      // load window
      [self window];
   }
   return self;
}

- (void)dealloc
{
   [super dealloc];
}

- (void)awakeFromNib
{
   [[self window] center];
}

#pragma mark ACTIONS

- (IBAction)okButtonAction:(id)sender
{
   [[self window] orderOut:nil];
   // post notification
   NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[[self userIdTextField] stringValue], CBBidCredentialUserIdKey, [[self passwordTextField] stringValue], CBBidCredentialPasswordKey, nil];
   [[NSNotificationCenter defaultCenter] postNotificationName:CBBidCredentialWindowControllerDidFinishNotification object:self userInfo:userInfo];
}

- (IBAction)cancelButtonAction:(id)sender
{
   [[self window] orderOut:nil];
   [[NSNotificationCenter defaultCenter] postNotificationName:CBBidCredentialWindowControllerDidFinishNotification object:self userInfo:nil];
}

#pragma mark INTERFACE MANAGEMENT

- (void)validateOKButton
{
   if (([[[self userIdTextField] stringValue] length] > 0) && ([[[self passwordTextField] stringValue] length] > 0)) {
      [[self okButton] setEnabled:YES];
   } else {
      [[self okButton] setEnabled:NO];
   }
}

#pragma INTERFACE DELGATE METHODS

- (void)controlTextDidChange:(NSNotification *)notification
{
   [self validateOKButton];
}

#pragma mark ACCESSORS

- (NSTextField *)userIdTextField { return userIdTextField; }
- (NSTextField *)passwordTextField { return passwordTextField; }
- (NSButton *)okButton { return okButton; }
- (NSButton *)cancelButton { return cancelButton; }

@end
