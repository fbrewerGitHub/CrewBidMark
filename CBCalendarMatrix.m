//
//  CBCalendarMatrix.m
//  CrewBid
//
//  Created by Mark on Tue Dec 02 2003.
//  Copyright © 2003 Mark Ackerman. All rights reserved.
//

#import "CBCalendarMatrix.h"
#import "CBDataModel.h"
#import "CBMainWindowController.h"
#import "CBTrip.h"
#import "CBLine.h"

@implementation CBCalendarMatrix

#pragma mark INITIALIZATION

 - (void)awakeFromNib
{
	[self setTripText:@"No trip selected."];
}

#pragma mark TEXT VIEW METHODS

- (void)setTripText:(NSString *)text
{
	NSDictionary * textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont userFixedPitchFontOfSize:12.0], NSFontAttributeName, nil];
	[[[self tripTextView] textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:text attributes:textAttributes] autorelease]];
}

#pragma mark EVENT HANDLING

- (void)mouseDown:(NSEvent *)event
{
   // point where mouseDown occurred in screen coordinates
	NSPoint windowPoint = [event locationInWindow];
   // point where mouseDown occurred in window coordinates
   NSPoint matrixPoint = [self convertPoint:windowPoint fromView:nil];
   // cell where mouseDown occurred
	NSInteger row = 0;
	NSInteger column = 0;
	[self getRow:&row column:&column forPoint:matrixPoint];
	NSTextFieldCell * matrixCell = [self cellAtRow:row column:column];
	if (matrixCell) {
		id cellRepresentedObject = [matrixCell representedObject];
		// if cell has trip/date as represented object:
		//   - set text color of cell to purple
		//   - display pairing text in trip text view
		if (cellRepresentedObject != [NSNull null]) {
			// date for cell
			NSCalendarDate * date = [cellRepresentedObject objectForKey:CBLineTripDateKey];
			// CBTrip for cell
			CBTrip * trip = [cellRepresentedObject objectForKey:CBLineTripNumberKey];
			// highlight cells
			int matrixCellTag = [matrixCell tag];
         NSEnumerator * cellEnumerator = [[self cells] objectEnumerator];
         NSTextFieldCell * cell = nil;
         while (cell = [cellEnumerator nextObject]) {
            if (matrixCellTag != 0 && matrixCellTag == [cell tag]) {
               [cell setTextColor:[NSColor purpleColor]];
            } else {
               [cell setTextColor:[NSColor blueColor]];
            }
         }
			// display pairing for trip
         NSString *faPosition = [cellRepresentedObject objectForKey:CBLineTripPositionKey];
         if (faPosition) {
            [self setTripText:[trip descriptionWithDate:date generic:NO faPosition:faPosition]];
         } else {
            [self setTripText:[trip descriptionWithDate:date generic:NO]];
         }
         // set selected cell
         [self setSelectedCell:matrixCell];
		} else {
         [[self cells] makeObjectsPerformSelector:@selector(setTextColor:) withObject:[NSColor blueColor]];
			[self setTripText:@"No trip selected."];
         [self setSelectedCell: nil];
		}
	}
}



#pragma mark ACCESSORS

- (NSTextView *)tripTextView { return tripTextView; }
- (NSMatrix *)dateMatrix { return dateMatrix; }

- (NSTextFieldCell *)selectedCell
{
   return selectedCell;
}
- (void)setSelectedCell:(NSTextFieldCell *)inValue
{
   selectedCell = inValue;
}

@end
