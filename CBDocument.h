//
//  CBDocument.h
//  CrewBid
//
//  Created by Mark Ackerman on Fri Apr 23 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CBNotificationAndKeyStrings.h"

@class CBDataModel;
@class CBMainWindowController;
@class CBPreferencesWindowController;

@interface CBDocument : NSDocument
{
   CBDataModel * dataModel;
}

#pragma mark ACTIONS
- (void)saveChoices:(id)sender;
- (void)applyChoices:(id)sender;
- (void)choicesSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)choicesOpenPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)showCoverLetter:(id)sender;
- (void)showSeniorityList:(id)sender;
- (void)showBidLinesText:(id)sender;
- (void)showTripsText:(id)sender;
- (IBAction)retrieveBidAwards:(id)sender;
- (IBAction)showBidAwards:(id)sender;
- (void)bidAwardsAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)submitBid:(id)sender;
- (void)showBidReceipt:(id)sender;
- (void)showBidReceiptSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)sortByColumns:(id)sender;

#pragma mark ACCESSORS
- (CBDataModel *)dataModel;
- (void)setDataModel:(CBDataModel *)inValue;
- (CBMainWindowController *)mainWindowController;

@end
