//
//  CBSelectCalendarMatrix.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri May 28 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBSelectCalendarMatrix.h"


@implementation CBSelectCalendarMatrix

- (void)mouseDown:(NSEvent *)event
{
   // point where mouseDown occurred in screen coordinates
	NSPoint windowPoint = [event locationInWindow];
   // point where mouseDown occurred in window coordinates
   NSPoint matrixPoint = [self convertPoint:windowPoint fromView:nil];
   // cell where mouseDown occurred
	int row = 0;
	int column = 0;
	[self getRow:&row column:&column forPoint:matrixPoint];
	NSButtonCell * matrixCell = [self cellAtRow:row column:column];
   // if the mouseDown was on a button, perform action
   if (matrixCell)
   {
      [super mouseDown:event];
   // if mouse down in matrix, but not on a button, make points matrix
   // the first responder
   } else {
      NSWindow * window = [self window];
      if (window) {
         [window makeFirstResponder:pointsMatrix];
         [pointsMatrix mouseDown:event];
      }
   }
}

@end
