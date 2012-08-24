//
//  CSBidReceiptWindowController.h
//  CrewBid
//
//  Created by Mark Ackerman on 1/15/08.
//  Copyright 2008 Mark Ackerman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CSBidReceipt;
@class CSBidPeriod;


@interface CSBidReceiptWindowController : NSWindowController
{
	NSArray *_bidReceipts;
	NSIndexSet *_selectedBidReceiptIndexes;
	id _delegate;
}

#pragma mark Initialization
- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod;

#pragma mark Actions
- (IBAction)okButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

#pragma mark Derived Accessors
- (CSBidReceipt *)selectedBidReceipt;

#pragma mark Accessors
- (NSArray *)bidReceipts;
- (void)setBidReceipts:(NSArray *)value;
- (NSIndexSet *)selectedBidReceiptIndexes;
- (void)setSelectedBidReceiptIndexes:(NSIndexSet *)value;
- (id)delegate;
- (void)setDelegate:(id)value;

@end
