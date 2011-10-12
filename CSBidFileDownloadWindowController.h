//
//  CSBidFileDownloadWindowController.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 5/12/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CSBidPeriod;
@class CSBidFileDownload;


@interface CSBidFileDownloadWindowController : NSWindowController
{
    IBOutlet NSView *progressView;
    CSBidPeriod *_bidPeriod;
    CSBidFileDownload *_bidFileDownload;
	NSArray *_selectedBidPeriodIndexes;
    NSView *_windowView;
    BOOL _enableOkButton;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithWindowNibName:(NSString *)windowNibName bidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)okButtonAction:(id)sender;
- (void)bidFileDownloadDidFinish:(NSNotification *)notification;
- (void)bidFileDownloadDidFinish;
- (void)displayError:(NSError *)error forWindow:(NSWindow *)window;
- (void)errorAlerDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)progressCancelButtonAction:(id)sender;

#pragma mark
#pragma mark User Interface
#pragma mark

- (void)showProgressInterface;
- (void)showWindowInterface;
- (void)exchangeWindowViewWithView:(NSView *)otherView;

#pragma mark
#pragma mark File Download
#pragma mark

- (void)downloadBidData;
- (NSArray *)bidFilesToDownload;
- (NSString *)nextBidReceipt;

#pragma mark
#pragma mark Accessors
#pragma mark

- (CSBidPeriod *)bidPeriod;
- (void)setBidPeriod:(CSBidPeriod *)value;

- (CSBidFileDownload *)bidFileDownload;
- (void)setBidFileDownload:(CSBidFileDownload *)value;

- (NSArray *)selectedBidPeriodIndexes;
- (void)setSelectedBidPeriodIndexes:(NSArray *)value;

- (NSView *)windowView;
- (void)setWindowView:(NSView *)value;

- (BOOL)enableOkButton;
- (void)setEnableOkButton:(BOOL)value;

@end

extern NSString *CSBidFileDownloadWindowControllerDidFinishNotification;
