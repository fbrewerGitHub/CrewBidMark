//
//  CBBidFileDownload.h
//  CrewBid
//
//  Created by Mark Ackerman on Fri Jul 16 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBBidCredentialWindowController;
@class CBBidFileWindowController;
@class CBProgressWindowController;

@interface CBBidFileDownload : NSObject
{
   // credential window
   CBBidCredentialWindowController * credentialController;
   // progress window
   CBProgressWindowController *      progressController;
   // url connections
   NSURLConnection *                 preLogonConnection;
   NSURLConnection *                 credentialConnection;
   NSURLConnection *                 fileConnection;
   NSMutableData *                   urlData;
   NSString *                        requestBody;
   // file info
   NSString *                        filename;
   NSString *                        directoryPath;
   // owner
   CBBidFileWindowController *       owner;
   // is bid submission
   BOOL                              isBidSubmission;
}

#pragma mark INITIALIZATION
- (id)initWithBidDataFile:(NSString *)name directory:(NSString *)path requestBody:(NSString *)body owner:(CBBidFileWindowController *)inOwner;

#pragma mark ACTIONS
- (void)credentialWindowButtonAction:(id)sender;
- (void)progressWindowCancelButtonAction:(id)sender;

#pragma mark INTERFACE MANAGEMENT
- (void)showCredentialWindow;
- (void)setProgressText:(NSString *)text;

#pragma mark CONNECTION METHODS
- (void)startPreLogonCredentialConnection;
- (void)startSessionCredentialConnectionWithPreLogonCredential:(NSString *)credential;
- (void)startFileConnectionWithSessionCredential:(NSString *)credential;
- (NSString *)credentialWithData:(NSData *)credentialData;
- (void)cancelConnection;

#pragma mark ERROR HANDLING
- (BOOL)isValidDataForConnection:(NSURLConnection *)connection;
//- (NSString *)errorReasonWithData:(NSData *)data; // not used for now
- (void)handleErrorForConnection:(NSURLConnection *)connection;
- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (OSStatus) openHelpPage:(NSString *)pagePath anchor:(NSString *)anchorName;

#pragma mark ACCESSORS
// credential window
- (CBBidCredentialWindowController *)credentialController;
- (NSWindow *)credentialWindow;
- (NSTextField *)userIdTextField;
- (NSTextField *)passwordTextField;
- (NSButton *)credentialOkButton;
- (NSButton *)credentialCancelButton;
// progress window
- (CBProgressWindowController *)progressController;
- (NSWindow *)progressWindow;
- (NSTextField *)progressTextField;
- (NSProgressIndicator *)progressIndicator;
- (NSButton *)progressCancelButton;
// url connections
- (NSURLConnection *)preLogonConnection;
- (void)setPreLogonConnection:(NSURLConnection *)inValue;
- (NSURLConnection *)credentialConnection;
- (void)setCredentialConnection:(NSURLConnection *)inValue;
- (NSURLConnection *)fileConnection;
- (void)setFileConnection:(NSURLConnection *)inValue;
- (NSMutableData *)urlData;
- (void)setUrlData:(NSMutableData *)inValue;
- (NSString *)requestBody;
- (void)setRequestBody:(NSString *)inValue;
// file info
- (NSString *)filename;
- (void)setFilename:(NSString *)inValue;
- (NSString *)directoryPath;
- (void)setDirectoryPath:(NSString *)inValue;
// no set accessor for parent window since it is not retained
- (CBBidFileWindowController *)owner;
// is bid submission
- (BOOL)isBidSubmission;
- (void)setIsBidSubmission:(BOOL)inValue;

@end
