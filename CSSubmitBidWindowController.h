//
//  CSSubmitBidWindowController.h
//  CrewSchedule
//
//  Created by Mark Ackerman on 7/6/06.
//  Copyright 2006 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSBidFileDownloadWindowController.h"

typedef enum {
	CSSubmitBidEmployeeNumberChangeTemporary = 0,
	CSSubmitBidEmployeeNumberChangePermanent
} CSSubmitBidEmployeeNumberChangeType;


@interface CSSubmitBidWindowController : CSBidFileDownloadWindowController
{
	IBOutlet NSWindow *changeEmployeeNumberWindow;
	NSString *_submitBidButtonTitle;
	NSString *_newEmployeeNumber;
	int _employeeNumberChangeType;
}

#pragma mark
#pragma mark Initialization
#pragma mark

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark
#pragma mark Actions
#pragma mark

- (IBAction)changeEmployeeNumberAction:(id)sender;
- (IBAction)employeeNumberChangeAction:(id)sender;
- (IBAction)employeeNumberCancelAction:(id)sender;
- (void)employeeNumberChangeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

#pragma mark Bid Receipt

- (void)handleDownloadedBidFile:(NSString *)path;
- (void)bidReceiptAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;

#pragma mark
#pragma mark Accessors
#pragma mark

- (NSString *)submitBidButtonTitle;
- (void)setSubmitBidButtonTitle:(NSString *)value;
- (NSString *)newEmployeeNumber;
- (void)setNewEmployeeNumber:(NSString *)value;
- (int)employeeNumberChangeType;
- (void)setEmployeeNumberChangeType:(int)value;

@end
