//
//  CBShowTripWindowController.h
//  CrewBid
//
//  Created by mark on 10/19/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBDataModel;

@interface CBShowTripWindowController : NSWindowController
{
	IBOutlet NSPanel *     tripPanel;
	IBOutlet NSTextView *  tripTextView;
	IBOutlet NSTextField * tripTextField;
	IBOutlet NSButton *    showTripButton;
	IBOutlet NSButton *    cancelButton;
	CBDataModel *          dataModel;
}

#pragma mark INITIALIZATION
- (id)initWithDataModel:(CBDataModel *)inDataModel;

#pragma mark ACTIONS
- (void)showTripButtonAction:(id)sender;
- (void)cancelButtonAction:(id)sender;

#pragma mark DISPLAY TRIP TEXT
- (void)setTripText:(NSString *)text;

#pragma mark CONTROL VALIDATION
- (void)validateShowTripButton;

#pragma mark ERROR HANDLING
- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo;

#pragma mark ACCESSORS
- (NSWindow *)showTripDialog;
- (NSPanel *)tripPanel;
- (NSTextField *)tripTextField;
- (NSTextView *)tripTextView;
- (NSButton *)showTripButton;
- (NSButton *)cancelButton;
- (CBDataModel *)dataModel;

@end
