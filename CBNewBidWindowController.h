//
//  CBNewBidWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBBidFileWindowController.h"

@class CBProgressWindowController;
@class CBBidFileDownload;

@interface CBNewBidWindowController : CBBidFileWindowController
{
   IBOutlet NSPopUpButton *    monthPopUpButton;
   IBOutlet NSPopUpButton *    basePopUpButton;
   IBOutlet NSPopUpButton *    seatPopUpButton;
   IBOutlet NSPopUpButton *    roundPopUpButton;
   NSString *                  crewBidDirectoryPath;
   CBProgressWindowController * progressController;
   NSCalendarDate *            bidMonth;
   NSString *                  crewBase;
   NSString *                  seatPosition;
}

#pragma mark INITIALIZATION
- (id)initWithCrewBidDirectory:(NSString *)path;
- (void)initializeMonthPopUpButton;
- (void)initializeBasePopUpButton;
- (void)initializeSeatPopUpButton;
- (void)initializeRoundPopUpButton;

#pragma mark ACTIONS
- (IBAction)okButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)basePopUpButtonAction:(id)sender;
- (IBAction)seatPopUpButtonAction:(id)sender;
- (IBAction)roundPopUpButtonAction:(id)sender;

#pragma mark DOCUMENT CREATION
- (void)openDocumentWithDataFile:(NSString *)path;

#pragma mark ERROR HANDLING
- (void)handleErrorTitle:(NSString *)title message:(NSString *)message;
- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)conetextInfo;

#pragma mark FILE AND PATH METHODS
- (NSString *)dataFileName;
- (NSString *)documentFileName;
- (NSString *)textFileName;

#pragma mark ACCESSORS
- (NSPopUpButton *)monthPopUpButton;
- (NSPopUpButton *)basePopUpButton;
- (NSPopUpButton *)seatPopUpButton;
- (NSPopUpButton *)roundPopUpButton;
- (NSString *)crewBidDirectoryPath;
- (void)setCrewBidDirectoryPath:(NSString *)inValue;
- (CBBidFileDownload *)bidFileDownload;
- (CBProgressWindowController *)progressController;
- (NSCalendarDate *)bidMonth;
- (void)setBidMonth:(NSCalendarDate *)inValue;
- (NSString *)crewBase;
- (void)setCrewBase:(NSString *)inValue;
- (NSString *)seatPosition;
- (void)setSeatPosition:(NSString *)inValue;

@end

#pragma mark USER DEFAULT KEYS
extern NSString *CBCrewBaseKey;
extern NSString *CBCrewPositionKey;
extern NSString *CBMostRecentOpenedBidFileKey;

#pragma mark NOTIFICATION AND KEYS
extern NSString * CBNewBidControllerDidFinish;
