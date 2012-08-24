//
//  CSBidReceiptWindowController.m
//  CrewBid
//
//  Created by Mark Ackerman on 1/15/08.
//  Copyright 2008 Mark Ackerman. All rights reserved.
//

#import "CSBidReceiptWindowController.h"
#import "CSBidReceipt.h"
#import "CSBidPeriod.h"


@implementation CSBidReceiptWindowController

#pragma mark Initialization

- (id)initWithBidPeriod:(CSBidPeriod *)bidPeriod
{
	if (self = [super initWithWindowNibName:@"BidReceipts"]) {
		NSMutableArray *bidReceipts = [NSMutableArray arrayWithCapacity:[[bidPeriod bidReceipts] count]];
		NSString *bidDirPath = [bidPeriod bidDataDirectoryPath];
		NSEnumerator *bidReceiptNameEnum = [[bidPeriod bidReceipts] objectEnumerator];
		NSString *bidReceiptName = nil;
		while (bidReceiptName = [bidReceiptNameEnum nextObject]) {
			NSString *path = [bidDirPath stringByAppendingPathComponent:bidReceiptName];
			// file exists and is not a directory
			BOOL isDir = NO;
			if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
				// has 'txt' extension
				if (NSOrderedSame == [[path pathExtension] caseInsensitiveCompare:CSBidReciptExtension]) {
					CSBidReceipt *bidReceipt = [[CSBidReceipt alloc] initWithPath:path];
					[bidReceipts addObject:bidReceipt];
					[bidReceipt release];
				}
			}
		}
		NSSortDescriptor *submittedForSort = [[NSSortDescriptor alloc] initWithKey:@"submittedFor" ascending:YES];
		NSSortDescriptor *bidDateTimeSort = [[NSSortDescriptor alloc] initWithKey:@"bidDateTime" ascending:NO];
		NSArray *sorts = [NSArray arrayWithObjects:submittedForSort, bidDateTimeSort, nil];
		[submittedForSort release];
		[bidDateTimeSort release];
		[bidReceipts sortUsingDescriptors:sorts];
		[self setBidReceipts:bidReceipts];
	}
	return self;
}

- (void) dealloc
{
	[self setBidReceipts:nil];
	[self setSelectedBidReceiptIndexes:nil];
	[super dealloc];
}

#pragma mark Actions

- (IBAction)okButtonAction:(id)sender
{
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)cancelButtonAction:(id)sender
{
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

#pragma mark Derived Accessors

- (CSBidReceipt *)selectedBidReceipt {
	CSBidReceipt *selectedBidReceipt = nil;
	unsigned selectedBidReceiptIndex = [[self selectedBidReceiptIndexes] firstIndex];
	if (NSNotFound != selectedBidReceiptIndex && selectedBidReceiptIndex < [[self bidReceipts] count]) {
		selectedBidReceipt = [[self bidReceipts] objectAtIndex:selectedBidReceiptIndex];
	}
    return selectedBidReceipt;
}

#pragma mark Accessors

- (NSArray *)bidReceipts {
    return _bidReceipts;
}

- (void)setBidReceipts:(NSArray *)value {
    if (_bidReceipts != value) {
        [_bidReceipts release];
        _bidReceipts = [value copy];
    }
}

- (NSIndexSet *)selectedBidReceiptIndexes {
    return _selectedBidReceiptIndexes;
}

- (void)setSelectedBidReceiptIndexes:(NSIndexSet *)value {
    if (_selectedBidReceiptIndexes != value) {
        [_selectedBidReceiptIndexes release];
        _selectedBidReceiptIndexes = [value copy];
    }
}

- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)value
{
	_delegate = value;
}

@end
