//
//  CBBidCredentialWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Mon Apr 26 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class CBBidSession;

@interface CBBidCredentialWindowController : NSWindowController
{
   IBOutlet NSTextField * passwordTextField;
   IBOutlet NSTextField * userIdTextField;
   IBOutlet NSButton *    okButton;
   IBOutlet NSButton *    cancelButton;
}

#pragma mark INITIALIZATION
- (id)init;

#pragma mark ACTIONS
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)okButtonAction:(id)sender;

#pragma mark INTERFACE MANAGEMENT
- (void)validateOKButton;

#pragma mark ACCESSORS
- (NSTextField *)userIdTextField;
- (NSTextField *)passwordTextField;
- (NSButton *)okButton;
- (NSButton *)cancelButton;

@end

#pragma mark NOTFICATION AND KEYS
extern NSString * CBBidCredentialWindowControllerDidFinishNotification;
extern NSString * CBBidCredentialUserIdKey;
extern NSString * CBBidCredentialPasswordKey;