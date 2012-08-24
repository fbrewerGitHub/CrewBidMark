//
//  CBBidFileDownload.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri Jul 16 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBBidFileDownload.h"
#import "CBMainWindowController.h"
#import "CBBidFileWindowController.h"
#import "CBBidCredentialWindowController.h"
#import "CBProgressWindowController.h"
#import <Carbon/Carbon.h>

//NSString * THIRD_PARTY_URL = @"https://www.myswa.com/webbid3pty/ThirdParty";
NSString * THIRD_PARTY_URL = @"https://www1.swalife.com/webbid3pty/ThirdParty";
//NSString * THIRD_PARTY_URL = @"https://www14.swalife.com/webbid3pty/ThirdParty";
NSString * CREDENTIAL_REQUEST = @"CREDENTIALS=%@&REQUEST=LOGON&UID=%@&PWD=%@";

@class CBMainWindowController;

@implementation CBBidFileDownload

#pragma mark INITIALIZATION

- (id)initWithBidDataFile:(NSString *)name directory:(NSString *)path requestBody:(NSString *)body owner:(CBBidFileWindowController *)inOwner
{
   if (self = [super init]) {
      // set up data members
      [self setFilename:name];
      [self setDirectoryPath:path];
      [self setRequestBody:body];
      owner = inOwner;
      if ([owner isKindOfClass:[CBMainWindowController class]]) {
         [self setIsBidSubmission:YES];
      } else {
         [self setIsBidSubmission:NO];
      }
   }
   return self;
}

- (void)dealloc
{
   [credentialController release];
   [progressController release];
   [preLogonConnection release];
   [credentialConnection release];
   [fileConnection release];
   [urlData release];
   [filename release];
   [directoryPath release];
   [super dealloc];
}

#pragma mark ACTIONS

- (void)credentialWindowButtonAction:(id)sender
{
   // end modal session
   [NSApp endSheet:[sender window]];
   [[sender window] orderOut:self];

   if (sender == [self credentialOkButton]) {
      [self startPreLogonCredentialConnection];

   }
}

- (void)progressWindowCancelButtonAction:(id)sender
{
   [self cancelConnection];
   NSWindow * senderWindow = [(NSButton *)sender window];
   [NSApp endSheet:senderWindow];
   [senderWindow orderOut:self];
   [owner cancelBidFileDownload];
}

#pragma mark INTERFACE MANAGEMENT

- (void)showCredentialWindow
{
   if (![self credentialController]) {
      credentialController = [[CBBidCredentialWindowController alloc] init];
      [[credentialController okButton] setTarget:self];
      [[credentialController okButton] setAction:@selector(credentialWindowButtonAction:)];
      [[credentialController cancelButton] setTarget:self];
      [[credentialController cancelButton] setAction:@selector(credentialWindowButtonAction:)];
   }
   // reset credential window text fields
   [[self userIdTextField] setStringValue:@""];
   [[self passwordTextField] setStringValue:@""];
   [[self credentialWindow] makeFirstResponder:[self userIdTextField]];
   // display credential window as sheet modal for owner's window
   [NSApp beginSheet:[self credentialWindow] modalForWindow:[[self owner] window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (void)setProgressText:(NSString *)text
{
   [[self progressController] setProgressText:text];
}

#pragma mark CONNECTION METHODS

- (void)startPreLogonCredentialConnection
{
   // initialize url data
   [self setUrlData:[NSMutableData data]];
   // load and set up progress window, if not already loaded
   progressController = [[CBProgressWindowController alloc] init];
   [self setProgressText:@"Connecting..."];
   [[self progressCancelButton] setTarget:self];
   [[self progressCancelButton] setAction:@selector(progressWindowCancelButtonAction:)];
   // run progress window modal for owner's window
   [NSApp beginSheet:[self progressWindow] modalForWindow:[[self owner] window] modalDelegate:self didEndSelector:NULL contextInfo:nil];
   // start preLogonConnection
   NSURL * url = [NSURL URLWithString:THIRD_PARTY_URL];
   NSURLRequest * request = [NSURLRequest requestWithURL:url];
   NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
   [self setPreLogonConnection:connection];
}

- (void)startSessionCredentialConnectionWithPreLogonCredential:(NSString *)credential
{
   // update progress text
   [self setProgressText:@"Logging In..."];
   // create request body from credential window user interface
   // set up session credential request with pre-logon credential, userId, and password
   NSURL * url = [NSURL URLWithString:THIRD_PARTY_URL];
   NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
   [request setHTTPMethod:@"POST"];
   NSString * password = [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[self passwordTextField] stringValue], NULL, CFSTR("!@$*()-_=+:;\'?,./"), kCFStringEncodingUTF8) autorelease];
   NSString * sessionCredentialHTTPBody = [NSString stringWithFormat:CREDENTIAL_REQUEST, credential, [[self userIdTextField] stringValue], password];
   NSData * bodyData = [sessionCredentialHTTPBody dataUsingEncoding:NSUTF8StringEncoding];
   unsigned contentLength = [bodyData length];
   [request setValue:[NSString stringWithFormat:@"%u", contentLength] forHTTPHeaderField:@"Content-Length"];
   [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
   [request setHTTPBody:bodyData];
   // start the connection
   NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
   [self setCredentialConnection:connection];
}

- (void)startFileConnectionWithSessionCredential:(NSString *)credential
{
   NSString * fileConnectionProgressText = nil;
   if ([self isBidSubmission]) {
      fileConnectionProgressText = @"Submitting bid...";
   } else {
      fileConnectionProgressText = @"Downloading data file...";
   }
   // update progress text
   [self setProgressText:fileConnectionProgressText];
   // create file connection request body from session credential
   NSURL * url = [NSURL URLWithString:THIRD_PARTY_URL];
   NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
   [request setHTTPMethod:@"POST"];
   NSString * fileConnectionHTTPBody = [NSString stringWithFormat:[self requestBody], credential];
   NSData * bodyData = [fileConnectionHTTPBody dataUsingEncoding:NSUTF8StringEncoding];
   unsigned contentLength = [bodyData length];
   [request setValue:[NSString stringWithFormat:@"%u", contentLength] forHTTPHeaderField:@"Content-Length"];
   [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
   [request setHTTPBody:bodyData];
   // start the connection
   NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
   [self setFileConnection:connection];
}

- (NSString *)credentialWithData:(NSData *)credentialData
{
   NSString * credential = nil;
   NSString * credentialDataString = [[[NSString alloc] initWithData:credentialData encoding:NSUTF8StringEncoding] autorelease];
   NSArray * credentialArray = [credentialDataString componentsSeparatedByString:@"\r"];
   if ([credentialArray count] > 0) {
      credential = [credentialArray objectAtIndex:0u];
   }
   // escape + characters, but not space character (to prevent escaping of
   // spaces in error messages)
   credential = [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)credential, CFSTR(" "), CFSTR("+"), kCFStringEncodingUTF8) autorelease];
   return credential;
}

- (void)cancelConnection
{
   // cancel any active connection
   if([self preLogonConnection]) {
      [[self preLogonConnection] cancel];
   }
   if([self credentialConnection]) {
      [[self credentialConnection] cancel];
   }
   if([self fileConnection]) {
      [[self fileConnection] cancel];
   }
}

#pragma mark ERROR HANDLING

- (BOOL)isValidDataForConnection:(NSURLConnection *)connection
{
   // data for pre-logon connection can be just about anything
   // data for credential connection cannot start with ERROR
   // bid data file should start with 0x50 0x4b 0x03 0x04
   // bid receipt should start with bidder's employee number
   
   // quick fix for case where url data is not nil but has length 0
   if ([self urlData] == nil || [[self urlData] length] < 6) {
      return NO;
   }

   BOOL isValidData = YES;
   NSData *   errorAsData = [@"ERROR" dataUsingEncoding:NSUTF8StringEncoding];
   NSData *   urlDataFirst5Bytes = [[self urlData] subdataWithRange:NSMakeRange(0u, 5u)];
   NSString * bidder = nil;
   NSString * bidReceiptBidder = nil;
   NSData *   urlDataFirst4Bytes = nil;
   // see http://www.pkware.com/products/enterprise/white_papers/appnote.txt
   // for description of first four bytes of zipped file
   char       bidFileStart[4] = { 0x50, 0x4b, 0x03, 0x04 };
   NSData *   bidDataFileFirst4Bytes = [NSData dataWithBytes:bidFileStart length:4u];
   
   // check for ERROR at beginning of urlData
   if ([urlDataFirst5Bytes isEqualToData:errorAsData]) {
      isValidData = NO;

   // for file connection, if bid submission, check bid receipt; if bid data
   // file download, check zipped file
   } else if (connection == [self fileConnection]) {
   
      // check bid receipt
      if ([self isBidSubmission]) {
      
         // bid receipt should begin with bidder's empolyee number
         bidder = [[NSUserDefaults standardUserDefaults] objectForKey:@"Employee Number"];
         bidReceiptBidder = [[[NSString alloc] initWithData:[[self urlData] subdataWithRange:NSMakeRange(0u, [bidder length])] encoding:NSUTF8StringEncoding] autorelease];
         
         if (NO == [bidReceiptBidder isEqualToString:bidder]) {
            isValidData = NO;
         }

      // check bid data file
      } else {
      
      // zipped data file should begin with 0x50 0x4b 0x03 0x04
         urlDataFirst4Bytes = [[self urlData] subdataWithRange:NSMakeRange(0u, 4u)];

         if (NO == [urlDataFirst4Bytes isEqualToData:bidDataFileFirst4Bytes]) {
            isValidData = NO;
         }
      }
   }
   return isValidData;
}

/* NOT USED FOR NOW
- (NSString *)errorReasonWithData:(NSData *)data
{
   // remove "ERROR: " from beginning and "CR/LF" from end of error reason
   // received from SWA server

   NSString * dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

   // remove CR/LF from end
   unsigned endIndex = 0;
   [dataString getLineStart:NULL end:NULL contentsEnd:&endIndex forRange:NSMakeRange(0, [dataString length])];

   // remove ERROR from beginning
   NSString * errorReason = [dataString substringWithRange:NSMakeRange(7u, endIndex - 7)];

   return errorReason;
}
*/

- (void)handleErrorForConnection:(NSURLConnection *)connection
{
   NSString * errorTitle = nil;
   NSString * errorMessage = nil;
   NSString * helpPage = nil;
   
   if ([self isBidSubmission]) {
      errorTitle = @"Bid submission failed";
   } else {
      errorTitle = @"Bid data file download failed";
   }

   // determine at which stage the error occurred
   if (connection == [self preLogonConnection]) {
      errorMessage = @"Could not connect to the SWA server. Please make sure that you have established an internet connection and that your computer's date is set correctly.";
      helpPage = @"html/error/no_connect.htm";
      [self setPreLogonConnection:nil];
   } else if (connection == [self credentialConnection]) {
      errorMessage = @"Could not log in to the SWA server. Please make sure that you entered your User ID and Password correctly.";
      helpPage = @"html/error/no_logon.htm";
      [self setCredentialConnection:nil];
   } else if (connection == [self fileConnection]) {
      if ([self isBidSubmission]) {

//         errorMessage = @"Could not submit bid. Please make sure that bidding is open for this bid period.";
         errorMessage = [[[NSString alloc] initWithData:[self urlData] encoding:NSUTF8StringEncoding] autorelease];


         helpPage = @"html/error/no_submit.htm";
      } else {
         errorMessage = @"Could not download bid data file. Please make sure that bid data is available for this bid period.";
         helpPage = @"html/error/no_bid_data.htm";
      }
      [self setFileConnection:nil];
   }
    
    // Supress complier warning for possible insecure format ('errorMessage' is
    // not a string literal).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
   NSBeginAlertSheet(errorTitle, @"OK", @"Help", nil, [[self owner] window], self, @selector(errorSheetDidEnd:returnCode:contextInfo:), NULL, [helpPage retain], errorMessage);
#pragma clang diagnostic pop
}

- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
   OSStatus err = noErr;
   
   if (NSAlertDefaultReturn == returnCode) {
      // do noting
   } else if (NSAlertAlternateReturn == returnCode) {
      // open help page
      // contextInfo is CFStringRef with relative path to help page
      err = [self openHelpPage:(NSString *)contextInfo anchor:nil];
   }
   
   [(NSString *)contextInfo release];
   
   [[self owner] handleDownloadError];
}

- (OSStatus) openHelpPage:(NSString *)pagePath anchor:(NSString *)anchorName
{
   CFBundleRef applicationBundle = NULL;
   CFStringRef helpBookName = NULL;
   OSStatus err = noErr;

   applicationBundle = CFBundleGetMainBundle();

   if (applicationBundle == NULL) {
      err = fnfErr;
   } else {
      helpBookName = CFBundleGetValueForInfoDictionaryKey (applicationBundle, CFSTR("CFBundleHelpBookName"));
      if (helpBookName == NULL) {
         err = fnfErr;
      } else {
         if (CFGetTypeID(helpBookName) != CFStringGetTypeID()) { 
              err = paramErr;
         } else {
            if (err == noErr) {
               err = AHGotoPage (helpBookName, (CFStringRef)pagePath, (CFStringRef)anchorName);
            }
         }
      }
   }

    return err;
}

#pragma mark URL CONNECTION DELEGATE METHODS

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
   // discard previously received data
   [[self urlData] setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
   // append new data to urlData
   [[self urlData] appendData:data];
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
   // don't cache anything
   return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
   NSString * credential = nil;
   NSString * filePath = nil;
   
   // check for error
   if (NO == [self isValidDataForConnection:connection]) {
      // remove progress sheet
      [NSApp endSheet:[self progressWindow]];
      [[self progressIndicator] stopAnimation:self];
      [[self progressWindow] orderOut:self];
      // handle error
      [self handleErrorForConnection:connection];
      // clean up: connection will be released in handle error method
      [[self urlData] setLength:0u];

   // if no error, continue
   } else {
      // preLogonCredential connection
      if (connection == [self preLogonConnection]) {
         // create pre-logon credential from url data
         credential = [self credentialWithData:[self urlData]];
         // clean up
         [[self urlData] setLength:0u];
         [self setPreLogonConnection:nil];
         // start session credential connection
         [self startSessionCredentialConnectionWithPreLogonCredential:credential];

      // session credential connection
      } else if (connection == [self credentialConnection]) {
         // create session credential from url data
         credential = [self credentialWithData:[self urlData]];
         // clean up
         [self setCredentialConnection:nil];
         [[self urlData] setLength:0u];
         // start file download/bid submission if received good session credential
         [self startFileConnectionWithSessionCredential:credential];
      
      // file connection
      } else if (connection == [self fileConnection]) {
         // disable cancel button in progress window
         [[self progressController] disableCancelButton];
         // write data to file
         filePath = [[self directoryPath] stringByAppendingPathComponent:[self filename]];
         [[self urlData] writeToFile:filePath atomically:YES];
         // clean up
         [[self urlData] setLength:0u];
         // progress sheet will be removed by bid file window controller
         [self setFileConnection:nil];
         // handle downloaded file
         [[self owner] handleDownloadedBidFile:filePath];
      }
   }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
   // remove progress sheet
   [NSApp endSheet:[self progressWindow]];
   [[self progressWindow] orderOut:self];
   // clean up: connection will be released in handleError: method
   [[self urlData] setLength:0u];
   // handle error
   [self handleErrorForConnection:connection];
}

#pragma mark ACCESSORS

// credential window
- (CBBidCredentialWindowController *)credentialController { return credentialController; }
- (NSWindow *)credentialWindow { return [credentialController window]; }
- (NSTextField *)userIdTextField { return [credentialController userIdTextField]; }
- (NSTextField *)passwordTextField { return [credentialController passwordTextField]; }
- (NSButton *)credentialOkButton { return [credentialController okButton]; }
- (NSButton *)credentialCancelButton { return [credentialController cancelButton]; }

// progress window
- (CBProgressWindowController *)progressController { return progressController; }
- (NSWindow *)progressWindow { return [progressController window]; }
- (NSTextField *)progressTextField { return [progressController progressTextField]; }
- (NSProgressIndicator *)progressIndicator { return [progressController progressIndicator]; }
- (NSButton *)progressCancelButton { return [progressController cancelButton]; }

// url connections
- (NSURLConnection *)preLogonConnection { return preLogonConnection; }
- (void)setPreLogonConnection:(NSURLConnection *)inValue
{
   if (preLogonConnection != inValue) {
      [preLogonConnection release];
      preLogonConnection = [inValue retain];
   }
}

- (NSURLConnection *)credentialConnection { return credentialConnection; }
- (void)setCredentialConnection:(NSURLConnection *)inValue
{
   if (credentialConnection != inValue) {
      [credentialConnection release];
      credentialConnection = [inValue retain];
   }
}

- (NSURLConnection *)fileConnection { return fileConnection; }
- (void)setFileConnection:(NSURLConnection *)inValue
{
   if (fileConnection != inValue) {
      [fileConnection release];
      fileConnection = [inValue retain];
   }
}

- (NSMutableData *)urlData { return urlData; }
- (void)setUrlData:(NSMutableData *)inValue
{
   if (urlData != inValue) {
      [urlData release];
      urlData = [inValue retain];
   }
}

- (NSString *)requestBody { return requestBody; }
- (void)setRequestBody:(NSString *)inValue
{
   if (requestBody != inValue) {
      [requestBody release];
      requestBody = [inValue retain];
   }
}

// file info
- (NSString *)filename { return filename; }
- (void)setFilename:(NSString *)inValue
{
   if (filename != inValue) {
      [filename release];
      filename = [inValue retain];
   }
}

- (NSString *)directoryPath { return directoryPath; }
- (void)setDirectoryPath:(NSString *)inValue
{
   if (directoryPath != inValue) {
      [directoryPath release];
      directoryPath = [inValue retain];
   }
}

// no set accessor for parent window since it is not retained
- (CBBidFileWindowController *)owner { return owner; }

// is bid submission
- (BOOL)isBidSubmission { return isBidSubmission; }
- (void)setIsBidSubmission:(BOOL)inValue { isBidSubmission = inValue; }

@end
