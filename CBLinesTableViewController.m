//
//  CBLinesTableViewController.m
//  CrewBid
//
//  Created by Mark Ackerman on Mon May 03 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBDocument.h"
#import "CBDataModel.h"

@implementation CBMainWindowController ( CBLinesTableViewController )

#pragma mark INTERFACE MANAGEMENT

- (void)updateLinesTableView:(NSNotification *)notification
{
   // TEMP CODE
   [self setDocumentEdited:[[self document] isDocumentEdited]];

   [[self linesTableView] reloadData];
   [[self linesTableView] deselectAll:nil];
   // update available table columns as well, I guess
   [[self availableLinesTableColumns] reloadData];
   [[self availableLinesTableColumns] deselectAll:nil];
}

- (void)updateLinesTableViewSelectedRows:(NSNotification *)notification
{
	// select rows that have been moved
	NSArray *movedRows = [[notification userInfo] objectForKey:CBDataModelLinesMovedNotification];
	if (movedRows) {
		// select moved rows
		NSEnumerator *rowsEnum = [movedRows objectEnumerator];
		NSNumber *rowNumber = nil;
		int rowIndex = 0;
		int firstRow = 0;
		while (rowNumber = [rowsEnum nextObject]) {
			rowIndex = [rowNumber intValue];
			[[self linesTableView] selectRow:rowIndex byExtendingSelection:YES];
			if (rowIndex < firstRow) {
				firstRow = rowIndex;
			}
		}
		[[self linesTableView] scrollRowToVisible:firstRow];
	}
}

#pragma mark MOVE LINES TABLE VIEW ROWS

- (void)moveLinesTableRows:(NSArray *)fromRows toRow:(int)row
{
	// create array of indexes to which lines will be moved
	unsigned rowsCount = [fromRows count];
	NSMutableArray *toIndexes = [NSMutableArray arrayWithCapacity:rowsCount];
	int numRowsMovedFromAboveToRow = 0;
	unsigned i = 0;
	for (i = 0; i < rowsCount; ++i) {
		int fromRow = [[fromRows objectAtIndex:i] intValue];
		int toRow = 0;
		if (fromRow > row) {
			toRow = row + i - numRowsMovedFromAboveToRow;
			[toIndexes addObject:[NSNumber numberWithInt:toRow]];
		} else {
			numRowsMovedFromAboveToRow++;
			toRow = row - numRowsMovedFromAboveToRow;
			[toIndexes insertObject:[NSNumber numberWithInt:toRow] atIndex:0];
		}
	}
	// move rows
	[[self dataModel] moveLinesArrayRows:fromRows toRows:toIndexes];
}

#pragma mark NOTIFICATIONS
- (void)registerNotificationsForLinesTableView
{
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLinesTableView:) name:CBDataModelLinesChangedNotification object:[self document]];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLinesTableView:) name:CBDataModelUnarchivedNotification object:[self document]];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLinesTableViewSelectedRows:) name:CBDataModelLinesMovedNotification object:[self document]];
}

#pragma mark ACCESSORS

- (NSTableView *)linesTableView { return linesTableView; }

- (NSDictionary *)linesTableToolTips { return linesTableToolTips; }
- (void)setLinesTableToolTips:(NSDictionary *)inValue
{
   if (linesTableToolTips != inValue) {
      [linesTableToolTips release];
      linesTableToolTips = [inValue copy];
   }
}

@end
