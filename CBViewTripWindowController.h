//
//  CBViewTripWindowController.h
//  CrewBid
//
//  Created by mark on 10/19/04.
//  Copyright 2004 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CBDataModel;
@class CBTrip;

@interface CBViewTripWindowController : NSWindowController
{
	IBOutlet NSTextView *  tripTextView;
   IBOutlet NSWindow *    viewTripDialog;
	IBOutlet NSTextField * tripNumberTextField;
   IBOutlet NSTextField * startDayTextField;
	IBOutlet NSButton *    viewTripButton;
	IBOutlet NSButton *    cancelButton;
	CBDataModel *          dataModel;
   CBTrip *               trip;
   NSCalendarDate *       tripStartDate;
}

#pragma mark INITIALIZATION
- (id)initWithDataModel:(CBDataModel *)inDataModel;

#pragma mark TOOLBAR
- (void)setupToolbar;

#pragma mark ACTIONS
- (void)viewTripButtonAction:(id)sender;
- (void)cancelButtonAction:(id)sender;
- (void)copyLegs:(id)sender;
- (void)showViewTripDialog:(id)sender;

#pragma mark DISPLAY TRIP TEXT
- (void)setTripText:(NSString *)text;

#pragma mark CONTROL VALIDATION
- (void)validateViewTripButton;

#pragma mark ERROR HANDLING
- (void)errorSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo;

#pragma mark ACCESSORS
- (NSWindow *)viewTripDialog;
- (NSTextField *)tripNumberTextField;
- (NSTextField *)startDayTextField;
- (NSTextView *)tripTextView;
- (NSButton *)viewTripButton;
- (NSButton *)cancelButton;
- (CBDataModel *)dataModel;
- (CBTrip *)trip;
- (void)setTrip:(CBTrip *)inValue;
- (NSCalendarDate *)tripStartDate;
- (void)setTripStartDate:(NSCalendarDate *)inValue;

@end
