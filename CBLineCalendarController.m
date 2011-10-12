//
//  CBLineCalendarController.m
//  CrewBid
//
//  Created by Mark Ackerman on Fri May 07 2004.
//  Copyright © 2004 Mark Ackerman. All rights reserved.
//

#import "CBMainWindowController.h"
#import "CBMatrixController.h"
#import "CBDataModel.h"
#import "CBCalendarMatrix.h"

@implementation CBMainWindowController ( CBLineCalendarController )

#pragma mark INITIALIZATION

- (void)initializeLineCalendar
{
	[self setLineCalendarDatesController:[[[CBMatrixController alloc] initWithMatrix:[self lineCalendarDateMatrix]] autorelease]];
	[[self lineCalendarDatesController] loadEntries:[self calendarDateStringsWithMonth:[[self dataModel] month]] objects:[self calendarDatesWithMonth:[[self dataModel] month]] tags:nil];
   [self setLineCalendarEntryController:[[[CBMatrixController alloc] initWithMatrix:[self lineCalendarEntryMatrix]] autorelease]];
}

#pragma mark INTERFACE MANAGEMENT

- (void)updateLineCalendar
{
   [[self lineCalendarDatesController] reloadData];
   [[self lineCalendarTitleTextField] setStringValue:[NSString stringWithFormat:@"%@ - No line selected", [[[self dataModel] month] descriptionWithCalendarFormat:@"%B %Y"]]];
   [[self lineCalendarEntryController] loadEntries:[[self dataModel] emptyCalendarEntries] objects:[[self dataModel] emptyCalendarObjects] tags:[[self dataModel] emptyCalendarTags]];
}

#pragma mark ACCESSORS

- (NSTextField *)lineCalendarTitleTextField { return lineCalendarTitleTextField; }

- (NSMatrix *)lineCalendarDateMatrix { return lineCalendarDateMatrix; }

- (CBCalendarMatrix *)lineCalendarEntryMatrix { return lineCalendarEntryMatrix; }

- (CBMatrixController *)lineCalendarDatesController { return lineCalendarDatesController; }
- (void)setLineCalendarDatesController:(CBMatrixController *)inValue
{
   if (lineCalendarDatesController != inValue) {
      [lineCalendarDatesController release];
      lineCalendarDatesController = [inValue retain];
   }
}

- (CBMatrixController *)lineCalendarEntryController { return lineCalendarEntryController; }
- (void)setLineCalendarEntryController:(CBMatrixController *)inValue
{
   if (lineCalendarEntryController != inValue) {
      [lineCalendarEntryController release];
      lineCalendarEntryController = [inValue retain];
   }
}

@end
